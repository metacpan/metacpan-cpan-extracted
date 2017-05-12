package Hyper::Developer::Server;

use strict;
use warnings;

use base qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Static);

use File::Basename;
use Hyper;
use Hyper::Singleton::Context;
use Hyper::Template::HTC;
use Hyper::Developer::Model::Viewer;
use Hyper::Request::Default;
use Module::Refresh;

use Readonly;
Readonly my $PACKAGE => __PACKAGE__;

use CGI;
use File::Find;
use Hyper::Functions;

sub new {
    my $class   = shift;
    my $arg_ref = shift;
    my $config  = delete $arg_ref->{$PACKAGE};
    my $self    = HTTP::Server::Simple::new($class, %{$arg_ref});

    $self->{$PACKAGE} = {
        base_path => dirname((caller)[1]) . '/../../',
        refresh   => Module::Refresh->new(),
        %{$config}
    };

    return $self;
}

sub handler {
    my $self = shift;
    my $cgi  = CGI->new();

    { no warnings qw(redefine);
      $self->{$PACKAGE}->{refresh}->refresh();
    }

    # use server's cgi as cgi singleton
    { no warnings qw(redefine);
      *Hyper::Singleton::CGI::new
          = *Hyper::Singleton::CGI::singleton
          = sub { return $cgi; };
      *Hyper::Error::_is_eval_context = sub {
          return $_[3] && $_[3] eq '(eval)';
      };
    }

    print "HTTP/1.0 200 OK\n";
    eval {
        my $file         = $cgi->path_info();
           $file         =~ s{//}{/}xmsg;
        my $query_string = $cgi->query_string();
        my $config       = Hyper::Singleton::Context->new({
            file => $self->{$PACKAGE}->{config_file},
        })->get_config();
        my $namespace    = $config->get_namespace();
        my $base_path    = $config->get_base_path();

        if ( ! $file || $file eq '/' ) {
            $self->_show_index();
        }
        elsif ( $file =~ m{/Model/Viewer/([^/]+)/([^/]+)/([^/]+)}xms ) {
            $self->_model_viewer({
                namespace => $namespace,
                type      => $1,
                service   => $2,
                usecase   => $3,
            });
        }
        elsif ( $file eq '/cgi-bin/' . (lc $namespace) . '/index.pl' ) {
            do "$base_path/$file";
        }
        else {
            $self->serve_static($cgi, "$base_path/htdocs/");
        }
        Hyper::Request::Default::cleanup();
    };

    return;
}

sub _model_viewer {
    my $self        = shift;
    my $arg_ref     = shift;
    my $class       = "$arg_ref->{namespace}\::Control\::$arg_ref->{type}"
        . "\::$arg_ref->{service}\::"
        . ( substr $arg_ref->{type}, 0, 1 )
        . $arg_ref->{usecase};

    eval {
        my $svg = Hyper::Developer::Model::Viewer->new({
            for_class => $class,
        })->create_graph()->as_svg();
        print <<"EOT";
content-type:image/svg+xml

<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events"
     version="1.1" baseProfile="full" width="5000">$svg</svg>
EOT
    };

    return;
}

sub _show_index {
    my $self      = shift;
    my $config    = Hyper::Singleton::Context->singleton()->get_config();
    my $namespace = $config->get_namespace();
    my $base_path = $config->get_base_path();

    eval {
        # Child
        print "content-type:text/html; charset=utf-8\n\n";
        my @flow_controls;
        my @container_controls;
        find(
            sub {
                m{.ini\Z} or return;
                my ($type, $service, $last_part)
                    = (split m{/}, $File::Find::name)[-3..-1];
                my ($usecase) = $last_part =~ m{(?: F|C)([^\.]+)\.ini}xms;

                my %value_of = (
                    service   => $service,
                    usecase   => $usecase,
                    is_broken => do {
                        $last_part =~ s{\.ini\Z}{}xms;
                        eval "use $namespace\::Control\::$type\::$service\::$last_part;";
                        warn "use $namespace\::Control\::$type\::$service\::$last_part;";
                        $@;
                    },
                );

                if ( $type eq 'Flow' ) {
                    push @flow_controls, \%value_of;
                }
                else {
                    push @container_controls, \%value_of;
                }
            },
            map {
                "$base_path/etc/$namespace/Control/$_";
            } qw(Container Flow)
        );
        my $template = Hyper::Template::HTC->new(
            out_fh    => 0,
            for_class => __PACKAGE__,
            path      => [
                map {
                    $_ . '/' . Hyper::Functions::get_path_for('template');
                } $config->get_base_path(),
                  Hyper::Functions::get_path_from_file(__FILE__),
            ]
        );

        $template->param(
            namespace          => $namespace,
            lc_namespace       => lc $namespace,
            flow_controls      => \@flow_controls,
            container_controls => \@container_controls,
        );
        print $template->output();
    };

    return $self;
}

1;

__END__

# ToDo: add pod

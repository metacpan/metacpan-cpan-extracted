package Dist::Maker::Scatter;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker::Name;
use Dist::Maker::Util qw(mkpath);

use Text::Xslate   ();
use File::Spec     ();

extends 'Dist::Maker::Base';

has dist => (
    is       => 'ro',
    isa      => 'Dist::Maker::Name',
    coerce   => 1,
    required => 1,
);

has template => (
    is       => 'ro',
    isa      => 'Dist::Maker::Name',
    coerce   => 1,
    default  => sub {
        my($self) = @_;
        return $self->config->data->{template}{default};
    },
);

has cache_dir => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => sub {
        my($self) = @_;
        return $self->config->path('cache');
    },
    required => 0,
);

has content_map => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    init_arg   => undef,
    lazy_build => 1,
);

has _vpath => (
    is       => 'ro',
    isa      => 'HashRef[Dist::Maker::Template]',
    init_arg => undef,
    default  => sub { {} },
);

has _xslate => (
    is         => 'ro',
    isa        => 'Object',
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        _render       => 'render',
        render_string => 'render_string',
    },
);

sub _build__xslate {
    my($self) = @_;

    return Text::Xslate->new(
        type      => 'text',
        suffix    => '',
        path      => [ $self->_vpath ],
        module    => $self->config_data->{template}{module},
        cache_dir => $self->cache_dir,
    );
}


sub _load_dist_template {
    my($self, $name) = @_;

    (my $module_name = $name) =~ s/-/::/g;
    my $template_class = $self->load_class("Template::$module_name",);

    my $vpath = $self->_vpath;

    my $mtime = 0; # returns max mtime
    foreach my $c($template_class->meta->linearized_isa) {
        next unless $c->does('Dist::Maker::Template');

        my $t       = $c->new();
        my $moniker = $t->moniker;

        $self->info("loading $c as $moniker.\n");

        $vpath->{$moniker} = $t->distribution;

        my $mt = $t->mtime;
        if($mt > $mtime) {
            $mtime = $mt;
        }
    }
    return $mtime;
}

sub _build_content_map {
    my($self) = @_;

    my $name = $self->template->name;

    $self->info("build distribution with $name\n");

    my $mtime = $self->_load_dist_template($name);
    local $^T = $mtime; # XXX: hack to fool Xslate

    my $config = $self->config;
    my $vars = $config->merge_data(
        $config->data,
        { dist => $self->dist, template => { name => $self->template->module } },
    );
    my $packed = $self->_render($name, $vars);
    return $self->_parse_packed($packed);
}

sub _parse_packed { # parse Data::Section::Simple like packed structure
    my($self, $packed) = @_;

    my @pairs = split /^ \@\@ [ \t]* ([^\n]+) [ \t]* $/xms, $packed;
    shift @pairs;

    my %map;
    while(my($name, $content) = splice @pairs, 0, 2) {
        $content =~ s/\A \n+   //xms;   # remove starting newlines
        $content =~ s/   \n+ \z/\n/xms; # compress ending newlines
        $map{$name} = $content if length($content); # skip empty files
    }
    return \%map;
}

#sub raw_content_map {
#    my($self) = @_;
#    my $name = $self->template->name;
#    $self->_load_dist_template($name);
#    return $self->_parse_packed( $self->_vpath->{$name} );
#}

sub scatter {
    my($self, $to, $map) = @_;
    $map //= $self->content_map();

    $self->info("scatter to $to/\n");
    foreach my $file(sort keys %{$map}) {
        my $fullpath      = File::Spec->catfile($to, $file);
        my($volume, $dir) = File::Spec->splitpath($fullpath);
        $dir              = File::Spec->catpath($volume, $dir, '');
        unless(-e $dir) {
            $self->mkpath($dir);
        }

        $self->info("$file\n");
        open my $out, '>:raw:utf8', $fullpath ## no critic
            or die("Cannot open($fullpath) for writing: $!");
        print $out $map->{$file};
        close $out or die("Cannot close($fullpath) in writing: $!");
    }
    $self->info("scattered successfully.\n");
    return;
}


no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Scatter - Builds and scatters distributions

=cut

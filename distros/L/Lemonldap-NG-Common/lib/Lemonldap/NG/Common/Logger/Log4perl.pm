package Lemonldap::NG::Common::Logger::Log4perl;

use strict;
use Log::Log4perl;
use Log::Log4perl::MDC;

our $VERSION = '2.21.0';

our $init = 0;

sub new {
    my ( $class, $conf, %args ) = @_;
    my $self = bless {}, $class;

    unless ($init) {
        my $file = $conf->{log4perlConfFile} || '/etc/log4perl.conf';

        # Fix reporting of code location
        Log::Log4perl->wrapper_register(
            "Lemonldap::NG::Common::Logger::_Duplicate");
        Log::Log4perl->wrapper_register(__PACKAGE__);

        # map %S to the userData
        Log::Log4perl::Layout::PatternLayout::add_global_cspec(
            'S',
            sub {
                my $layout = shift;
                my $subvar = $layout->{curlies};
                my $req    = Log::Log4perl::MDC->get("req");
                return defined($req) ? $req->userData->{$subvar} : undef;
            }
        );

        # map %E to the stored $req->env
        Log::Log4perl::Layout::PatternLayout::add_global_cspec(
            'E',
            sub {
                my $layout = shift;
                my $subvar = $layout->{curlies};
                my $req    = Log::Log4perl::MDC->get("req");
                return defined($req) ? $req->env->{$subvar} : undef;
            }
        );

        # map %Q to the stored $req
        Log::Log4perl::Layout::PatternLayout::add_global_cspec(
            'Q',
            sub {
                my $layout = shift;
                my $subvar = $layout->{curlies};
                my $req    = Log::Log4perl::MDC->get("req");
                if ( ref($req) and $req->can($subvar) ) {
                    return $req->$subvar;
                }
                else {
                    return undef;
                }
            }
        );
        Log::Log4perl->init($file);
        $init++;
    }
    my $logger =
      $args{user}
      ? ( $conf->{log4perlUserLogger} || 'LLNG.user' )
      : ( $conf->{log4perlLogger} || 'LLNG' );
    $self->{log} = Log::Log4perl->get_logger($logger);

    no warnings 'redefine';
    my $show = 1;

    foreach (qw(error warn notice info debug)) {
        if ($show) {
            my $name = $_;
            $name = 'info' if ( $_ eq 'notice' );
            eval
              qq'sub $_ {shift->{log}->$name(\@_)}';
            die $@ if ($@);
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $conf->{logLevel} eq $_ );
    }
    die "Unknown logLevel $conf->{logLevel}" if $show;
    return $self;
}

sub setRequestObj {
    my ( $self, $req ) = @_;
    Log::Log4perl::MDC->put( "req", $req );
}

sub clearRequestObj {
    my ( $self, $req ) = @_;
    my $text = Log::Log4perl::MDC->remove();
}

1;

package Lemonldap::NG::Common::Logger::Log4perl;

use strict;
use Log::Log4perl;
use Log::Log4perl::MDC;

our $VERSION = '2.0.0';

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

sub AUTOLOAD {
    my $self = shift;
    no strict;
    $AUTOLOAD =~ s/.*:://;
    $AUTOLOAD =~ s/notice/info/;
    return $self->{log}->$AUTOLOAD(@_);
}

1;

package Lemonldap::NG::Common::Logger::Log4perl;

use strict;
use Log::Log4perl;

our $VERSION = '2.0.0';

our $init = 0;

sub new {
    my ( $class, $conf, %args ) = @_;
    my $self = bless {}, $class;
    unless ($init) {
        my $file = $conf->{log4perlConfFile} || '/etc/log4perl.conf';
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

sub AUTOLOAD {
    my $self = shift;
    no strict;
    $AUTOLOAD =~ s/.*:://;
    $AUTOLOAD =~ s/notice/info/;
    return $self->{log}->$AUTOLOAD(@_);
}

1;

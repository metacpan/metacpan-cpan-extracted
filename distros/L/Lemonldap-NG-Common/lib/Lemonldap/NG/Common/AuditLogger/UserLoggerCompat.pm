package Lemonldap::NG::Common::AuditLogger::UserLoggerCompat;

use Scalar::Util qw(weaken);

our $VERSION = '2.21.0';

sub new {
    my ( $class, $psgi_or_handler ) = @_;
    my $self = bless {}, $class;

    $self->{userLogger} = $psgi_or_handler->userLogger
      or die 'Missing userLogger';
    weaken $self->{userLogger};
    return $self;
}

sub log {
    my ( $self, $req, %fields ) = @_;

    my $message = $fields{message};
    if ( !$message ) {
        my ( $module, $file, $line ) = caller(2);
        $message =
          "auditLogger internal error: no message provided at $file line $line";
    }
    $self->{userLogger}->notice($message);
}
1;

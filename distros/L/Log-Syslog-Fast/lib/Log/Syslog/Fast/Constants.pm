package Log::Syslog::Fast::Constants;

use strict;
use warnings;

use Log::Syslog::Constants ();
use Carp 'croak';

require Exporter;
our @ISA = qw(Exporter);

# protocols
use constant LOG_UDP    => 0; # UDP
use constant LOG_TCP    => 1; # TCP
use constant LOG_UNIX   => 2; # UNIX socket

# formats
use constant LOG_RFC3164 => 0;
use constant LOG_RFC5424 => 1;
use constant LOG_RFC3164_LOCAL => 2;

our @EXPORT = ();
our %EXPORT_TAGS = (
    protos =>  [qw/ LOG_TCP LOG_UDP LOG_UNIX /],
    formats => [qw/ LOG_RFC3164 LOG_RFC5424 LOG_RFC3164_LOCAL /],
);
$EXPORT_TAGS{$_} = $Log::Syslog::Constants::EXPORT_TAGS{$_}
    for qw(facilities severities);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} } = map {@$_} values %EXPORT_TAGS;

sub AUTOLOAD {
    (my $meth = our $AUTOLOAD) =~ s/.*:://;
    if (Log::Syslog::Constants->can($meth)) {
        return Log::Syslog::Constants->$meth(@_);
    }
    croak "Undefined subroutine $AUTOLOAD";
}

1;

package CaptureStderr;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw( capture_stderr );

sub capture_stderr {
    my ($code) = @_;
    my $captured = "";
    open my $fh, ">", \$captured or die $!;
    {
        local *STDERR = $fh;
        $code->();
    }
    close $fh;
    return $captured;
}

1;

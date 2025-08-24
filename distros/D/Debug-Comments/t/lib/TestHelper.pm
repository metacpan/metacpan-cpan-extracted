use strict;
use warnings;

package TestHelper;

use File::Temp qw(tempfile);

my $LIBS = join(' ', map("-I$_", qw(blib/lib lib t/lib)));
my $MODULE = '-mOutputSwapper';

sub run_code {
    my ($code, %env) = @_;
    
    # Set up environment
    local %ENV = %ENV;
    $ENV{$_} = $env{$_} for keys %env;
    
    # Write to temp file
    my ($fh, $filename) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $code;
    close $fh or die "$!";
    
    my $output = `$^X $LIBS $MODULE $filename`;
    my $exit = $? >> 8;
    
    return ($output, $exit);
}

sub parse_debug_output {
    my ($output) = @_;
    # Strip ANSI codes if present
    $output =~ s/\e\[[0-9;]*m//g;
    my @messages;
    while ($output =~ /^(\d{2}):(\d{2})\s+\[([^:]+):(\d+)\]\s+(.*)$/mg) {
        push @messages, {
            min  => $1,
            sec  => $2,
            file => $3,
            line => $4,
            text => $5,
        };
    }
    return @messages;
}

sub has_ansi {
    my ($text) = @_;
    return $text =~ /\e\[[0-9;]+m/;
}

# See OutputSwapper
sub can_tty { -t STDERR or -t STDIN or -t STDOUT or -c '/dev/tty' }

1;

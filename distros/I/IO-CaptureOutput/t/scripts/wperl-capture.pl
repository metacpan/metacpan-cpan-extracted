use strict;
use IO::File;
use IO::CaptureOutput qw/capture/;

my $output_file = shift @ARGV;

my ($stdout, $stderr) = (q{}, q{});
capture sub { 
    print STDOUT "STDOUT\n";
    print STDERR "STDERR\n";
} => \$stdout, \$stderr;

my $fh = IO::File->new($output_file, ">");
print {$fh} $stdout, $stderr;
$fh->close;



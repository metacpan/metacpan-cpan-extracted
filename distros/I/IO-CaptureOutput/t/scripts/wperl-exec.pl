use strict;
use IO::File;
use IO::CaptureOutput qw/qxx/;

my $output_file = shift @ARGV;

my ($stdout, $stderr) = 
    qxx($^X, '-e', 'print "STDOUT\n"; print STDERR "STDERR\n"');

my $fh = IO::File->new($output_file, ">");
print {$fh} $stdout, $stderr;
$fh->close;



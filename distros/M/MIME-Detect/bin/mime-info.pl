#!perl -w
use strict;
use MIME::Detect;
my $mime = MIME::Detect->new();

if( $^O =~ /mswin/i ) {
    require File::Glob;
    @ARGV = grep { ! -d } map { File::Glob::bsd_glob $_ } @ARGV;
};

for my $file (@ARGV) {
    my $t = $mime->mime_type($file);
    $t = $t ? $t->mime_type : "<unknown>";
    print sprintf "%s: %s\n", $file, $t;
}

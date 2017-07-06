# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test

use strict;
use File::Temp qw/ tempfile tempdir /;
use Test::More tests => 10;
BEGIN { $^W = 1 }

use_ok('HTML::Scrubber');

my $s    = HTML::Scrubber->new;
my $html = q[<html><body><p>hi<br>start <!--comment--> mid1 <?html pi> mid2 <?xml pi?> end</body></html>];

isa_ok( $s, 'HTML::Scrubber' );

my $tmpdir = tempdir( CLEANUP => 1 );

SKIP: {
    skip "no writable temporary directory found", 6
        unless length $tmpdir
        and -d $tmpdir;

    my $template = 'html-scrubber-XXXX';
    my ( $tfh, $tmpfile ) = tempfile( $template, DIR => $tmpdir, SUFFIX => '.html' );
    my $r = $s->scrub( $html, $tmpfile );
    $r = "Error: \$@=$@ \$!=$!" unless $r;
    is( $r, 1, "scrub(\$html,\$tmpfile=$tmpfile)" );

    open my $filis, "+>", $tmpfile or die "can't write to $tmpfile";

    $r = $s->scrub( $html, $filis );
    $r = "Error: \$@=$@ \$!=$!" unless $r;

    is( $r, 1, q[scrub($html, $filis)] );

    seek $filis, 0, 0;
    $r = join '', readline $filis;
    is( $r, "histart  mid1  mid2  end", '$filis has the right stuff' );
    is( close($filis), 1, q[close($filis)] );

    my ( $tfh2, $tmpfile2 ) = tempfile( $template, DIR => $tmpdir, SUFFIX => '.html' );
    $r = $s->scrub_file( $tmpfile, "$tmpfile2" );
    $r = "Error: \$@=$@ \$!=$!" unless $r;

    is( $r, 1, qq[scrub_file(\$tmpfile,"\$tmpfile2"=$tmpfile2)] );

    open $filis, "+>", $tmpfile2 or die "can't write to $tmpfile";
    $r = $s->scrub_file( $tmpfile, $filis );
    $r = "Error: \$@=$@ \$!=$!" unless $r;

    is( $r, 1, q[scrub_file($tmpfile, $filis)] );
    seek $filis, 0, 0;
    $r = join '', readline $filis;
    is( $r, "histart  mid1  mid2  end", '$filis has the right stuff' );
    is( close($filis), 1, q[close($filis)] );

}

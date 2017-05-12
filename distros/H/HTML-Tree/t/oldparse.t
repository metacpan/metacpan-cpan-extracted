#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 16;

use HTML::Parse;

# This is a very simple test.  It basically just ensures that the
# HTML::Parse module is parsed ok by perl and that it will interact
# nicely with the rest of our modules

our $TestInput = "t/oldparse.html";

my $HTML;
{
    local $/ = undef;
    open( "INFILE", "$TestInput" ) || die "$!";
    binmode INFILE;
    $HTML = <INFILE>;
    close(INFILE);
}

my $own_builder = new HTML::TreeBuilder;
isa_ok( $own_builder, 'HTML::TreeBuilder' );

my $obj_h = parse_html $HTML, $own_builder;
isa_ok( $obj_h, "HTML::TreeBuilder", "existing TreeBuilder handled OK." );

my $h = parse_html $HTML;
isa_ok( $h, "HTML::TreeBuilder" );

# This ensures that the output from $h->dump goes to STDOUT
my $html;
ok( $html = $h->as_HTML( undef, '  ' ), "Get html as string." );

# This is a very simple test just to ensure that we get something
# sensible back.
like( $html, qr/<BODY>/i,     "<BODY> found OK." );
like( $html, qr/www\.sn\.no/, "found www.sn.no link" );
unlike( $html, qr/comment/, "Didn't find comment" );
like( $html, qr/Gisle/, "found Gisle" );

my $bad_file = parse_htmlfile("non-existent-file.html");
ok( !$bad_file, "Properly returned undef on missing file." );

my $own_obj_parser2 = parse_htmlfile( "t/oldparse.html", $own_builder );
isa_ok( $own_obj_parser2, "HTML::TreeBuilder" );

my $h2 = parse_htmlfile("t/oldparse.html");
isa_ok( $h2, "HTML::TreeBuilder" );

ok( $html = $h2->as_HTML( undef, '  ' ), "Get html as string." );

# This is a very simple test just to ensure that we get something
# sensible back.
like( $html, qr/<BODY>/i,     "parse_htmlfile: <BODY> found OK." );
like( $html, qr/www\.sn\.no/, "parse_htmlfile: found www.sn.no link" );
unlike( $html, qr/comment/, "parse_htmlfile: found comment" );
like( $html, qr/Gisle/, "parse_htmlfile: found Gisle" );


#!/usr/bin/perl

use warnings;
use strict;

use constant tests_per_object => 7;

use Test::More tests => ( 5 + 10 * tests_per_object );
use Test::Fatal qw(exception);

#initial tests + number of tests in test_new_obj() * number of times called

use HTML::Tree;

my $obj = new HTML::Tree;
isa_ok( $obj, "HTML::TreeBuilder" );

my $TestInput = "t/oldparse.html";

my $HTML;
{
    local $/ = undef;
    open( INFILE, $TestInput ) || die "Can't open $TestInput: $!";
    binmode INFILE;
    $HTML = <INFILE>;
    close(INFILE);
}

# setup some parts of the HTML for the list tests.

# die "$TestInput does not have at least 2 characters!"
#     if length($HTML) <= 2;
# my $HTMLPart1 = substr( $HTML, 0, int( length($HTML) / 2 ) );
# my $HTMLPart2 = substr( $HTML, int( length($HTML) / 2 ) );

# The logic here is to try to split the HTML in the middle of a tag.
# The above commented-out code is also an option.

my $split_at = 4;
die "$TestInput does not have at least " . ( $split_at + 1 ) . " characters!"
    if length($HTML) <= $split_at;
my $HTMLPart1 = substr( $HTML, 0, 4 );
my $HTMLPart2 = substr( $HTML, 4 );

is( $HTMLPart1 . $HTMLPart2, $HTML, "split \$HTML correctly" );

# Filehandle Test
{
    open( INFILE, $TestInput ) || die "Can't open $TestInput: $!";
    binmode INFILE;
    my $file_obj = HTML::Tree->new_from_file(*INFILE);
    test_new_obj( $file_obj, "new_from_file Filehandle" );
    close(INFILE);
}

# Scalar Tests
{
    my $content_obj = HTML::Tree->new_from_content($HTML);
    test_new_obj( $content_obj, "new_from_content Scalar" );
}

{
    my $file_obj = HTML::Tree->new_from_file($TestInput);
    test_new_obj( $file_obj, "new_from_file Scalar" );
}

{
    my $parse_content_obj = HTML::Tree->new;
    $parse_content_obj->parse_content($HTML);
    test_new_obj( $parse_content_obj, "new(); parse_content Scalar" );
}

# URL tests
{
  SKIP: {
    eval {
        # RECOMMEND PREREQ: URI::file
        require URI::file;
        require LWP::UserAgent;
        1;
    } or skip("URI::file or LWP::UserAgent not installed",
              2 + 2 * tests_per_object);

    my $file_url = URI->new( "file:" . $TestInput );

    {
        my $file_obj = HTML::Tree->new_from_url( $file_url->as_string );
        test_new_obj( $file_obj, "new_from_url Scalar" );
    }

    {
        my $file_obj = HTML::Tree->new_from_url($file_url);
        test_new_obj( $file_obj, "new_from_url Object" );
    }

    like(
        exception { HTML::Tree->new_from_url( "file:t/sample.txt" ) },
        qr!^file:t/sample\.txt returned text/plain not HTML\b!,
        "opening text/plain URL failed"
    );

    like(
        exception { HTML::Tree->new_from_url( "file:t/non_existent.html" ) },
        qr!^GET failed on file:t/non_existent\.html: 404 !,
        "opening 404 URL failed"
    );
  }
}

# Scalar REF Tests
{
    my $content_obj = HTML::Tree->new_from_content($HTML);
    test_new_obj( $content_obj, "new_from_content Scalar REF" );
}

# None for new_from_file
# Filehandle test instead. (see above)

{
    my $parse_content_obj = HTML::Tree->new;
    $parse_content_obj->parse_content($HTML);
    test_new_obj( $parse_content_obj, "new(); parse_content Scalar REF" );
}

# List Tests (Scalar and Scalar REF)
{
    my $content_obj = HTML::Tree->new_from_content( \$HTMLPart1, $HTMLPart2 );
    test_new_obj( $content_obj, "new_from_content List" );
}

# None for new_from_file.
# Does not support lists.

{
    my $parse_content_obj = HTML::Tree->new;
    $parse_content_obj->parse_content( \$HTMLPart1, $HTMLPart2 );
    test_new_obj( $parse_content_obj, "new(); parse_content List" );
}

# Nonexistent file test:
like(
    exception { HTML::Tree->new_from_file( "t/non_existent.html" ) },
    qr!^unable to parse file: !,
    "opening missing file failed"
);


sub test_new_obj {
    my $obj              = shift;
    my $test_description = shift;

    isa_ok( $obj, "HTML::TreeBuilder", $test_description );

    my $html = $obj->as_HTML( undef, '  ' );
    ok( $html, "Get HTML as string." );

    # This is a very simple test just to ensure that we get something
    # sensible back.
    like( $html, qr/<BODY>/i,     "<BODY> found OK." );
    like( $html, qr/www\.sn\.no/, "found www.sn.no link" );

TODO: {
        local $TODO = <<ENDTEXT;
HTML::Parser doesn't handle nested comments correctly.
See: http://phalanx.kwiki.org/index.cgi?HTMLTreeNestedComments
ENDTEXT

        unlike( $html, qr/nested-comment/, "Nested comment not found" );
    }

    unlike( $html, qr/simple-comment/, "Simple comment not found" );
    like( $html, qr/Gisle/, "found Gisle" );
}    # test_new_obj

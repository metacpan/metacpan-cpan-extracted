#!perl -T

use 5.010001;
use warnings;
use strict;

use Test::More tests => 2;

use HTML::T5;
use Encode ();
use Carp;

use lib 't';

use TidyTestUtils;

# Suck in the reference HTML document.
open( my $html_in, '<:encoding(UTF-8)', 't/unicode.html' ) or Carp::croak( "Can't read unicode.html: $!" );
my $html = join( '', <$html_in> );
close $html_in or die $!;

# Suck in the correct, cleaned doc (from DATA)
binmode DATA, ':encoding(UTF-8)';
my $reference = join( '', <DATA> );

subtest 'utf8 testing' => sub {
    plan tests => 8;

    my $tidy_constructor_args = { newline => 'LF', wrap => 0 };
    my $tidy = HTML::T5->new( $tidy_constructor_args );
    $tidy->ignore( type => TIDY_INFO );

    # Make sure both are unicode characters (not utf-x octets).
    ok(utf8::is_utf8($html), 'html is utf8');
    ok(utf8::is_utf8($reference), 'reference is utf8');

    my $clean = $tidy->clean( $html );
    ok(utf8::is_utf8($clean), 'cleaned output is also unicode');

    $clean = remove_specificity( $clean );
    is($clean, $reference, q{Cleanup didn't break anything});

    my @messages = $tidy->messages;
    is_deeply( \@messages, [], q{There still shouldn't be any errors} );

    $tidy = HTML::T5->new( $tidy_constructor_args );
    isa_ok( $tidy, 'HTML::T5' );
    my $rc = $tidy->parse( '', $html );
    ok( $rc, 'Parsed OK' );
    @messages = $tidy->messages;
    is_deeply( \@messages, [], q{There still shouldn't be any errors} );
};

subtest 'Try send bytes to clean method.' => sub {
    plan tests => 3;

    my $tidy_constructor_args = { newline => 'LF', wrap => 0 };
    my $tidy = HTML::T5->new( $tidy_constructor_args );
    $tidy->ignore( type => TIDY_INFO );

    my $encoded_html = Encode::encode('utf8',$html);
    ok(!utf8::is_utf8($encoded_html), 'html is row bytes');
    my $clean = $tidy->clean( $encoded_html );
    ok(utf8::is_utf8($clean), 'but cleaned output is string');
    $clean = remove_specificity( $clean );
    is($clean, $reference, q{Cleanup didn't break anything});
};

exit 0;


__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2//EN">
<html>
<head>
<meta name="generator" content="TIDY">
<title>日本語のホムページ</title>
</head>
<body>
<p>Unicodeが好きですか?</p>
</body>
</html>

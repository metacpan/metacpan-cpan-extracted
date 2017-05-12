use strict;

use Test::More tests => 23;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use HTML::Truncate;
use Encode;

ok( my $ht = HTML::Truncate->new(),
    "HTML::Truncate->new()" );

isa_ok( $ht, 'HTML::Truncate' );

ok( $ht->ellipsis() eq '&#8230;',
    "Ellipsis defaults properly");

diag ( 'Ellipsis: "' . $ht->ellipsis() . '"' ) if $ENV{TEST_VERBOSE};

SKIP: {
    skip "perl 5.8 or better for unicode features", 4 if $] < 5.008;

    ok( $ht->utf8_mode(1), "Set utf8_mode" );

    ok( $ht->utf8_mode(), "Get utf8_mode" );

    ok( $ht->ellipsis() eq chr(8230),
        "Ellipsis defaults properly" );

    if ( $ENV{TEST_VERBOSE} )
    {
        my $ellipsis = Encode::encode_utf8( $ht->ellipsis() );
        diag( qq{Ellipsis: "$ellipsis"} );
    }

    ok( $ht->utf8_mode(undef), "Unset utf8_mode" );
}

ok( ! $ht->utf8_mode(), "Check utf8_mode is 'off'" );

my $html = join('', <DATA>);
my $original_length = length($html);

is( $original_length, 974,
    "Test HTML is expected length" );

diag("Length of original corpus is $original_length") if $ENV{TEST_VERBOSE};

ok( $ht->chars() == 100,
    "Chars is defaulting properly" );

{
    my $char_count = 10;

    ok( $ht->chars($char_count), "Setting chars to $char_count" );
    ok( $ht->chars() == $char_count, "Chars is reset to $char_count" );

  SKIP: {
        skip "perl 5.8 or better for unicode features", 4 if $] < 5.01;
        ok( $ht->utf8_mode(1), "Setting utf8_mode" );
        ok( $ht->cleanly(undef), "Turning off cleanly");

        ok( my $trunc = $ht->truncate($html), "Truncating HTML" );
        my $strip = $trunc;
        _strip_html($strip);

        is( length($strip), $ht->chars + length($ht->ellipsis),
            "Length from character count matches expectation" );

        diag("TRUNCATED:\n" . Encode::encode_utf8($trunc)) if $ENV{TEST_VERBOSE};
        diag(" STRIPPED:\n" . Encode::encode_utf8($strip)) if $ENV{TEST_VERBOSE};
    }
}

{
    my $char_count = 100;
    ok( $ht->chars($char_count), "Setting chars to $char_count" );
    ok( $ht->chars() == $char_count, "Chars is reset to $char_count" );

    ok( $ht->utf8_mode(1), "Setting utf8_mode" );

    ok( my $trunc = $ht->truncate($html), "Truncating HTML" );
    my $strip = $trunc;
    _strip_html($strip);

    is( length($strip), ( $ht->chars + length($ht->ellipsis) ),
        "Length from character count matches expectation" );

    diag("TRUNCATED:\n" . Encode::encode_utf8($trunc)) if $ENV{TEST_VERBOSE};
    diag(" STRIPPED:\n" . Encode::encode_utf8($strip)) if $ENV{TEST_VERBOSE};
}

ok( $ht->percent('52%'), 'Setting percentage to 52%' );

ok( my $renewed = $ht->truncate($html), "Truncating" );

#is( length($renewed), 580,
#    "Length from percentage matches expectation" );

sub _strip_html {
    # Simple HTML stripper since we know the content is clean for it.
    $_[0] =~ s/\&(?=\S)[^;]+;/./g;
    $_[0] =~ s/<br\s*\/>/./g;
    $_[0] =~ s/<[^>]+>//g;
    $_[0] =~ s/\s\s+/ /g;
    $_[0] =~ s/\A\s+//g;
}

__DATA__
<a href="/yo-ho/blow/the/man.down"><img src="/img/whatever.png" alt="Whatever"
title="Whatever" name="Whatever" class="whatever" /></a>

<div id="piece">

<h2>About  the   &ldquo;author&rdquo;</h2>

<div id="whatever">
<p>
  <span class="date">
    11/20/2003
  </span>
  <b>Tags to <i>test</i> and check</b> <tt>and</tt> such.
</p>

<p>
  I think we can do this in a pretty straightforward fashion otherwise.
</p>

<p>
  It&#8217;s <a href="/wherever.html">a link</a> along with <a
     href="http://whatever.com/feat/embraces/why-i-took-the-pen-name.html">this</a>.
  I dislike <a
href="/wherever/20020403.html">formatting dummy <acronym title="hurtful, terrible, mean language">HTML</acronym></a>.
  15<span class="ord">th</span> generation Americans are sometimes decent fellows though gentlemen may differ.
</p>

<blockquote>
<p>
  Now you have plenty to test.
</p>
<cite>&#8212;Moo-cow-moo</cite>
</blockquote>

<p>
  <br /><br />Something else.

</p>

</div>

</div>

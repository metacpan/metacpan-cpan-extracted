use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Digest::SHA qw(sha256_hex);
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->catdir( $FindBin::Bin, '..' );
require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::HtmlEscape;

ok( defined $Developer::Dashboard::HtmlEscape::XS_LOADED,
    'HtmlEscape reports whether the native backend is loaded' );
is( Developer::Dashboard::HtmlEscape::_escape_html('<&>'), '&lt;&amp;&gt;',
    'public escaping output remains unchanged' );
is( Developer::Dashboard::HtmlEscape::_escape_html_attr(q{<a title="x'">}),
    '&lt;a title=&quot;x&#39;&quot;&gt;',
    'attribute escaping protects body metacharacters and both quote characters' );
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    is( Developer::Dashboard::HtmlEscape::_escape_html_attr(undef), '',
        'undefined attribute input reaches the Perl fallback and returns an empty string' );
    local *Developer::Dashboard::HtmlEscape::_escape_html = sub {
        die "plain attribute values should bypass body escaping\n";
    };
    is( Developer::Dashboard::HtmlEscape::_escape_html_attr('ordinary nav id'), 'ordinary nav id',
        'plain attribute values bypass the multi-pass body escaper' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    my @attribute_cases = (
        [ 'ordinary value &', 'ordinary value &amp;' ],
        [ 'ordinary value <', 'ordinary value &lt;' ],
        [ 'ordinary value >', 'ordinary value &gt;' ],
        [ 'ordinary value "', 'ordinary value &quot;' ],
        [ "ordinary value '", 'ordinary value &#39;' ],
        [ q{a&<>"'b}, q{a&amp;&lt;&gt;&quot;&#39;b} ],
    );
    for my $case (@attribute_cases) {
        is( Developer::Dashboard::HtmlEscape::_escape_html_attr( $case->[0] ), $case->[1],
            'Perl attribute fast-path guard preserves escaping for every metacharacter' );
    }
}
is( Developer::Dashboard::HtmlEscape::_escape_html_perl(undef), '',
    'Perl fallback normalizes undefined input without the XS backend' );
is( Developer::Dashboard::HtmlEscape::_escape_html_perl('ordinary helper input'),
    'ordinary helper input',
    'Perl reference helper preserves defined input without needing an escape' );
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    is( Developer::Dashboard::HtmlEscape::_escape_html(undef), '',
        'undefined public input retains the empty-string fallback without XS' );
    my $overloaded = bless {}, 'Local::Problem48DispatchOverloadedText';
    is( Developer::Dashboard::HtmlEscape::_escape_html($overloaded), '&lt;dispatch&gt;',
        'overloaded references retain Perl stringification without XS' );
    is( Developer::Dashboard::HtmlEscape::_escape_html_attr($overloaded), '&lt;dispatch&gt;',
        'defined overloaded attribute references take the Perl fallback without XS' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::HtmlEscape::_escape_html_perl = sub {
        die "the source fallback must not add a second escaper call\n";
    };
    my $escaped = eval { Developer::Dashboard::HtmlEscape::_escape_html('<&>') };
    is( $@, '', 'the source fallback escapes directly without another helper call' );
    is( $escaped, '&lt;&amp;&gt;', 'the direct source fallback preserves escaped output' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html = sub {
        return 'native:' . ( defined $_[0] ? $_[0] : '' );
    };
    is( Developer::Dashboard::HtmlEscape::_escape_html('<scalar>'), 'native:<scalar>',
        'native dispatch is selected for dense escapable scalars when available' );
    is( Developer::Dashboard::HtmlEscape::_escape_html(undef), 'native:',
        'undefined values are passed through the native empty-value contract' );
    my $overloaded = bless {}, 'Local::Problem48DispatchOverloadedText';
    is( Developer::Dashboard::HtmlEscape::_escape_html($overloaded), '&lt;dispatch&gt;',
        'references keep the Perl path when the native backend is available' );
}

{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html = sub { return $_[0] // '' };
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html_attr = sub {
        return 'native-attribute:' . ( defined $_[0] ? $_[0] : '' );
    };
    is( Developer::Dashboard::HtmlEscape::_escape_html_attr(q{<"'x}),
        'native-attribute:<"\'x',
        'attribute dispatch selects the one-pass native helper for scalar input' );
    my $overloaded = bless {}, 'Local::Problem48DispatchOverloadedText';
    is( Developer::Dashboard::HtmlEscape::_escape_html_attr($overloaded), '&lt;dispatch&gt;',
        'attribute escaping retains Perl stringification for overloaded references' );
}

{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html = sub {
        die "native path should not handle a plain string\n";
    };
    my $plain = 'ordinary text with no HTML metacharacters';
    is( Developer::Dashboard::HtmlEscape::_escape_html($plain), $plain,
        'plain text bypasses native byte scanning' );
}

{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html_chunked = sub {
        return "chunked:$_[0]";
    };
    my $sparse = ( 'ordinary text ' x 20 ) . '<tag>';
    is( Developer::Dashboard::HtmlEscape::_escape_html($sparse),
        "chunked:$sparse",
        'sparse metacharacters use the chunk-scanning native implementation' );
}

{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html = sub {
        die "direct byte loop should not handle early-but-rare escapes\n";
    };
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html_chunked = sub {
        return "chunked:$_[0]";
    };
    my $early_sparse = '<' . ( 'ordinary words ' x 20 ) . '&>';
    is( Developer::Dashboard::HtmlEscape::_escape_html($early_sparse),
        "chunked:$early_sparse",
        'an early but rare escape uses chunked native scanning on long input' );
}

{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_xs_escape_html = sub { return "native:$_[0]"; };
    is( Developer::Dashboard::HtmlEscape::_escape_html('<dense>'), 'native:<dense>',
        'dense metacharacters retain the native implementation' );
    my $dense_long = '<&>' x 100;
    is( Developer::Dashboard::HtmlEscape::_escape_html($dense_long), "native:$dense_long",
        'a high-density prefix selects the direct native loop for long input' );
    is( Developer::Dashboard::HtmlEscape::_escape_html('>'), 'native:>',
        'a first greater-than byte is found when earlier candidates are absent' );
    is( Developer::Dashboard::HtmlEscape::_escape_html('&<'), 'native:&<',
        'ampersand remains first when a later less-than candidate is found' );
    is( Developer::Dashboard::HtmlEscape::_escape_html('<&'), 'native:<&',
        'a less-than candidate before ampersand replaces the first position' );
    is( Developer::Dashboard::HtmlEscape::_escape_html('><'), 'native:><',
        'a greater-than candidate before less-than replaces the first position' );
}

my @include_args = map { ( '-I', File::Spec->rel2abs($_) ) } grep { defined $_ && !ref($_) && -d $_ } @INC;
my $taint_program = q{
    use Developer::Dashboard::HtmlEscape ();
    use Scalar::Util qw(tainted);
    my @cases = (
        [ $ENV{P48_HTML_ESCAPE_TAINT}, '&lt;&amp;&gt;' ],
        [ $ENV{P48_HTML_ESCAPE_PLAIN_TAINT}, 'ordinary text' ],
        [ $ENV{P48_HTML_ESCAPE_SPARSE_TAINT}, $ENV{P48_HTML_ESCAPE_SPARSE_TAINT_EXPECTED} ],
    );
    for my $case (@cases) {
        my $escaped = Developer::Dashboard::HtmlEscape::_escape_html( $case->[0] );
        die "escaped value lost its taint flag\n" if !tainted($escaped);
        die "escaped value changed\n" if $escaped ne $case->[1];
    }
    my $attribute = Developer::Dashboard::HtmlEscape::_escape_html_attr( $ENV{P48_HTML_ATTR_TAINT} );
    die "escaped attribute lost its taint flag\n" if !tainted($attribute);
    die "escaped attribute changed\n" if $attribute ne '&lt;&quot;&#39;';
    my $plain_attribute = Developer::Dashboard::HtmlEscape::_escape_html_attr( $ENV{P48_HTML_ATTR_PLAIN_TAINT} );
    die "plain attribute lost its taint flag\n" if !tainted($plain_attribute);
    die "plain attribute changed\n" if $plain_attribute ne 'ordinary navigation attribute';
    print "taint=yes output=yes\n";
};
local $ENV{P48_HTML_ESCAPE_TAINT} = '<&>';
local $ENV{P48_HTML_ESCAPE_PLAIN_TAINT} = 'ordinary text';
local $ENV{P48_HTML_ESCAPE_SPARSE_TAINT} = ( 'ordinary text ' x 20 ) . '<tag>';
local $ENV{P48_HTML_ESCAPE_SPARSE_TAINT_EXPECTED} = ( 'ordinary text ' x 20 ) . '&lt;tag&gt;';
local $ENV{P48_HTML_ATTR_TAINT} = '<"\'';
local $ENV{P48_HTML_ATTR_PLAIN_TAINT} = 'ordinary navigation attribute';
my ( $taint_out, $taint_err, $taint_exit ) = capture {
    system $^X, '-T', @include_args, '-e', $taint_program;
};
is( $taint_exit, 0, 'taint-mode subprocess preserves taint and output' );
is( $taint_out, "taint=yes output=yes\n", 'taint-mode subprocess confirms both properties' );
is( $taint_err, '', 'taint-mode subprocess emits no diagnostics' );

SKIP: {
    skip 'compiled XS extension is unavailable in this source-only test run', 26
      if !$Developer::Dashboard::HtmlEscape::XS_LOADED;

    my $sparse_unit = ( 'ordinary words and punctuation ' x 32 ) . '<&>' . chr(0xE9);
    my $plain_unit  = 'ordinary words and punctuation ' . chr(0xE9) . chr(0x1F600);
    my @cases = (
        [ undef, '' ],
        [ '', '' ],
        [ '<&>"\'', '&lt;&amp;&gt;"\'' ],
        [ "left\0<&>right", "left\0&lt;&amp;&gt;right" ],
        [ "caf\x{e9} \x{1f642} <tag>", "caf\x{e9} \x{1f642} &lt;tag&gt;" ],
        [ ( 'x' x ( 1_048_576 - 3 ) ) . '<&>', ( 'x' x ( 1_048_576 - 3 ) ) . '&lt;&amp;&gt;' ],
        [ substr( $sparse_unit x 1_100, 0, 1_048_576 ), undef ],
        [ substr( $plain_unit x 40_000, 0, 1_048_576 ), undef ],
    );
    for my $index ( 0 .. $#cases ) {
        my ( $input, $expected ) = @{ $cases[$index] };
        $expected = Developer::Dashboard::HtmlEscape::_escape_html_perl($input)
          if !defined $expected;
        my $actual = Developer::Dashboard::HtmlEscape::_xs_escape_html($input);
        if ( length($expected) > 8_192 ) {
            my ( $actual_bytes, $expected_bytes ) = ( $actual, $expected );
            utf8::encode($actual_bytes)   if utf8::is_utf8($actual_bytes);
            utf8::encode($expected_bytes) if utf8::is_utf8($expected_bytes);
            is( sha256_hex($actual_bytes), sha256_hex($expected_bytes),
                "XS result preserves exact bytes for large case $index" );
        }
        else {
            is( $actual, $expected, "XS result preserves exact bytes for case $index" );
        }
        is( utf8::is_utf8($actual) ? 1 : 0, utf8::is_utf8($expected) ? 1 : 0,
            "XS result preserves UTF-8 flag for case $index" );
        if ( $index == 6 ) {
            my $chunked = Developer::Dashboard::HtmlEscape::_xs_escape_html_chunked($input);
            my ( $chunked_bytes, $expected_bytes ) = ( $chunked, $expected );
            utf8::encode($chunked_bytes)  if utf8::is_utf8($chunked_bytes);
            utf8::encode($expected_bytes) if utf8::is_utf8($expected_bytes);
            is( sha256_hex($chunked_bytes), sha256_hex($expected_bytes),
                'chunked XS preserves exact bytes for large sparse input' );
            is( utf8::is_utf8($chunked) ? 1 : 0, utf8::is_utf8($expected) ? 1 : 0,
                'chunked XS preserves UTF-8 flag for large sparse input' );
        }
        if ( $index == 6 || $index == 7 ) {
            my $routed = Developer::Dashboard::HtmlEscape::_escape_html($input);
            my ( $routed_bytes, $expected_bytes ) = ( $routed, $expected );
            utf8::encode($routed_bytes)   if utf8::is_utf8($routed_bytes);
            utf8::encode($expected_bytes) if utf8::is_utf8($expected_bytes);
            is( sha256_hex($routed_bytes), sha256_hex($expected_bytes),
                "public dispatch preserves exact bytes for large case $index" );
            is( utf8::is_utf8($routed) ? 1 : 0, utf8::is_utf8($expected) ? 1 : 0,
                "public dispatch preserves UTF-8 flag for large case $index" );
        }
    }

    {
        package Local::Problem48OverloadedText;
        use overload '""' => sub { return '<overloaded>'; }, fallback => 1;
    }
    my $overloaded = bless {}, 'Local::Problem48OverloadedText';
    is( Developer::Dashboard::HtmlEscape::_escape_html($overloaded),
        '&lt;overloaded&gt;', 'references retain Perl stringification behavior' );
    is( Developer::Dashboard::HtmlEscape::_xs_escape_html('ordinary'), 'ordinary',
        'direct native helper returns unchanged ASCII text' );
    my $reference_error = eval {
        Developer::Dashboard::HtmlEscape::_xs_escape_html($overloaded);
        1;
    };
    ok( !$reference_error, 'native helper rejects references outside its contract' );
    like( $@, qr/Native HTML escaping accepts only scalar values/,
        'native reference rejection explains the accepted input contract' );
}

{
    package Local::Problem48DispatchOverloadedText;
    use overload '""' => sub { return '<dispatch>'; }, fallback => 1;
}

SKIP: {
    skip 'compiled XS extension is unavailable in this source-only test run', 16
      if !$Developer::Dashboard::HtmlEscape::XS_LOADED;

    my @attribute_cases = (
        [ undef, '' ],
        [ '', '' ],
        [ q{<&>"'}, '&lt;&amp;&gt;&quot;&#39;' ],
        [ "caf\x{e9} \0'", "caf\x{e9} \0&#39;" ],
    );
    for my $index ( 0 .. $#attribute_cases ) {
        my ( $input, $expected ) = @{ $attribute_cases[$index] };
        my $native = Developer::Dashboard::HtmlEscape::_xs_escape_html_attr($input);
        is( $native, $expected, "native attribute helper preserves exact output for case $index" );
        is( utf8::is_utf8($native) ? 1 : 0, utf8::is_utf8($expected) ? 1 : 0,
            "native attribute helper preserves UTF-8 flag for case $index" );
        my $public = Developer::Dashboard::HtmlEscape::_escape_html_attr($input);
        is( $public, $expected, "public attribute dispatcher preserves output for case $index" );
        is( utf8::is_utf8($public) ? 1 : 0, utf8::is_utf8($expected) ? 1 : 0,
            "public attribute dispatcher preserves UTF-8 flag for case $index" );
    }
}

done_testing;

__END__

=pod

=head1 NAME

665-problem48-xs-html-escape.t - test the optional native HTML escaper

=head1 PURPOSE

Verifies the HTML escaper reports native-backend availability and preserves
its public output, and checks the compiled XS implementation when built.
Source-only dispatch checks also cover unchanged text and the sparse and dense
native strategies.

=head1 WHY IT EXISTS

Problem 48 benchmarked a native byte loop as substantially faster for large
HTML strings. This regression protects exact escaping, UTF-8 flags, embedded
NUL handling, taint state, undefined input, and Perl overload behavior before
production integration. It also exercises the no-escape, sparse, and dense
dispatch branches with scoped stubs so source-only coverage does not depend on
a compiled artifact. The compiled backend's byte-level behavior, including
1 MiB dense, sparse, and plain inputs, is checked separately when built.

=head1 WHEN TO USE

Run when changing the shared HTML escaper, its XS implementation, or the
distribution's XS build mapping.

=head1 HOW TO USE

  prove -lv t/665-problem48-xs-html-escape.t

The compiled-backend checks run when the XS extension has been built and is in
the active library path; otherwise the source-only compatibility checks pass
and native cases are explicitly skipped. Attribute tests verify the dedicated
one-pass XS path and its output/UTF-8 parity for quotes, NULs, and Unicode.

=head1 WHAT USES IT

The repository test suite runs this test. The escaper's consumers are the web
page renderer and archive renderer; neither loads the benchmark code.

=head1 EXAMPLES

Build the distribution extension, then run the native checks from the blib
library paths:

  perl Makefile.PL
  make
  PERL5LIB=blib/lib:blib/arch prove -lv t/665-problem48-xs-html-escape.t

=cut

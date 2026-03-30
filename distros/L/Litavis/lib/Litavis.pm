package Litavis;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Litavis', $VERSION);

sub include_dir {
    my $dir = $INC{'Litavis.pm'};
    $dir =~ s{Litavis\.pm$}{Litavis/include};
    return $dir;
}

1;

__END__

=head1 NAME

Litavis - CSS preprocessor and compiler implemented in C via XS

=head1 SYNOPSIS

    use Litavis;

    # Basic usage
    my $css = Litavis->new->parse($input)->compile;

    # With options
    my $l = Litavis->new(
        pretty        => 1,
        indent        => "\t",
        dedupe        => 1,           # 0=off, 1=conservative, 2=aggressive
        shorthand_hex => 1,           # #aabbcc -> #abc
        sort_props    => 0,           # alphabetise properties
    );

    # Multiple inputs accumulate
    $l->parse($base_css);
    $l->parse($theme_css);
    my $output = $l->compile;

    # File and directory input
    $l->parse_file('styles.css');
    $l->parse_dir('css/');            # sorted, .css only, non-recursive

    # Write directly to file
    $l->compile_file('output.css');

    # Reset between independent compilations
    $l->reset;
    $l->parse($other_css);
    my $fresh = $l->compile;

=head1 DESCRIPTION

Litavis is a CSS preprocessor and compiler with its entire engine implemented
in C via reusable header files, exposed to Perl through XS. It succeeds
Crayon with a focus on correctness and performance.

=head2 Features

=over 4

=item * B<Nested selectors> with flattening (C<.a { .b { } }> becomes C<.a .b { }>)

=item * B<Parent references> (C<&:hover>, C<&.active>)

=item * B<Preprocessor variables> (C<$color: red; .a { color: $color; }>)

=item * B<Mixins> (C<%box: ( padding: 8px; ); .a { %box; }>)

=item * B<Map variables> (C<%sizes: ( sm: 8px; ); .a { padding: $sizes{sm}; }>)

=item * B<Colour functions> via Colouring::In::XS (C<lighten>, C<darken>, C<mix>, C<saturate>, C<desaturate>, C<fade>, C<tint>, C<shade>, C<greyscale>)

=item * B<Cascade-aware deduplication> that only merges selectors when provably safe

=item * B<Order preservation> using C arrays (no Perl hash randomisation)

=item * B<CSS custom properties passthrough> (C<var(--x)>, C<calc()>, C<clamp()>)

=item * B<@import/@charset hoisting> to the top of output

=item * B<Hex shorthand optimisation> (C<#ffffff> becomes C<#fff>)

=item * B<Comment stripping> (block C</* */> and line C<//>)

=back

=head2 Compilation Pipeline

Each call to C<compile> processes the full accumulated AST through these
stages, all in C:

    1. Flatten nested selectors
    2. Resolve preprocessor variables, mixins, and map variables
    3. Evaluate colour functions (lighten, darken, etc.)
    4. Merge rules with the same selector (later properties win)
    5. Deduplicate rules with identical properties (cascade-aware)
    6. Emit CSS string (minified or pretty-printed)

C<compile> is non-destructive; calling it multiple times returns the same
result. Use C<reset> to clear state between independent compilations.

=head1 METHODS

=head2 new

    my $l = Litavis->new(%options);

Create a new Litavis instance. All options are optional.

=over 4

=item B<pretty> => 0 | 1

Output mode. C<0> (default) produces minified CSS with no whitespace.
C<1> produces human-readable output with indentation and newlines.

=item B<dedupe> => 0 | 1 | 2

Deduplication strategy. C<0> disables deduplication entirely. C<1> (default)
uses conservative mode which only merges rules when no intervening rule
defines a conflicting property. C<2> uses aggressive mode which merges all
rules with identical properties regardless of cascade position.

=item B<indent> => $string

Indent string for pretty mode. Default is two spaces C<"  ">. Common
alternative is C<"\t">.

=item B<shorthand_hex> => 0 | 1

Hex colour shorthand. C<1> (default) converts C<#aabbcc> to C<#abc> when
possible. C<0> preserves the original form.

=item B<sort_props> => 0 | 1

Property sorting. C<0> (default) preserves source order. C<1> alphabetises
properties within each rule.

=back

=head2 parse

    $l->parse($css_string);

Parse a CSS string and accumulate the rules into the internal AST. Supports
nested selectors, preprocessor variables (C<$var: value;>), mixins
(C<%name: (...);>), map variables (C<%name: ( key: value; );>), C<@media>,
C<@keyframes>, C<@import>, and other at-rules.

Returns self for chaining.

=head2 parse_file

    $l->parse_file($filename);

Read and parse a CSS file. Dies if the file cannot be opened.

Returns self for chaining.

=head2 parse_dir

    $l->parse_dir($directory);

Parse all C<.css> files in a directory in alphabetical order. Non-recursive
(subdirectories are ignored). Non-CSS files are skipped.

Variables defined in earlier files (by sort order) are available to later
files, enabling patterns like C<01-vars.css>, C<02-base.css>,
C<03-theme.css>.

Returns self for chaining.

=head2 compile

    my $css = $l->compile;

Compile the accumulated AST to a CSS string. Runs the full pipeline
(flatten, resolve variables, resolve colours, merge, deduplicate, emit).

Non-destructive: can be called multiple times with the same result.

=head2 compile_file

    $l->compile_file($filename);

Compile and write the output directly to a file. Dies if the file cannot
be opened for writing.

=head2 reset

    $l->reset;

Clear all accumulated state (AST, variables, mixins, maps). Configuration
options (pretty, dedupe, etc.) are preserved.

=head2 pretty

    my $val = $l->pretty;        # get
    $l->pretty(1);               # set

Get or set the pretty-print mode.

=head2 dedupe

    my $val = $l->dedupe;        # get
    $l->dedupe(2);               # set

Get or set the deduplication strategy.

=head2 include_dir

    my $dir = Litavis->include_dir;

Returns the path to the installed C header files. Intended for downstream
XS modules that want to C<#include> the Litavis C engine directly:

    # In downstream Makefile.PL
    my $inc = Litavis->include_dir;
    # Then use -I$inc in CCFLAGS

=head1 COLOUR FUNCTIONS

Litavis evaluates colour functions at compile time using the
L<Colouring::In::XS> C headers. Colour arguments can be hex (C<#rgb>,
C<#rrggbb>), C<rgb()>, C<rgba()>, C<hsl()>, or C<hsla()>. Functions that
are not recognised as colour functions (e.g. C<calc()>, C<var()>,
C<linear-gradient()>) are passed through unchanged.

=head2 lighten

    .a { color: lighten(#000, 50%); }       /* #7f7f7f */
    .a { color: lighten(#3498db, 20%); }    /* lighter blue */

Increases lightness by the given percentage. Converts to HSL internally,
adds the amount to the lightness component, and converts back to hex.

=head2 darken

    .a { color: darken(#fff, 50%); }        /* #7f7f7f */
    .a { color: darken(#3498db, 20%); }     /* darker blue */

Decreases lightness by the given percentage.

=head2 saturate

    .a { color: saturate(#7f7f7f, 50%); }

Increases the saturation of a colour by the given percentage.

=head2 desaturate

    .a { color: desaturate(#3498db, 50%); }

Decreases the saturation of a colour by the given percentage.

=head2 greyscale

    .a { color: greyscale(#3498db); }

Removes all saturation, converting the colour to its greyscale equivalent.
Equivalent to C<desaturate($colour, 100%)>.

=head2 fade

    .a { color: fade(#3498db, 50%); }       /* rgba(52,152,219,0.5) */

Sets the absolute opacity of a colour. The result is emitted as
C<rgba()> when alpha is less than 1.

=head2 fadein

    .a { color: fadein(rgba(0,0,0,0.5), 25%); }

Increases opacity by the given amount.

=head2 fadeout

    .a { color: fadeout(#3498db, 25%); }    /* rgba(52,152,219,0.75) */

Decreases opacity by the given amount.

=head2 mix

    .a { color: mix(#fff, #000, 50); }      /* #7f7f7f */
    .a { color: mix(#f00, #00f, 75); }      /* 75% red, 25% blue */

Mixes two colours. The third argument is the weight (0-100) given to the
first colour. Default is 50 (equal mix). Uses alpha-aware blending.

=head2 tint

    .a { color: tint(#3498db, 50); }

Mixes the colour with white. The argument is the weight (0-100) given to
the original colour.

=head2 shade

    .a { color: shade(#3498db, 50); }

Mixes the colour with black. The argument is the weight (0-100) given to
the original colour.

=head1 EXAMPLES

=head2 Basic Compilation

    use Litavis;

    my $css = Litavis->new->parse('
        .card {
            color: red;
            font-size: 16px;
        }
    ')->compile;
    # .card{color:red;font-size:16px;}

=head2 Nested Selectors and Parent References

    my $css = Litavis->new->parse('
        .nav {
            background: #333;
            .item {
                color: white;
                &:hover {
                    color: yellow;
                }
                &.active {
                    font-weight: bold;
                }
            }
        }
    ')->compile;
    # .nav{background:#333;}.nav .item{color:white;}.nav .item:hover{color:yellow;}.nav .item.active{font-weight:bold;}

=head2 Variables and Mixins

    my $css = Litavis->new->parse('
        $brand: #3498db;
        $pad: 16px;

        %button-base: (
            padding: 8px $pad;
            border: none;
            border-radius: 4px;
        );

        .btn-primary {
            %button-base;
            background: $brand;
            color: white;
        }
        .btn-secondary {
            %button-base;
            background: #ecf0f1;
            color: #2c3e50;
        }
    ')->compile;

=head2 Map Variables

    my $css = Litavis->new->parse('
        %breakpoints: (
            sm: 576px;
            md: 768px;
            lg: 992px;
        );

        .container { max-width: $breakpoints{lg}; }
    ')->compile;
    # .container{max-width:992px;}

=head2 Colour Functions with Variables

    my $css = Litavis->new->parse('
        $primary: #3498db;

        .btn {
            background: $primary;
            color: white;
        }
        .btn:hover {
            background: darken($primary, 15%);
        }
        .btn:disabled {
            background: desaturate($primary, 40%);
            color: fade(#000, 50%);
        }
    ')->compile;

=head2 Cascade-Aware Deduplication

    # Conservative mode (default) — safe merging only
    my $css = Litavis->new->parse('
        .reset  { color: black; margin: 0; }
        .theme  { color: red; }
        .footer { color: black; margin: 0; }
    ')->compile;
    # .reset and .footer are NOT merged because .theme
    # defines "color" which conflicts — merging would
    # reorder the cascade.

    # Aggressive mode — merge all identical, ignore cascade
    my $css = Litavis->new(dedupe => 2)->parse('
        .a { padding: 8px; }
        .b { color: red; }
        .c { padding: 8px; }
    ')->compile;
    # .a,.c{padding:8px;}.b{color:red;}

=head2 Pretty-Printed Output

    my $css = Litavis->new(pretty => 1, indent => "    ")->parse('
        .card {
            color: red;
            background: blue;
        }
    ')->compile;
    # .card {
    #     color: red;
    #     background: blue;
    # }

=head2 @media Queries

    my $css = Litavis->new(pretty => 1)->parse('
        .container { max-width: 1200px; }
        @media (max-width: 768px) {
            .container { max-width: 100%; padding: 0 16px; }
        }
    ')->compile;

=head2 Multi-File Project with Directory Parsing

    # css/
    #   01-variables.css   ->  $brand: #3498db; $text: #333;
    #   02-base.css        ->  body { color: $text; }
    #   03-components.css  ->  .btn { background: $brand; }

    my $l = Litavis->new;
    $l->parse_dir('css/');
    my $css = $l->compile;
    # Variables from 01 are available in 02 and 03

=head2 CSS Custom Properties (Passthrough)

    my $css = Litavis->new->parse('
        $brand: #3498db;
        :root {
            --primary: $brand;
            --spacing: 8px;
        }
        .card {
            color: var(--primary);
            padding: var(--spacing);
            width: calc(100% - 32px);
        }
    ')->compile;
    # Preprocessor $brand is resolved; var(), calc() pass through unchanged

=head1 C HEADER FILES

The entire engine is implemented in standalone C header files that can be
reused by other XS modules:

    litavis.h             Master include (context struct, lifecycle)
    litavis_ast.h         Ordered AST with hash index
    litavis_tokeniser.h   Single-pass CSS tokeniser
    litavis_parser.h      Recursive descent parser with selector flattening
    litavis_cascade.h     Cascade-aware deduplication
    litavis_vars.h        Variable, mixin, and map resolution
    litavis_colour.h      Colour function evaluation (uses colouring.h)
    litavis_emitter.h     CSS output (minified and pretty-printed)

=head1 DEPENDENCIES

=over 4

=item * L<Colouring::In::XS> - C headers for colour manipulation

=back

=head1 SEE ALSO

L<Crayon> - the pure-Perl predecessor that Litavis replaces

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# Resolve the checkout root before the hermetic chdir so the source scan can
# still find lib/ afterwards.
my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

# Hermetic runtime rooted in a throwaway HOME; config resolves from the CWD's
# deepest .developer-dashboard layer, so we must chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
chdir $home or die "Unable to chdir to $home: $!";

# Families whose glyph coverage includes the keycap bases U+0030-U+0039 and
# U+002E. When one of these leads a font-family list, plain ASCII digits and
# dots are painted with emoji advance widths.
my @EMOJI_FAMILIES = (
    'Segoe UI Emoji',
    'Noto Color Emoji',
    'Apple Color Emoji',
    'Segoe UI Symbol',
    'Noto Emoji',
);

# _font_family_lists($css)
# Extracts every font-family declaration from a CSS or inline-style string.
# Input: CSS text string.
# Output: list of arrayrefs of family names in declaration order.
sub _font_family_lists {
    my ($css) = @_;
    my @lists;
    while ( $css =~ /font-family\s*:\s*((?:[^;"'}]|'[^']*'|"[^"]*")*)/g ) {
        my $declaration = $1;
        my @families;
        while ( $declaration =~ /\G\s*(?:'([^']*)'|"([^"]*)"|([^,]+?))\s*(?:,|\z)/gc ) {
            my $family = defined $1 ? $1 : defined $2 ? $2 : $3;
            $family =~ s/\A\s+//;
            $family =~ s/\s+\z//;
            push @families, $family if $family ne '';
        }
        push @lists, \@families if @families;
    }
    return @lists;
}

# _first_emoji_index($families)
# Finds the position of the first colour-emoji family in a font-family list.
# Input: arrayref of family names.
# Output: zero-based index, or -1 when the list names no emoji family.
sub _first_emoji_index {
    my ($families) = @_;
    for my $index ( 0 .. $#{$families} ) {
        return $index if grep { $_ eq $families->[$index] } @EMOJI_FAMILIES;
    }
    return -1;
}

# ---------------------------------------------------------------------------
# 1. The shipped top chrome must survive a 320px viewport.
#
#    DD-405 dogfooding measured document.documentElement.scrollWidth 325 vs
#    window.innerWidth 320 on /app/<id> at 320x640 (clean at 375). The 5px came
#    from the top-right status column: its inline font-family led with the
#    colour-emoji families, and Noto Color Emoji covers U+0030-U+0039 plus
#    U+002E for keycap sequences, so "192.168.1.189" was painted at emoji
#    advance widths (212px measured) as one unbreakable token. As a flex item
#    with the default min-width:auto the column could not shrink below that,
#    and a 320px phone only offers 262px of <main> content box
#    (320 - 2*1px border - 2*28px padding).
# ---------------------------------------------------------------------------
my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $files      = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store      = Developer::Dashboard::PageStore->new( paths => $paths );
my $config     = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $auth       = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions   = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime    = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $prompt     = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators );
my $actions    = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'narrow',
    title  => 'Narrow',
    mode   => 'render',
    layout => { body => '<h1>Narrow</h1>' },
);
$page->{meta}{request_context} = {
    tier        => 'admin',
    host        => '127.0.0.1:17890',
    remote_addr => '127.0.0.1',
};

my $chrome = $app->_top_chrome_html(
    $page,
    {
        edit   => '/app/narrow/edit',
        render => '/app/narrow',
        source => '/app/narrow/edit',
    },
);

like( $chrome, qr/class="dd-top-chrome"/, 'top chrome renders the flex chrome row' );
like( $chrome, qr/id="status-server"/,    'top chrome renders the host status line that overflowed' );

my ($row_style) = $chrome =~ /class="dd-top-chrome"\s+style="([^"]*)"/;
ok( defined $row_style, 'top chrome row carries an inline style' );
$row_style = '' if !defined $row_style;

like( $row_style, qr/display\s*:\s*flex/, 'top chrome row is a flex row' );
like(
    $row_style,
    qr/flex-wrap\s*:\s*wrap/,
    'top chrome row wraps instead of forcing both columns onto one line',
);

like(
    $chrome,
    qr/class="dd-top-chrome"[^>]*>\s*<div style="[^"]*min-width\s*:\s*0/,
    'left top chrome column sets min-width:0 so it can shrink below min-content',
);

my @column_styles = $chrome =~ /<div style="([^"]*)">/g;
my ($status_style) = grep { /white-space\s*:\s*pre-wrap/ } @column_styles;
ok( defined $status_style, 'top chrome status column is identifiable by its pre-wrap style' );
$status_style = '' if !defined $status_style;

like(
    $status_style,
    qr/min-width\s*:\s*0/,
    'top chrome status column sets min-width:0 so it can shrink below min-content',
);
like(
    $status_style,
    qr/overflow-wrap\s*:\s*anywhere/,
    'top chrome status column may break inside a long host or date token',
);

my @status_lists = _font_family_lists($status_style);
is( scalar(@status_lists), 1, 'top chrome status column declares exactly one font-family list' );

my $status_families = $status_lists[0] || [];
my $emoji_index     = _first_emoji_index($status_families);
cmp_ok( $emoji_index, '>', 0, 'top chrome status column lists a text family before any colour-emoji family' )
  or diag( 'font-family: ' . join( ', ', @$status_families ) );
cmp_ok(
    scalar( grep { _first_emoji_index( [$_] ) >= 0 } @$status_families ),
    '>=',
    2,
    'top chrome status column still falls back to colour-emoji families for indicator icons',
);

# ---------------------------------------------------------------------------
# 2. Source guard: no shipped stylesheet or inline style may lead a
#    font-family list with a colour-emoji family. Doing so silently widens
#    every digit in that element and reintroduces the narrow-viewport overflow.
# ---------------------------------------------------------------------------
{
    my @offenders;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if $File::Find::name !~ /\.pm\z/;
                open my $fh, '<', $File::Find::name
                  or die "Unable to read $File::Find::name: $!";
                my $line_number = 0;
                while ( my $line = <$fh> ) {
                    $line_number++;
                    for my $families ( _font_family_lists($line) ) {
                        next if _first_emoji_index($families) != 0;
                        my $rel = File::Spec->abs2rel( $File::Find::name, $ROOT );
                        push @offenders, "$rel:$line_number: " . join( ', ', @$families );
                    }
                }
                close $fh or die "Unable to close $File::Find::name: $!";
            },
        },
        File::Spec->catdir( $ROOT, 'lib' ),
    );
    is_deeply( \@offenders, [], 'no lib/ font-family list starts with a colour-emoji family' )
      or diag( join "\n", @offenders );
}

# ---------------------------------------------------------------------------
# 3. The rendered page skeleton must opt into the device viewport width and
#    embed the narrow-safe chrome verbatim, so the contract above is the
#    contract the browser actually receives.
# ---------------------------------------------------------------------------
{
    my $html = $page->render_html( chrome_html => $chrome, page_url => '/app/narrow' );
    like(
        $html,
        qr/<meta name="viewport" content="width=device-width, initial-scale=1">/,
        'rendered page skeleton opts into the device viewport width',
    );
    like( $html, qr/\Q$chrome\E/, 'rendered page skeleton embeds the narrow-safe chrome' );
}

done_testing();

__END__

=pod

=head1 NAME

t/127-narrow-viewport-chrome.t - rendered page chrome fits a 320px phone viewport

=head1 PURPOSE

This test is the narrow-viewport contract for the browser chrome that every
rendered saved page carries. The top chrome row must be a wrapping flex row
whose columns can shrink below their min-content width, its status column must
be allowed to break inside a long host or timestamp token, and its font stack
must name a text family before any colour-emoji family so plain ASCII digits
are never painted with emoji advance widths.

=head1 WHY IT EXISTS

DD-405 exploratory browser QA measured C<document.documentElement.scrollWidth>
at 325 against a C<window.innerWidth> of 320 on a rendered page at 320x640,
i.e. a 5px horizontal scrollbar on small phones, while 375px was clean. The
cause was not the box model: the status column's inline font-family led with
the colour-emoji families, and those fonts carry the keycap bases U+0030-U+0039
and U+002E, so the host address and timestamp were rendered as unbreakable
emoji-width tokens that a flex item with the default C<min-width: auto> refused
to shrink. Ordering emoji families last keeps indicator icons rendering in
colour (they are absent from the serif text fonts) while ASCII returns to text
metrics, and the shrink-safety declarations stop any future long token from
pushing the page wide again.

=head1 WHEN TO USE

Use this file when changing the top chrome markup or its inline styles, when
changing the rendered page skeleton stylesheet, when adding indicator icons to
the browser status strip, or when a mobile viewport reports a horizontal
scrollbar.

=head1 HOW TO USE

Run C<prove -lv t/127-narrow-viewport-chrome.t> while iterating on the chrome
markup, then keep it green under C<prove -lr t>. For a visual re-check, serve a
page with C<dashboard serve> and measure
C<document.documentElement.scrollWidth> against C<window.innerWidth> in a
browser device-emulation viewport of 320x640, 375x667, and 800x600; all three
must report equal widths and the status-strip icons must still be visible.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep the
rendered page chrome usable on small phones.

=head1 EXAMPLES

Example 1:

  prove -lv t/127-narrow-viewport-chrome.t

Run the narrow-viewport chrome contract by itself.

Example 2:

  prove -lv t/127-narrow-viewport-chrome.t t/123-html-lang-attribute.t

Run it together with the other rendered-document contract from the same
browser-QA pass.

Example 3:

  prove -lr t

Run it inside the full repository suite before release.

=cut

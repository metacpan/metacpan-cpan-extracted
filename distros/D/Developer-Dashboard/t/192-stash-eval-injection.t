#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );

my $tempdir = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $tempdir;
chdir $tempdir or die "Unable to chdir to $tempdir: $!";

require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::PageDocument;

my $marker = File::Spec->catfile( $tempdir, 'PWNED' );
unlink $marker;

# AC-1: the live-reproduced exploit must not execute.
my $payload = "1}; system('touch', '$marker'); {";
my $result  = Developer::Dashboard::PageDocument::_decode_stash_section($payload);
ok( !-e $marker, 'AC-1: a system() call embedded in a STASH body is never executed' );
is_deeply( $result, {}, 'AC-1: the malicious payload safely falls back to an empty hash' );

# A second payload shape: backticks / qx.
unlink $marker;
my $payload2 = "1}; qx{touch $marker}; {";
Developer::Dashboard::PageDocument::_decode_stash_section($payload2);
ok( !-e $marker, 'AC-1b: a backtick/qx call embedded in a STASH body is never executed' );

# Further attack shapes: open/require/glob-based symbolic-ref tricks,
# confirming the permitted rv2gv (needed only to satisfy Safe's own
# compartment-namespace setup on some Perl builds) does not itself open a
# path to dangerous functionality.
for my $shape (
    [ 'open',            "1}; open(my \$fh, '>', '$marker'); {" ],
    [ 'require',         "1}; require '/etc/passwd'; {" ],
    [ 'glob-symbolic-ref', "1}; my \$g = *{'main::system'}; &\$g('touch','$marker'); {" ],
    [ 'glob-assign',      "1}; *foo = *STDOUT; {" ],
  )
{
    my ( $name, $payload ) = @$shape;
    unlink $marker;
    Developer::Dashboard::PageDocument::_decode_stash_section($payload);
    ok( !-e $marker, "AC-1c: a $name payload embedded in a STASH body is never executed" );
}

# AC-2: legitimate shapes this project's own serializer produces still round-trip.
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section('foo => 1'),
    { foo => 1 },
    'AC-2: simple key => number still decodes'
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section("foo => 'bar'"),
    { foo => 'bar' },
    'AC-2: key => quoted string still decodes'
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section("foo => undef"),
    { foo => undef },
    'AC-2: key => undef still decodes'
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section("foo => [\n  1,\n  2\n]"),
    { foo => [ 1, 2 ] },
    'AC-2: nested array literal still decodes'
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section("foo => {\n  bar => 1\n}"),
    { foo => { bar => 1 } },
    'AC-2: nested hash literal still decodes'
);
is_deeply(
    Developer::Dashboard::PageDocument::_decode_stash_section('oops'),
    {},
    'AC-2: genuinely unparseable input still falls back to {} (unchanged existing behavior)'
);

# Round-trip: serialize then re-parse, exactly as PageDocument's own as_hash/from_instruction do.
{
    my $state = { a => 1, b => 'text', c => [ 1, 2, 3 ], d => { e => 'f' }, g => undef };
    my $text  = Developer::Dashboard::PageDocument::_legacy_stash_text($state);
    my $back  = Developer::Dashboard::PageDocument::_decode_stash_section($text);
    is_deeply( $back, $state, 'AC-2: a full serialize->parse round trip is unchanged' );
}

done_testing;

__END__

=head1 NAME

t/192-stash-eval-injection.t - regression test for the STASH string-eval RCE

=head1 PURPOSE

Proves DD-896's fix: C<PageDocument::_decode_stash_section> no longer
executes arbitrary Perl embedded in a saved page's STASH section, while
every legitimate STASH shape this project's own serializer produces still
round-trips correctly.

=head1 WHY IT EXISTS

DD-896: C<_decode_stash_section> parsed STASH bodies via a raw string
C<eval "+{ $text }">, so a STASH body could smuggle arbitrary Perl code
(including C<system>/C<qx>) that executed with the web process's own
privileges the moment a page containing it was loaded or rendered - live-
reproduced via a C<system('touch', ...)> payload creating a marker file.
Six call sites reach this parser, including directly from an HTTP body
parameter in C<Web::App::root_response>. Fixed by evaluating the STASH
body inside a C<Safe> compartment with a restrictive opcode mask instead
of a raw C<eval STRING>.

=head1 WHEN TO USE

Run whenever C<_decode_stash_section> or its opcode mask changes, or when
a new STASH shape needs to be supported.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/192-stash-eval-injection.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Exercises
C<Developer::Dashboard::PageDocument::_decode_stash_section> directly.

=head1 EXAMPLES

Watching this fail on a reintroduced regression: revert the C<Safe>
compartment back to a raw C<eval "+{ $text }">, rerun - AC-1 fails, the
marker file is created.

=cut

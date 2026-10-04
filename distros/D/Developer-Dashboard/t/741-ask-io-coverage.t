#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::open override must exist before Developer::Dashboard::CLI
# ::Ask is compiled. It fails only for exact registered paths, so the open
# failure branches run for any uid (root can read chmod-0000 files).
our %OPEN_FAIL;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $OPEN_FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
}

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::CLI::Ask;

my $M    = 'Developer::Dashboard::CLI::Ask';
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

sub wf {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# _execute_read_file: a file that passes -f but cannot be read.
{
    my $root = File::Spec->catdir( $home, 'proj' );
    make_path($root);
    my $file = wf( File::Spec->catfile( $root, 'secret.txt' ), "data\n" );
    is( $M->can('_execute_read_file')->( 'secret.txt', $root ), "data\n", 'a readable file is returned' );
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Ask::slurp_file = sub { die "denied\n" };
    like( $M->can('_execute_read_file')->( 'secret.txt', $root ), qr/^Unable to read secret\.txt: denied/, 'an unreadable file is reported to the model' );
}

# _execute_grep_repo: an unreadable file is skipped without aborting the search.
{
    my $root = File::Spec->catdir( $home, 'grep' );
    make_path($root);
    my $bad  = wf( File::Spec->catfile( $root, 'bad.txt' ),  "needle bad\n" );
    my $good = wf( File::Spec->catfile( $root, 'good.txt' ), "needle good\n" );
    local $OPEN_FAIL{$bad} = 1;
    $OPEN_FAIL{ File::Spec->rel2abs($bad) } = 1;
    my $out = $M->can('_execute_grep_repo')->( 'needle', undef, $root );
    like( $out, qr/good\.txt:1:needle good/, 'readable files are still searched' );
    unlike( $out, qr/bad\.txt/, 'the unreadable file is skipped' );
}

# _load_transcript: a transcript that exists but cannot be opened.
{
    my $file = wf( File::Spec->catfile( $home, 'transcript.json' ), '{"backend":"x","messages":[]}' );
    local $OPEN_FAIL{$file} = 1;
    is_deeply( $M->can('_load_transcript')->($file), { backend => '', messages => [] }, 'an unreadable transcript loads as an empty shell' );
}

# _build_config: roots that exist are kept, missing ones dropped.
{
    make_path( File::Spec->catdir( $home, 'projects' ) );
    my $cfg = $M->can('_build_config')->( { HOME => $home } );
    isa_ok( $cfg, 'Developer::Dashboard::Config' );
}

# _ask_claude / _ask_nova argument defaulting.
{
    package Test::Ask::Paths;
    sub new { bless {}, shift }
    sub current_project_root { '/tmp' }
}
{
    no warnings 'redefine';
    my %seen;
    local *Developer::Dashboard::CLI::Ask::_call_claude_api = sub { %seen = @_; return 'claude-answer' };
    local *Developer::Dashboard::CLI::Ask::_call_nova_api   = sub { %seen = @_; return 'nova-answer' };
    my $default_ua = bless {}, 'Test::Ask::DefaultUA';
    local *Developer::Dashboard::CLI::Ask::_default_ua = sub { return $default_ua };

    my %base = ( history => [], prompt => 'hi', text_files => [], images => [], paths => Test::Ask::Paths->new, env => { ANTHROPIC_API_KEY => 'k', NOVA_API_KEY => 'n' } );

    my $ua = bless {}, 'Test::Ask::GivenUA';
    is( $M->can('_ask_claude')->( %base, ua => $ua, model => 'm1', claude_conf => { base_url => 'http://x', max_tokens => 5 } ), 'claude-answer', 'claude answers with explicit settings' );
    is_deeply( [ @seen{qw(ua base_url model max_tokens)} ], [ $ua, 'http://x', 'm1', 5 ], 'explicit claude settings are passed through' );

    is( $M->can('_ask_claude')->( %base, claude_conf => {} ), 'claude-answer', 'claude answers with defaults' );
    is( $seen{ua}, $default_ua, 'the default user agent is built when none is given' );
    like( $seen{base_url}, qr{^https://}, 'the default base url is used' );
    like( $seen{model}, qr{^claude-}, 'the default model is used' );
    like( $seen{max_tokens}, qr{^\d+\z}, 'the default max tokens is used' );

    is( $M->can('_ask_nova')->( %base, ua => $ua, model => 'nm' ), 'nova-answer', 'nova answers with explicit settings' );
    is_deeply( [ @seen{qw(ua model)} ], [ $ua, 'nm' ], 'explicit nova settings are passed through' );
    is( $M->can('_ask_nova')->(%base), 'nova-answer', 'nova answers with defaults' );
    is( $seen{ua}, $default_ua, 'nova builds the default user agent' );
    like( $seen{model}, qr{^nova-}, 'nova uses its default model' );
}

done_testing;

__END__

=pod

=head1 NAME

t/741-ask-io-coverage.t - covers the I/O failure and argument-default branches of Developer::Dashboard::CLI::Ask

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces open and read failures with a CORE::GLOBAL::open override and a slurp stub, and drives the claude and nova backends with and without explicit settings.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and chmod-based fixtures cannot fail for root.

=head1 WHEN TO USE

Use this file when you change the ask tool helpers, transcript loading or backend defaults, or when a coverage run reports those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/741-ask-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/741-ask-io-coverage.t

Run this coverage-gap test by itself while editing the ask command.

=cut

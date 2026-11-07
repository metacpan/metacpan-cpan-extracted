#!/usr/bin/env perl
use 5.022;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports) the T2 handle, which the policy does not see used
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports) a plugin, loaded for its effect
use File::Temp   ();
use Path::Tiny   ();
use Pod::Checker ();

use Dist::Zilla::App::Tester              ();
use Dist::Zilla::App::Command::podchecker ();

# First, before anything in this process parses POD.  Pod::Simple 3.48 counts
# the commands that it saw in a variable of its file, which no parser resets,
# so after any parse of real POD, Pod::Checker counts this error itself.
T2->subtest(
    'the checker keeps the error of a file whose only POD command is unknown' => sub {
        my $only_method = "print 1;\n\n=method greet\n\nSays hello.\n\n=cut\n";
        my $checker     = Dist::Zilla::App::Command::podchecker::Checker->new( -warnings => 1 );
        open my $report, '>', \my $text or die "Cannot open a string: $!\n";
        $checker->output_fh($report);
        $checker->parse_string_document($only_method);
        close $report or die "Cannot close a string: $!\n";
        T2->is( $checker->num_errors, -1, 'Pod::Checker counts it as a file with no POD, in a process that parsed no POD before' );
        T2->is( $checker->errors,      1, 'but the checker keeps the error that it counted' );
        T2->like( $text, qr{Unknown\ directive:\ =method}, 'which it reported' );
    }
);

# A distribution whose POD Pod::Weaver writes: one module that weaves into
# good POD, one whose POD is broken in a way that weaving does not fix, a file
# with no POD, and a plugin that writes into the source tree after a build.
my $source = Path::Tiny::path( File::Temp::tempdir( CLEANUP => 1 ) );
my %files  = (
    'dist.ini' => <<'INI',
name = Test-Woven
version = 0.001
author = A. Tester <tester@test.test>
license = Perl_5
copyright_holder = Test Co

[GatherDir]
[PodWeaver]
[ReadmeAnyFromPod]
type = pod
filename = README.pod
location = root
INI
    'lib/Test/Woven.pm' => <<'PM',
package Test::Woven;

# ABSTRACT: A module that the test weaves

=method greet

Says hello.

=cut

sub greet { return 'hello' }

1;
PM
    'lib/Test/Broken.pm' => <<'PM',
package Test::Broken;

# ABSTRACT: A module whose POD has an error that weaving keeps

=head1 DESCRIPTION

=over 4

=item one

=cut

1;
PM
    'data.txt'       => "no pod here\n",
    'only-method.pl' => "print 1;\n\n=method greet\n\nSays hello.\n\n=cut\n",
);
for my $name ( sort keys %files ) {
    $source->child($name)->touchpath->spew_utf8( $files{$name} );
}

sub podchecker {
    my (@names) = @_;
    return Dist::Zilla::App::Tester->test_dzil( "$source", [ 'podchecker', @names ] );
}

T2->subtest(
    'a file that only weaving makes valid' => sub {
        my $checker = Pod::Checker->new( -warnings => 0 );
        open my $ignored, '>', \my $report or die "Cannot open a string: $!\n";
        $checker->output_fh($ignored);
        $checker->parse_file( $source->child(qw{lib Test Woven.pm})->stringify );
        close $ignored or die "Cannot close a string: $!\n";
        T2->like( $report, qr{Unknown\ directive:\ =method}, 'podchecker on the source reports the command of Pod::Weaver as an error' );

        my $result = podchecker('lib/Test/Woven.pm');
        T2->is( $result->exit_code, 0, 'and dzil podchecker passes the woven file' ) or T2->diag( $result->stdout, $result->error );
        T2->like( $result->stdout, qr{^lib/Test/Woven\.pm\ pod\ syntax\ OK\.$}m, 'and says so, under the name of the file in the distribution' );
    }
);

T2->subtest(
    'every installed module, by default' => sub {
        my $result = podchecker();
        T2->isnt( $result->exit_code, 0, 'a POD error fails the command' );
        T2->like( $result->error, qr{\A1\ of\ 2\ file\(s\)\ have\ POD\ errors}, 'and says how many files have one, of the modules that it checked' );
        my $forgot = qr{You\ forgot\ a\ '=back'\ before\ '=head1'};
        T2->like( $result->stdout, qr{$forgot\ at\ line\ \d+\ in\ file\ lib/Test/Broken\.pm}, 'and what the error is, and where' );
        T2->like( $result->stdout, qr{^lib/Test/Woven\.pm\ pod\ syntax\ OK\.$}m,              'and the good module still passes' );
        T2->ok( !-e Path::Tiny::path( $result->tempdir, qw{source README.pod} ), 'and nothing writes into the source tree, because no build happens' );
    }
);

T2->subtest(
    'files by name' => sub {
        my $result = podchecker('data.txt');
        T2->is( $result->exit_code, 0, 'a file with no POD is no error' ) or T2->diag( $result->error );
        T2->like( $result->stdout, qr{^data\.txt\ does\ not\ contain\ any\ pod\ commands\.$}m, 'but it is reported' );

        my $unknown = podchecker('only-method.pl');
        T2->isnt( $unknown->exit_code, 0, 'a file whose only POD command is unknown fails, though Pod::Checker counts it as a file with no POD' );
        my $directive = qr{Unknown\ directive:\ =method};
        T2->like( $unknown->stdout, qr{$directive\ at\ line\ 3\ in\ file\ only-method\.pl}, 'and the error is reported' );

        my $missing = podchecker('lib/Test/Nowhere.pm');
        T2->isnt( $missing->exit_code, 0, 'a name that is not a file of the distribution fails' );
        T2->like( $missing->error, qr{\ANot\ a\ file\ of\ the\ distribution:\ lib/Test/Nowhere\.pm}, 'and names it' );
    }
);

T2->done_testing;

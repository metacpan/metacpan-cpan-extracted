#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::open override must exist before the module under test is
# compiled. It fails only for exact paths registered in %FAIL, so the failure is
# deterministic for root and non-root users alike (a chmod 0000 file is still
# readable by root).
our %FAIL;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
}

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $auth  = Developer::Dashboard::Auth->new( paths => $paths, files => $files );

my ($file) = $auth->_user_file_candidates('alice');
make_path( ( File::Spec->splitpath($file) )[1] );
open my $out, '>', $file or die "Unable to write $file: $!";
print {$out} '{"username":"alice"}';
close $out or die "Unable to close $file: $!";

is( ref $auth->get_user('alice'), 'HASH', 'a readable user record is loaded' );

local $FAIL{$file} = 1;
my $user = eval { $auth->get_user('alice') };
ok( !defined $user, 'a user record that cannot be opened is not returned' );
like( $@, qr/Unable to read \Q$file\E/, 'the error names the file that could not be read' );

done_testing;

__END__

=pod

=head1 NAME

t/802-auth-get-user-open-failure-coverage.t - covers the unreadable-user-record branch of Developer::Dashboard::Auth::get_user

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces C<open> to fail for a user record that exists, so the C<Unable to read> branch of C<get_user> runs.

=head1 WHY IT EXISTS

It exists because the only earlier way to reach that branch was a chmod-based unreadable file, which a root process can still read, so a non-root CI run reported the branch uncovered (Problem 20).

=head1 WHEN TO USE

Use this file when you change how stored users are loaded, or when a coverage run reports the open failure in C<get_user> as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/802-auth-get-user-open-failure-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/802-auth-get-user-open-failure-coverage.t

Run this coverage-gap test by itself while editing the auth layer.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/802-auth-get-user-open-failure-coverage.t

Confirm the open-failure branch is reported as covered.

=cut

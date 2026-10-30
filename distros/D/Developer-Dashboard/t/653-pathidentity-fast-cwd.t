use strict;
use warnings;

use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use Developer::Dashboard::PathIdentity qw(current_working_directory);

my @identity_cases = (
    [ [],        [ 1, 2 ], 0, 'a failed candidate stat is rejected' ],
    [ [ 1, 2 ],  [],       0, 'a failed current-directory stat is rejected' ],
    [ [ 0, 0 ],  [ 0, 0 ], 0, 'an all-zero filesystem identity is rejected' ],
    [ [ 0, 2 ],  [ 0, 2 ], 1, 'a non-zero inode is sufficient when device is zero' ],
    [ [ 1, 2 ],  [ 3, 2 ], 0, 'a different device is rejected' ],
    [ [ 1, 2 ],  [ 1, 3 ], 0, 'a different inode is rejected' ],
    [ [ 1, 2 ],  [ 1, 2 ], 1, 'matching device and inode are accepted' ],
);
for my $case (@identity_cases) {
    is(
        Developer::Dashboard::PathIdentity::_same_directory_identity( $case->[0], $case->[1] ),
        $case->[2],
        $case->[3],
    );
}

my $original_cwd = getcwd();
my $temporary_root = tempdir( CLEANUP => 1 );
my $physical_cwd = File::Spec->catdir( $temporary_root, 'physical' );
mkdir $physical_cwd or die "Unable to create $physical_cwd: $!";
chdir $physical_cwd or die "Unable to change directory to $physical_cwd: $!";

{
    no warnings 'redefine';
    local *Developer::Dashboard::PathIdentity::cwd = sub {
        die 'slow Cwd::cwd fallback was unexpectedly called';
    };
    local *Developer::Dashboard::PathIdentity::getcwd = sub {
        return $physical_cwd;
    };
    local $ENV{PWD} = $physical_cwd;
    is( current_working_directory(), $physical_cwd,
        'returns the physical working directory for matching PWD' );
}

{
    no warnings 'redefine';
    my $getcwd_calls = 0;
    local *Developer::Dashboard::PathIdentity::getcwd = sub {
        ++$getcwd_calls;
        return $physical_cwd;
    };
    local $ENV{PWD} = $physical_cwd;
    is( current_working_directory(), $physical_cwd,
        'uses the direct getcwd result when PWD already matches' );
    is( $getcwd_calls, 1,
        'uses one getcwd lookup rather than two stat calls on the common path' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::PathIdentity::getcwd = sub { return ''; };
    local *Developer::Dashboard::PathIdentity::cwd = sub { return $physical_cwd; };
    local $ENV{PWD};
    is( current_working_directory(), $physical_cwd,
        'falls back to Cwd::cwd when getcwd returns an empty string' );
}

my $logical_cwd = File::Spec->catdir( $temporary_root, 'logical' );
SKIP: {
    skip 'directory symlinks are unavailable', 1 if !symlink $physical_cwd, $logical_cwd;
    local $ENV{PWD} = $logical_cwd;
    is( current_working_directory(), $logical_cwd,
        'preserves a logical symlink PWD when it identifies the current directory' );
}

for my $invalid_pwd (
    undef,
    '',
    'relative/path',
    File::Spec->catdir( $temporary_root, 'missing' ),
    $original_cwd,
  )
{
    local $ENV{PWD} = $invalid_pwd;
    is( current_working_directory(), $physical_cwd,
        'falls back to the physical working directory when PWD is absent or invalid' );
}

chdir $original_cwd or die "Unable to restore working directory to $original_cwd: $!";
done_testing();

__END__

=pod

=head1 NAME

653-pathidentity-fast-cwd.t - verify the fast logical current-directory lookup

=head1 PURPOSE

This test proves that the path identity helper avoids spawning an external
C<pwd> command when the inherited C<PWD> is absolute and points to the process's
actual current directory, while preserving safe fallback behavior.

=head1 WHY IT EXISTS

Devel::NYTProf showed C<Cwd::cwd> invoking C<pwd> from the path and prompt
helpers. A process launch costs milliseconds. This regression contract allows
the dashboard to use the validated shell-provided path on the normal path
without trusting stale or forged environment values.

=head1 WHEN TO USE

Run this test when changing C<Developer::Dashboard::PathIdentity>, the
switchboard working-directory initialization, path commands, or prompt
initialization.

=head1 HOW TO USE

Run the test from the repository's Docker test service:

  prove -lv t/653-pathidentity-fast-cwd.t

The test changes its process working directory only inside a temporary
directory and restores it before exit.

=head1 WHAT USES IT

The production callers are the public switchboard, path CLI helper, shared
path-table helper, and prompt helper. The tests protect their logical-path and
fallback semantics.

=head1 EXAMPLES

An absolute, verified C<PWD> is returned as-is, including a symlink spelling
that resolves to the current directory. An absent, empty, relative, nonexistent, or
different-directory C<PWD> falls back to the current physical directory.

=cut

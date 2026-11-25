use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempfile tempdir);
use FindBin qw($RealBin);
use Test::More;

my $root = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $selector = File::Spec->catfile( $root, 'script', 'select-ci-platforms' );

ok( -f $selector, 'the platform selector is present' );

# select_for(@tags)
# Purpose: execute the same tag-list parser used by the GitHub workflow.
# Input: zero or more exact Git tag names, one per line.
# Output: child exit status and the exact GitHub Actions output assignments.
sub select_for {
    my (@tags) = @_;
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    print {$fh} join( "\n", @tags ), "\n" if @tags;
    close $fh or die "Cannot close temporary tag list: $!";

    open my $pipe, '-|', $^X, $selector, $filename
      or die "Cannot start platform selector: $!";
    my $output = do { local $/; <$pipe> };
    close $pipe;
    my $status = $? >> 8;
    # Ignore unexpected diagnostic lines rather than constructing an odd
    # hash under fatal warnings; the workflow still rejects parser failures.
    my %values = map { split /=/, $_, 2 }
      grep { /\A(?:mac|ubuntu_amd64|ubuntu_arm64|win_amd64|win_arm64)=(?:true|false)\z/ }
      split /\n/, $output;
    return ( $status, \%values );
}

my @outputs = qw(mac ubuntu_amd64 ubuntu_arm64 win_amd64 win_arm64);

# expected(@selected)
# Purpose: express the exact boolean stage mapping for an intended selection.
# Input: platform output names in canonical underscore form.
# Output: a hash reference containing every stage's true/false assignment.
sub expected {
    my (@selected) = @_;
    my %wanted = map { $_ => 1 } @selected;
    return { map { $_ => ( $wanted{$_} ? 'true' : 'false' ) } @outputs };
}

my ( $status, $result ) = select_for();
is( $status, 0, 'an empty tag list is valid' );
is_deeply( $result, expected(@outputs), 'no tags triggers all five coverage stages' );

( $status, $result ) = select_for(qw(v6.29 release-2026 feature/abc));
is( $status, 0, 'unrelated Git tags are valid' );
is_deeply( $result, expected(@outputs),
    'unrelated Git tags do not disable normal coverage' );

( $status, $result ) = select_for('win-amd64');
is( $status, 0, 'one exact tag is valid' );
is_deeply( $result, expected('win_amd64'),
    'a single middle platform bypasses earlier stages' );

( $status, $result ) = select_for(qw(win-arm64 ubuntu-arm64));
is( $status, 0, 'multiple Git tags can point to one commit' );
is_deeply( $result, expected(qw(ubuntu_arm64 win_arm64)),
    'nonadjacent selected stages preserve their order' );

( $status, $result ) = select_for(qw(mac win-amd64 ubuntu-amd64 win-arm64 ubuntu-arm64));
is( $status, 0, 'all five platform Git tags are valid' );
is_deeply( $result, expected(@outputs), 'all selected platforms run in order' );

( $status, $result ) = select_for(qw(mac mac win-arm64 other-test v8.00));
is( $status, 0, 'duplicate and unrelated tags are accepted' );
is_deeply( $result, expected(qw(mac win_arm64)),
    'duplicates do not change the selected platform set' );

( $status, $result ) = select_for(qw(win-amd6 Mac [mac] ci-platforms));
is( $status, 0, 'similar tag names do not trigger an error' );
is_deeply( $result, expected(@outputs),
    'platform Git tags require an exact case-sensitive match' );

( $status, $result ) = select_for('win-amd64', '[ubuntu-arm64]',
    'CI-Platforms: mac');
is( $status, 0, 'commit-message-like tag names are ignored' );
is_deeply( $result, expected('win_amd64'),
    'bracket tags and message trailers have no platform effect' );

# This optional check verifies the exact git command used by the workflow:
# both lightweight and annotated tags point at HEAD, older tags do not.
my $git_installed = system('git', '--version') == 0;
SKIP: {
    skip 'Git not installed on this host', 3 if !$git_installed;
    my $dir = tempdir( CLEANUP => 1 );
    my @git = ( 'git', '-C', $dir );
    is( system( @git, 'init', '--quiet' ), 0, 'created temporary Git repository' );
    my @identity = ( '-c', 'user.name=CI Test', '-c', 'user.email=ci@example.invalid' );
    die 'Cannot create initial commit'
      if system( @git, @identity, 'commit', '--allow-empty', '--quiet',
          '-m', 'first commit') != 0;
    die 'Cannot add lightweight Git tag'
      if system( @git, 'tag', 'mac' ) != 0;
    die 'Cannot add annotated Git tag'
      if system( @git, @identity, 'tag', '-a', 'win-amd64', '-m', 'coverage' ) != 0;

    open my $tag_pipe, '-|', @git, 'tag', '--points-at', 'HEAD'
      or die "Cannot list pointed-at tags: $!";
    my @tags = <$tag_pipe>;
    close $tag_pipe or die "Cannot finish Git tag query: exit " . ($? >> 8);
    chomp @tags;
    is_deeply( [ sort @tags ], [qw(mac win-amd64)],
        'git finds lightweight and annotated tags on HEAD' );

    die 'Cannot advance HEAD'
      if system( @git, @identity, 'commit', '--allow-empty', '--quiet',
          '-m', 'next commit') != 0;
    open $tag_pipe, '-|', @git, 'tag', '--points-at', 'HEAD'
      or die "Cannot list current Git tags: $!";
    @tags = <$tag_pipe>;
    close $tag_pipe or die "Cannot finish Git tag query: exit " . ($? >> 8);
    is_deeply( \@tags, [],
        'tags pointing to the previous commit do not select the new HEAD' );
}

done_testing();

__END__

=head1 NAME

267-ci-platform-selection.t - select coverage stages from real Git tags

=head1 PURPOSE

Test that exactly matching Git tags point to platform stages, while untagged
commits still run the full five-platform serial coverage sequence.

=head1 WHY IT EXISTS

A branch commit with a tag elsewhere in the repository must not accidentally
turn off four coverage stages. The selector's exact-tag and default-all rules
are therefore protected by regressions independent of expensive hosted tests.

=head1 WHEN TO USE

Run when changing platform tag names, the tag query, or the coverage selector.

=head1 HOW TO USE

    prove -lv t/267-ci-platform-selection.t

=head1 WHAT USES IT

The five-platform coverage workflow runs this test as part of its Perl suite.
The optional real-Git test exercises the same command used by its selector job.

=head1 EXAMPLES

C<win-amd64> alone selects Windows amd64. C<ubuntu-arm64> plus C<win-arm64>
selects those two platforms in order. An empty list or a version tag selects
all five. An older-commit tag does not affect the most recent commit.

=cut

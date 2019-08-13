use 5.010;
use strict;
use warnings;
use lib qw/lib/;
use Git::Hooks::Test ':all';
use Test::More tests => 4;

my ($repo, $file, $clone, $T);

sub setup_repos_for {
    my ($reporef) = @_;

    ($repo, $file, $clone, $T) = new_repos();

	foreach my $git ($repo, $clone) {
		install_hooks($git, undef, qw/commit-msg update/);
	}

    $$reporef->run(qw/config githooks.plugin CheckYoutrack/);
    $$reporef->run(qw/config githooks.checkyoutrack.youtrack-host/, 'fake://url/');
    $$reporef->run(qw/config githooks.checkyoutrack.youtrack-token token/);
}

sub check_can_commit {
    my ($testname) = @_;
    $file->append($testname);
    $repo->run(add => $file);
    test_ok($testname, $repo, 'commit', '-m', $testname);
}

sub check_cannot_commit {
    my ($testname, $regex) = @_;
    $file->append($testname);
    $repo->run(add => $file);
    if ($regex) {
        test_nok_match($testname, $regex, $repo, 'commit', '-m', $testname);
    } else {
        test_nok($testname, $repo, 'commit', '-m', $testname);
    }
}

sub check_can_push {
	my ($testname, $ref) = @_;
	new_commit($repo, $file, $testname);
	test_ok($testname, $repo,
		'push', $clone->git_dir(), $ref || 'master');
}

sub check_cannot_push {
	my ($testname, $regex, $ref) = @_;
	new_commit($repo, $file, $testname);
	test_nok_match($testname, $regex, $repo,
		'push', $clone->git_dir(), $ref || 'master');
}

# Check commit
setup_repos_for(\$repo);

check_can_commit('allow commit by default without Youtrack');

$repo->run(qw{config githooks.checkyoutrack.required true});
check_cannot_commit('don\'t allow commit without Youtrack if required');

# Check push
setup_repos_for(\$clone);

$clone->run(qw{config githooks.checkyoutrack.required true});
check_cannot_push('deny push by update without Youtrack if required',
	qr/Missing youtrack ticket id/);

setup_repos_for(\$clone);

$clone->run(qw{config githooks.checkyoutrack.required false});
check_can_push('allow push by update without youtrack if not required');


use Test::More tests => 2;

if (($ENV{TRAVIS_PULL_REQUEST} || '') eq 'false') {
    chomp(my $branch_name = ($ENV{TRAVIS_BRANCH} || `git rev-parse --abbrev-ref HEAD`));
    $TODO = 'Changes need not have content for this release yet if this is only the master branch'
    if ($branch_name || '') eq 'master';
}

note 'Checking Changes';
my $changes_file = 'Changes';
my $newver = '6.35';
my $trial_token = '-TRIAL';
my $encoding = 'UTF-8';

SKIP: {
    ok(-e $changes_file, "$changes_file file exists")
        or skip 'Changes is missing', 1;

    ok(_get_changes($newver), "$changes_file has content for $newver");
}

done_testing;

sub _get_changes
{
    my $newver = shift;

    # parse changelog to find commit message
    open(my $fh, '<', $changes_file) or die "cannot open $changes_file: $!";
    my $changelog = join('', <$fh>);
    if ($encoding) {
        require Encode;
        $changelog = Encode::decode($encoding, $changelog, Encode::FB_CROAK());
    }
    close $fh;

    my @content =
        grep { /^$newver(?:$trial_token)?(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog;
    shift @content; # drop the version line

    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return number of non-blank lines
    return scalar @content;
}


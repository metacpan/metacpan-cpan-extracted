use strict;
use warnings;
use v5.14;
use Test::More;
use File::Temp qw(tempdir);
use Git::Hook::PostReceive;
use Cwd qw(abs_path cwd);
use Text::ParseWords;

my $gitv = `git --version`;    # e.g. "git version 1.8.1.2"
if ($?) {
    plan skip_all => 'git not installed';
    exit;
}
else {
    diag $gitv;
}

my $hook    = Git::Hook::PostReceive->new;
my $payload = $hook->read_stdin("\n");
is $payload, undef, "ignore empty lines";

my $cwd = cwd;

my $repo = abs_path( tempdir() );
chdir $repo;

my $null = '0000000000000000000000000000000000000000';

my @commands = <DATA>;
foreach (@commands) {
    chomp;    # don't use shell to avoid encoding issues, unless piped command
    my @args = $_ =~ />/ ? $_ : quotewords( '\s+', 0, $_ );
    @args = map { $_ =~ s/\{([0-9A-Z]+)\}/pack('U',hex($1))/ge; $_ } @args;
    system(@args) && last;
}

my @hashes = reverse split "\n", `git log --format='%H' --all --date-order`;

my @commits = ( {
        timestamp => '2013-07-30T08:20:24+02:00',
        author    => {
            email => 'a@li.ce',
            name  => 'Alice'
        },
        commiter => {
            email => 'a@li.ce',
            name  => 'Alice'
        },
        id       => $hashes[ 0 ],
        message  => 'first',
        added    => [ sort qw(foo bar doz) ],
        removed  => [],
        modified => [],

        # distinct => true,
    },
    {
        id        => $hashes[ 1 ],
        timestamp => '2013-08-10T14:36:06-01:00',
        author    => {
            email => 'a@li.ce',
            name  => 'Alice'
        },
        commiter => {
            email => 'a@li.ce',
            name  => 'Alice'
        },
        message  => "second\n\n\xE2\x98\x83",
        added    => [ 'baz' ],
        removed  => [ 'foo' ],
        modified => [ 'bar' ] } );

my $expect = {
    before     => $null,
    after      => $hashes[ 1 ],
    created    => 1,
    deleted    => 0,
    ref        => 'master',
    repository => $repo,
    commits    => [ @commits[ 0 .. 1 ] ],
};

$hook    = Git::Hook::PostReceive->new;
$payload = $hook->read_stdin("$null $hashes[1] master\n");
is_deeply $payload, $expect, 'sample payload';

my @branches = $hook->read_stdin( "$null $hashes[1] master\n",
    "$hashes[0] mytag mybranch" );
is_deeply $branches[ 1 ],
    {
    repository => $repo,
    ref        => 'mybranch',
    before     => $hashes[ 0 ],
    after      => $hashes[ 1 ],
    created    => 0,
    deleted    => 0,
    commits    => [ $commits[ 1 ] ]
    },
    'multiple branches';

$hook = Git::Hook::PostReceive->new( utf8 => 1 );
$payload = $hook->read_stdin("$null mytag master");
$expect->{commits}->[ 1 ]->{message} = "second\n\n\x{2603}";
is_deeply $payload, $expect, 'sample payload in UTF8';

$hook    = Git::Hook::PostReceive->new;
$payload = $hook->read_stdin("$hashes[3] $hashes[4] master");

is_deeply $payload->{commits}->[ 1 ]->{merge},
    {
    parent1 => substr( $hashes[ 3 ], 0, 7 ),
    parent2 => substr( $hashes[ 2 ], 0, 7 )
    },
    'merge';

$payload = $hook->read_stdin("$hashes[2] $null mybranch");

is_deeply $payload,
    {
    created    => 0,
    repository => $repo,
    before     => $hashes[ 2 ],
    after      => $null,
    commits    => [],
    ref        => 'mybranch',
    deleted    => 1,
    },
    'delete';

done_testing;

__DATA__
git init --quiet
git config user.name "Alice"
git config user.email "a@li.ce"
echo 1 > foo
echo 2 > bar
echo 3 > doz
git add --all
git commit -m "first" --date "Tue, 30 Jul 2013 08:20:24 +0200" --quiet
git rm foo --quiet
echo 4 > bar
echo 5 > baz
git add bar baz
git commit -m "second{A}{A}{2603}" --date "1376148966 -01:00" --quiet
git tag mytag
git checkout -b mybranch --quiet
echo x > baz
git commit --all -m "third" --date "2013-08-11T12:00:00+00:00" --quiet
git checkout master --quiet
echo x > bar
git commit --all -m "four" --date "2013-08-11T12:10:00+00:00" --quiet
git merge mybranch -m "merged" --quiet
git branch -d mybranch --quiet

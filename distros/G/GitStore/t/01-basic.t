#!perl

use Test::More tests => 11;
use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

my $time = time();
my $file = rand();
$gs->set("$file.txt", $time);
my $t = $gs->get("$file.txt");
is $t, $time;

$gs->discard;
$t = $gs->get("$file.txt");
is $t, undef;

$gs->set("$file.txt", $time);
$gs->set(['dir', 'ref.txt'], { hash => 1, array => 2 } );
$t = $gs->get("$file.txt");
is $t, $time;

$gs->commit( "stuff" );
$t = $gs->get("$file.txt");
is $t, $time;
my $refval = $gs->get('dir/ref.txt');
is $refval->{hash}, 1;
is $refval->{array}, 2;

subtest 'get_revision' => sub {
    plan tests => 3;

    my $rev = $gs->get_revision( "$file.txt" );
    like $rev->timestamp => qr/\d{4}-\d{2}-\d{2}T\d\d:\d\d:\d\d/, 'timestamp';
    is $rev->message, 'stuff', 'message';

    is $rev->content => $time, 'content';
};

# after delete
$gs->delete("$file.txt");
$t = $gs->get("$file.txt");
is $t, undef;
$gs->remove('dir/ref.txt');
$refval = $gs->get('dir/ref.txt');
is $refval, undef;

# save for next file, different instance
$gs->set("committed.txt", 'Yes');
$gs->set("gitobj.txt", $gitobj );
$gs->commit;
$gs->set("not_committed.txt", 'No');

subtest "list()" => sub {
    plan tests => 2;
    is_deeply [ $gs->list ] => [qw/ committed.txt gitobj.txt /], "list()";
    is_deeply [ $gs->list(qr/obj/) ] => [qw/ gitobj.txt /], "list(qr/obj/)";
};

subtest 'exist()' => sub {
    plan tests => 3;

    $gs->set( a => 0 );
    $gs->set( b => '' );
    $gs->commit;

    ok $gs->exist($_), $_  for 'a'..'b';
    ok !$gs->exist($_), $_ for 'd';
}



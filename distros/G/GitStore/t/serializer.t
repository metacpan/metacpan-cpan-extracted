use strict;
use warnings;

use Test::More tests => 2;

use GitStore;
use Path::Class;
use Git::PurePerl;

my $dir = './t/test';
dir($dir)->rmtree;

my $gitobj = Git::PurePerl->init( directory => $dir );

my $gs = GitStore->new( 
    repo => $dir,
    serializer => sub {
        my( $store, $path, $value ) = @_;
        $path =~ /./;
        return join $&, @$value;
    },
    deserializer => sub {
        my( $store, $path, $value ) = @_;
        $path =~ /./;
        return [ split $&, $value ];
    },
);

$gs->set( 'x/foo' => [qw/ foo bar /] );
$gs->commit;

is_deeply $gs->get('x/foo') => [ qw/ foo bar / ], 'set/get works';

$gs = GitStore->new( 
    repo => $dir,
    serializer => sub {
        my( $store, $path, $value ) = @_;
        $path =~ /./;
        return join $1, @$value;
    },
    deserializer => sub {
        my( $store, $path, $value ) = @_;
        return $value;
    },
);

is $gs->get('x/foo') => 'fooxbar', "stored correctly";



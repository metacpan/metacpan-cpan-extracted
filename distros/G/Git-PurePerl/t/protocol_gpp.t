#!perl
use strict;
use warnings;
use Git::PurePerl;
use IO::File;
use Path::Class;
use Test::More;

my $socket = IO::Socket::INET->new("www.github.com:80");
if ($socket) {
    close ($socket);
} else {
    plan skip_all => 'No Internet connection available';
}

my $directory = 'test-protocol';
dir($directory)->rmtree;

my $git = Git::PurePerl->init( directory => $directory );
isa_ok( $git, 'Git::PurePerl', 'can init' );

$git->clone( 'github.com', '/acme/git-pureperl.git' );

ok( $git->all_sha1s->all >= 604 );
ok( $git->all_objects->all >= 604 );

done_testing;

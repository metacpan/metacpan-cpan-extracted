use I22r::Translate::Request;
use I22r::Translate;
use Test::More;
use strict;
use warnings;

my $req = eval { I22r::Translate::Request->new() };
ok( !$req, 'missing attributes in constructor' );

$req = eval { I22r::Translate::Request->new( src => 'en', dest => 'zh' ) };
ok( !$req, 'still missing text' );

$req = eval { I22r::Translate::Request->new(
		  src => 'en', dest => 'vi',
		  text => { foo => 'hello world', bar => 'terrified of clowns' }
		  ) };
ok( $req, 'I think request will be created now' ) or diag $@;

$req = eval { I22r::Translate::Request->new(
		  src => 'en', dest => 'vi',
		  text => { foo => 'hello world', 
			    bar => 'terrified of clowns' },
		  log => sub { print STDERR "log!\n" },
		  ) };
ok( $req, 'request with options' );
ok( $req->config('log'), 'options passed to config' );
ok( 'CODE' eq ref $req->config('log'), 'coderef received in config' );

I22r::Translate->config( foo => 'bar' );
ok( $req->config('foo') eq 'bar',
    'request config looks through to global config' );

done_testing();

1;

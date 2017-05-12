use I22r::Translate::Request;
use I22r::Translate;
use Test::More;
use strict;
use warnings;

{
    package Test::Backend;
    use Moose;
    with 'I22r::Translate::Backend';

    sub can_translate { }
    sub get_translations { }
    sub config {
	my ($self,$key) = @_;
	if ($key eq 'bar') { return "foo" }
	if ($key eq 'baz') { return "bar" }
	if ($key =~ /\D/ && $key !~ /\d/) {
	    return $key + 1;
	}
	return;
    }
}
{
    package Test::Backend2;
    use Moose;
    with 'I22r::Translate::Backend';
    sub can_translate { }
    sub get_translations { }
    sub config { }
}


my $req = eval { I22r::Translate::Request->new(
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
ok( !$req->config('baz'),
    'no req or global config for "baz"' );

$req->backend( Test::Backend->new );
ok( $req->config('baz') eq "bar",
    "req config looks through to backend config" );

$req->backend( Test::Backend2->new );
ok( !$req->config('baz'),
    'backend reassigned, no config for "baz" anymore' );

done_testing();

1;

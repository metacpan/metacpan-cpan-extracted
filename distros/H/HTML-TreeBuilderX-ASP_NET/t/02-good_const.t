use Test::More tests => 5;

use HTML::TreeBuilder;
use HTML::TreeBuilderX::ASP_NET;
use HTML::Element;

my $html = qq{
<html><body>
<form name="foo" method="POST" action="http://google.com/Results.aspx">
<input type="hidden" name="__VIEWSTATE" value="foobar" />
<a href="__doPostBack('foo', 'bar')" id="stupidASP"> stupid asp </a>
</form>
</body><html>
};

eval {
	my $root = HTML::TreeBuilder->new_from_content( $html );
	my $form = $root->look_down( _tag => 'form' );
	my $asp = HTML::TreeBuilderX::ASP_NET->new({
		form => $form
		, eventTriggerArgument => { foo => 'bar' }
	});

	like (
		$asp->press->as_string
		, qr/__VIEWSTATE=foobar&__EVENTTARGET=foo&__EVENTARGUMENT=bar/
		, 'eventTriggerArgument w/ form, wo/ element'
	);
};

eval {
	my $root = HTML::TreeBuilder->new_from_content( $html );
	my $input = $root->look_down( id => 'stupidASP' );
	my $asp = HTML::TreeBuilderX::ASP_NET->new({
		element => $input
		, eventTriggerArgument => { foo => 'bar' }
	});

	like (
		$asp->press->as_string
		, qr/__VIEWSTATE=foobar&__EVENTTARGET=foo&__EVENTARGUMENT=bar/
		, 'eventTriggerArgument wo/ form, w/ element'
	);
};

eval {
	my $root = HTML::TreeBuilder->new_from_content( $html );
	my $input = $root->look_down( id => 'stupidASP' );
	my $asp = HTML::TreeBuilderX::ASP_NET->new({
		element => $input
		, form  => $input->look_up(_tag=>'form')
		, eventTriggerArgument => { foo => 'bar' }
	});

	like (
		$asp->press->as_string
		, qr/__VIEWSTATE=foobar&__EVENTTARGET=foo&__EVENTARGUMENT=bar/
		, 'eventTriggerArgument w/ form, w/ element'
	);
};

eval {
	my $root = HTML::TreeBuilder->new_from_content( $html );
	my $input = $root->look_down( id => 'stupidASP' );
	my $asp = HTML::TreeBuilderX::ASP_NET->new({
		element => $input
		, form  => HTML::Element->new( 'form' )
		, eventTriggerArgument => { foo => 'bar' }
	});

	like (
		$asp->press->as_string
		, qr/__EVENTTARGET=foo&__EVENTARGUMENT=bar/
		, 'eventTriggerArgument w/ element w/ new form w/ eventTriggerArgument'
	);
	like (
		$asp->press->as_string
		, qr/GET/
		,  'eventTriggerArgument w/ element w/ new form w/ eventTriggerArgument'
	);
};

print $@;

1;

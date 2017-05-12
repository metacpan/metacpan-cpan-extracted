use Test::More tests=>4;
use HTML::TreeBuilderX::ASP_NET;

eval {
	my $elements = HTML::TreeBuilderX::ASP_NET::createInputElements({foo=>'bar'});

	is_deeply( $elements, [
						bless( {
										 'value' => 'foo',
										 'name' => '__EVENTTARGET',
										 '_tag' => 'input'
									 }, 'HTML::Element' ),
						bless( {
										 'value' => 'bar',
										 'name' => '__EVENTARGUMENT',
										 '_tag' => 'input'
									 }, 'HTML::Element' )
					]
		, 'Test of the results of createInputElements'
	);
};


eval {
	my $js = q{__doPostBack('foo', 'bar')};
	my $element = HTML::Element->new('a', 'href' => $js);
	my $arr = HTML::TreeBuilderX::ASP_NET::parseDoPostBack($element);

	is_deeply( $arr, {foo=>'bar'}, 'Test of the results of parseDoPostBack' );
};

eval {
	my $foo = HTML::TreeBuilderX::ASP_NET->new;
	can_ok ( $foo, 'httpRequest' );
	can_ok ( $foo, 'press' );
};

1;

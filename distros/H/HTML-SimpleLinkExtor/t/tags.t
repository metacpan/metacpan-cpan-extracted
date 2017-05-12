use Test::More 0.96;

subtest 'Sanity check' => sub {
	use_ok( 'HTML::SimpleLinkExtor');

	no strict "refs";

	foreach my $sub ( qw( add_tags add_attributes remove_tags remove_attributes
		attribute_list tag_list) )
		{
		ok( defined &{"HTML::SimpleLinkExtor::$sub"}, "$sub is defined" );
		}
	};

my $default_tag_count  = HTML::SimpleLinkExtor->tag_list;
my $default_attr_count = HTML::SimpleLinkExtor->attribute_list;

subtest 'tag list' => sub {
	my @tags = HTML::SimpleLinkExtor->tag_list;
	is( scalar @tags, $default_tag_count, "Got the right number of tags" );

	my @attrs = HTML::SimpleLinkExtor->attribute_list;
	is( scalar @attrs, $default_attr_count, "Got the right number of attributes" );
	};

subtest 'bar tag' => sub {
	HTML::SimpleLinkExtor->add_tags( "bar" );
	my @tags = HTML::SimpleLinkExtor->tag_list;
	is( scalar @tags, 1 + $default_tag_count, "Got the right number of tags" );
	};

subtest 'add foo attribute' => sub {
	HTML::SimpleLinkExtor->add_attributes( "foo" );
	my @attrs = HTML::SimpleLinkExtor->attribute_list;
	is( scalar @attrs, 1 + $default_attr_count, "Got the right number of attributes" );
	};

subtest 'remove bar tag' => sub {
	HTML::SimpleLinkExtor->remove_tags( "bar" );
	my @tags = HTML::SimpleLinkExtor->tag_list;
	is( scalar @tags, $default_tag_count, "Got the right number of tags" );
	};

subtest 'remove foo attribute' => sub {
	HTML::SimpleLinkExtor->remove_attributes( "foo" );
	my @attrs = HTML::SimpleLinkExtor->attribute_list;
	is( scalar @attrs, $default_attr_count, "Got the right number of attributes" );
	};

done_testing();

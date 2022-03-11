#!perl
BEGIN
{
    use lib './lib';
    use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		plan(skip_all => 'These tests are for author or release candidate testing');
	}
};

eval "use Test::Pod::Coverage 1.04; use Pod::Coverage::TrustPod;";
plan( skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $params = 
{
    coverage_class => 'Pod::Coverage::TrustPod',
    trustme => [qr/^(new|init|filter|_\w+|on\w+|assignedSlot|cmp|css|css_cache_check|css_cache_store|data|each|empty|eq|even|exists|getLocalName|getNodePath|getValue|hasClass|hide|html|index|isa_collection|isa_element|length|load|map|name|new_root|odd|prependTo|promise|prop|rank|removeAttr|removeClass|set_namespace|show|string_value|tagname|toggleClass|xq)$/]
};
all_pod_coverage_ok( $params );

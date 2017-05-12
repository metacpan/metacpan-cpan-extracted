use Test::More tests => 12;

BEGIN { use_ok( "XML::SAX" ) }
BEGIN { use_ok( "XML::SAX::ParserFactory" ) }
BEGIN { use_ok( "XML::SAX::Base" ) }

use Data::Dumper;

use strict;

my %EXPECTED = (
	root_name => 0,
	root_ns => 0,
	element_name => 0,
	element_ns => 0,
	element_local_name => 0,
	element_prefix => 0,
	ns_name => 0,
	ns_prefix => 0,
);

{
package MyHandler;

our @ISA = qw( XML::SAX::Base );

sub start_element
{
	my( $self, $hash ) = @_;

#	print STDERR Data::Dumper::Dumper( $self, $hash );

	if( $hash->{Name} eq "root" )
	{
		$EXPECTED{"root_name"} = 1;
		if( $hash->{NamespaceURI} eq "NAMESPACE1" )
		{
			$EXPECTED{"root_ns"} = 1;
		}
	}
	if( $hash->{Name} eq "x:element" )
	{
		$EXPECTED{"element_name"} = 1;
		if( $hash->{LocalName} eq "element" )
		{
			$EXPECTED{"element_local_name"} = 1;
		}
		if( $hash->{NamespaceURI} eq "NAMESPACE2" )
		{
			$EXPECTED{"element_ns"} = 1;
		}
		if( $hash->{Prefix} eq "x" )
		{
			$EXPECTED{"element_prefix"} = 1;
		}
		my $namespace_attr = $hash->{"Attributes"}->{"{http://www.w3.org/2000/xmlns/}x"};
		if( defined $namespace_attr )
		{
			if( $namespace_attr->{Name} eq "xmlns:x" )
			{
				$EXPECTED{"ns_name"} = 1;
			}
			if( $namespace_attr->{Prefix} eq "xmlns" )
			{
				$EXPECTED{"ns_prefix"} = 1;
			}
			if( $namespace_attr->{Value} eq "NAMESPACE2" )
			{
				$EXPECTED{"ns_value"} = 1;
			}
		}
	}
}
}

my $handler = MyHandler->new;
my $parser = XML::SAX::ParserFactory->parser(
	Handler => $handler
	);

$parser->parse_string( join "", <DATA> );

foreach my $test (sort keys %EXPECTED)
{
	ok($EXPECTED{$test}, "parsed $test");
}

__DATA__
<?xml version="1.0"?>
<root xmlns="NAMESPACE1">
<x:element xmlns:x="NAMESPACE2">
content
</x:element>
</root>

###############################################################################
#json.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.1
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#json.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::json;
use strict;
use warnings;
require JSON;

#If it is not already loaded.
require Dotiac::DTL::Filter;
require Dotiac::DTL::Value;



our $VERSION=0.1;

our $json=JSON->new();

#Global options, allow as much as possible.
$json->allow_nonref(1);
$json->allow_blessed(1);
$json->allow_unknown(1);


my $oldjson;
my $oldjson_ascii;
my $oldjson_pretty;
my $oldjson_ascii_pretty;

sub import {
	$oldjson = *{Dotiac::DTL::Filter::json};
	$oldjson_ascii = *{Dotiac::DTL::Filter::json_ascii};
	$oldjson_pretty = *{Dotiac::DTL::Filter::json_pretty};
	$oldjson_ascii_pretty = *{Dotiac::DTL::Filter::json_ascii_pretty};
	*{Dotiac::DTL::Filter::json}=\&json;
	*{Dotiac::DTL::Filter::json_ascii}=\&json_ascii;
	*{Dotiac::DTL::Filter::json_pretty}=\&json_pretty;
	*{Dotiac::DTL::Filter::json_ascii_pretty}=\&json_ascii_pretty;

}
sub unimport {
	*{Dotiac::DTL::Filter::json} = $oldjson;
	*{Dotiac::DTL::Filter::json_ascii} = $oldjson_ascii;
	*{Dotiac::DTL::Filter::json_pretty} = $oldjson_pretty;
	*{Dotiac::DTL::Filter::json_ascii_pretty} = $oldjson_ascii_pretty;
}

sub json {
	my $value=shift;
	$Dotiac::DTL::Addon::json::json->pretty(0);
	$Dotiac::DTL::Addon::json::json->utf8(1);
	return $value->set($json->encode($value->content));
}

sub json_ascii {
	my $value=shift;
	$Dotiac::DTL::Addon::json::json->pretty(0);
	$Dotiac::DTL::Addon::json::json->ascii(1);
	return $value->set($json->encode($value->content));
}

sub json_pretty {
	my $value=shift;
	$Dotiac::DTL::Addon::json::json->pretty(1);
	$Dotiac::DTL::Addon::json::json->utf8(1);
	return $value->set($json->encode($value->content));
}

sub json_ascii_pretty {
	my $value=shift;
	$Dotiac::DTL::Addon::json::json->pretty(1);
	$Dotiac::DTL::Addon::json::json->ascii(1);
	return $value->set($json->encode($value->content));
}
1;

__END__

=head1 NAME

Dotiac::DTL::Addon::json: Filters to generate JSON data

=head1 SYNOPSIS

Load from a Dotiac::DTL-template:

	{% load json %}

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::json;

Then it can be used:

	{{ data|json|safe }}
	{{ data|json_ascii }}
	{{ data|json_pretty }}
	{{ data|json_pretty_ascii|safe }}

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::json"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

This provides some filters to output any type of data



=head2 Filters

B<Like most other filters, these will return a safe value on safe input. But string literals are always safe and will produce bad output, so beware of those.>

	{{ "Foo"|json }} {# "Foo" #}
	{{ "Foo"|json|escape }} {# &quot;Foo&quot; #}

=head3 json

Converts any value into JSON, even lists and dictionaries.

Output will be in UTF-8.

	data=>{List=>[1,2,3],Value=>"Foo\x{34fc}"};

	<a onclick="return {{ data|json }}"> 
	{# <a onclick="return {&quot;List&quot;:[1,2,3],&quot;Value&quot;:&quot;FooÒô+&quot;}"> #}
	
	var Value={{ data|json|safe }} 
	{# var Value={"List":[1,2,3],"Value":"FooÒô+"} #}

=head3 json_ascii

Like json, but the output will be in ascii. This is useful if the generated HTML page is not utf8.

	data=>{List=>[1,2,3],Value=>"Foo"};

	<a onclick="return {{ data|json_ascii }}"> 
	{# <a onclick="return {&quot;List&quot;:[1,2,3],&quot;Value&quot;:&quot;Foo\u34fc&quot;}"> #}
	
	var Value={{ data|json_ascii|safe }} 
	{# var Value={"List":[1,2,3],"Value":"Foo\u34fc"} #}

=head3 json_pretty

Like json, but with pretty output. This is much larger and mostly not needed.

	data=>{List=>[1,2,3],Value=>"Foo"};

	<a onclick="return {{ data|json_pretty }}"> 
	{# <a onclick="return {
	  &quot;List&quot; : [
	    1,
	    2,
	    3
	  ],
	  &quot;Value&quot; : &quot;FooÒô+&quot;
	 }"> #}
	
	var Value={{ data|json_pretty|safe }} 
	{# var Value={
	  "List" : [
	    1,
	    2,
	    3
	  ],
	  "Value" : "FooÒô+"
	} #}

=head3 json_ascii_pretty

Like json_ascii, but also with pretty output. This is much larger and mostly not needed.

		data=>{List=>[1,2,3],Value=>"Foo"};

	<a onclick="return {{ data|json_ascii_pretty }}"> 
	{# <a onclick="return {
	  &quot;List&quot; : [
	    1,
	    2,
	    3
	  ],
	  &quot;Value&quot; : &quot;Foo\u34fc&quot;
	 }"> #}
	
	var Value={{ data|json_ascii_pretty|safe }} 
	{# var Value={
	  "List" : [
	    1,
	    2,
	    3
	  ],
	  "Value" : "Foo\u34fc"
	} #}

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut

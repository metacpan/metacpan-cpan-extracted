###############################################################################
#jsonify.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.1
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#jsonify.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with this distribution\. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::jsonify;
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


my $oldjsonify;

sub import {
	$oldjsonify = *{Dotiac::DTL::Filter::jsonify};
	*{Dotiac::DTL::Filter::jsonify}=\&jsonify;

}
sub unimport {
	*{Dotiac::DTL::Filter::jsonify} = $oldjsonify;
}

sub jsonify {
	my $value=shift;
	$Dotiac::DTL::Addon::jsonify::json->pretty(0);
	$Dotiac::DTL::Addon::jsonify::json->ascii(1);
	$value->safe(1);
	return $value->set($json->encode($value->content));
}

1;

__END__

=head1 NAME

Dotiac::DTL::Addon::jsonify: Dump any data to json.

=head1 SYNOPSIS

Load from a Dotiac::DTL-template:

	{% load jsonify %}

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::jsonify;

Then it can be used:

	{{ data|jsonify }}

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::jsonify"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

After L<http://www.djangosnippets.org/snippets/1250/>, generates data from json objects.



=head2 Filters

=head3 json

Converts any value into JSON, even lists and dictionaries.

Output will be in ASCII, the returned value will always be safe.

	data=>{List=>[1,2,3],Value=>"Foo\x{34fc}"};

	<a onclick="return {{ data|jsonify|escape }}"> 
	{# <a onclick="return {&quot;List&quot;:[1,2,3],&quot;Value&quot;:&quot;Foo“Ù+&quot;}"> #}
	
	var Value={{ data|jsonify| }} 
	{# var Value={"List":[1,2,3],"Value":"Foo“Ù+"} #}

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 LICENSE

This distribution is published under the terms of the MIT license, which basically 
means "Do with it whatever you want". For more information, see the 
LICENSE file that should be enclosed with this distribution. A copy of
the license is (at the time of writing) also available at
L<http://www.opensource.org/licenses/mit-license.php>.

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

L<Dotiac::DTL::Addon::json> has some more options, but does mostly the same.

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut

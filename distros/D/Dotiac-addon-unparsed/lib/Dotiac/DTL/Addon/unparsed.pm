###############################################################################
#unparsed.pm
#Last Change: 2009-01-16
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.2
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#unparsed.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::unparsed;
use strict;
use warnings;

our $VERSION=0.2;

require Dotiac::DTL::Tag::unparsed;
sub import {
}
sub unimport {}
1;

__END__

=head1 NAME

Dotiac::DTL::Addon::unparsed: Tags to work with unparsed template data

=head1 SYNOPSIS

Load from a Dotiac::DTL-template:

	{% load unparsed %}

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::unparsed;

Then it can be used:

	{% unparsed %}Some text{% endunparsed %}

=head1 DESCRIPTION

This addons includes a tag to work with unparsed template data, this is useful if you want to document Django Template code in a Django Template (using Dotiac::DTL)

It can also be used for 2-pass (or more) templating. The first pass includes static data and the second pass will render the dynamic template:

	{% include "header.html" %}
	{% unparsed %}{% for x in list %}...{% endfor %}
	{% endunparsed %}

This will generate after the first pass:

	Headertext
	{% for x in list %}...{% endfor %}

This is also valid template and can be used by another script.

=head2 Tags

There is only one (for now)

L<Dotiac::DTL::Tag::unparsed>

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut

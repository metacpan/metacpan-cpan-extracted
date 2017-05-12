###############################################################################
#importloop.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.2
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#importloop.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::importloop;
use strict;
use warnings;

require Dotiac::DTL::Tag::importloop;

our $VERSION=0.2;

1;
__END__

=head1 NAME

Dotiac::DTL::Addon::importloop: Import loop variables into the top level namespace

=head1 SYNOPSIS

Load from a Dotiac::DTL-template:

	{% load importloope %}

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::importloop;

Then it can be used in the template:

	posts=>[
	{Title=>"test",Content="A test post",Date=>time},
	{Title=>"My first post",Content="Nothing to say here",Date=>time-3600}
	]

	{% importloop posts %}
		<h1>{{ Title }}</h1> {# Title is now in the main namespace #}
		{{ Content|linebreaks }}
		<em>{{ Date|date:jS F Y H:i" }}</em>
	{% empty %}
		No entries
	{% endimportloop %}

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::importloop"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

Adds the {% importloop %} tag

=head1 Tags

L<Dotiac::DTL::Tag::importloop>: The importloop Tag.

=head1 BUGS

This will make Dotiac slower.

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut

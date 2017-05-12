=head1 NAME

Konstrukt - Web application/design framework

=head1 SYNOPSIS

use Konstrukt;

=head1 DESCRIPTION

This framework aims (beside L<others|/GOALS>) for separation of presentation,
logic and content.

The B<presentation> is basically accomplished with a very powerful
L<templating system|Konstrukt::Plugin::template>, which allows fine grained
modularization of the presentation components (templates can be nested as deep
as you want) and has an easy to use interface, that any non-programmer will
understand.

The B<logic> is encapsulated in plugins, which can be integrated seamlessly
into the websites using a simple tag-interface. You can develop your own plugins
easily and also use the existing plugins for your own ones through the perl-interface
of the existing plugins. The Konstrukt core will do all the nasty donkeywork
for you, so you can concentrate on the logic of your application.

The B<content> for each application-plugin is stored in a database using perl
L<DBI>. The data backends for each plugin are implemented as a separate plugin,
which can be exchanged easily, so the applications can adapt to various
data stores. Static content (layout, static web pages, ...) will be stored
in modular templates.

Your web pages will only describe B<what> they contain, not B<how> they are
generated. They will be as simple as:

	<!-- use a template for the page layout, set the page title to "blog"
	     and use the blog plugin as the content -->
	
	<& template src="/templates/layout.template" title="blog" &>
		<$ content $>
			<& blog / &>
		<$ / $>
	<& / &>

For more information about the Konstrukt Framework and its design goals take a
look at L<Konstrukt::Doc::About>.

An overview of the supplied documentation can be found in L<Konstrukt::Doc>. 

=cut

package Konstrukt;
$Konstrukt::VERSION = 0.5;

require 5.006; #TODO: Check supported perl versions

use strict;
use warnings;

return 1;

=head1 BUGS

Many... Currently tracked for each module at its beginning:

	#FIXME: ...
	#TODO: ...
	#FEATURE: ...

You may get an overview of these by using the supplied C<todo_list.pl> script
or looking in the TODO file.

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Doc>, L<HTML::Mason>, L<Template>, L<Embperl>, L<perl>

=cut


package HTML::Merge;
1;

=head1 NAME

HTML::Merge - Embedded HTML/SQL/Perl system.

=head1 INSTALLATION

After installing the package, activate B<mergecreateinstance> to create an instance in your cgi-bin (or mod_perl) directory.
Follow the directions you get from B<mergecreateinstance> in order to configure
your web server.

You must edit the merge.conf created for you.

=head1 SYNOPSIS

	<HTML>
	<$RQ.'SELECT * FROM customers WHERE customer_id=<$RVAR.cust_id>'>
	<$RLOOP>
		<$RSQL.name> owes <$RSQL.debt><BR>
	</$RLOOP>
	<A HREF="/cgi-bin/merge.pl?template=main_menu.html">
	</HTML>

=head1 DESCRIPTION

Merge is an embedded HTML/Perl/SQL tool for creating dynamic web content.
merge.pl compiles HTML with embeded Perl to Perl CGI programs and run them.

All Merge pages are referred to by B<cgi-bin-dir>/merge.pl?template=B<file.html>

(Important: file.html is a HTML template that located in a directory you choose
and name it on the merge.conf file. Notice for better security, the web server 
must not be able to display the templates dirctory).
although on CGI mode you can define merge.pl as an handler with the Action
directive in Apache.

Using merge.pl under Apache::Registry will utilize Perl's built-in caching to
cache pages using the B<do> command.

Merge uses a configuration file to retrieve information about paths, database
connectivity and debugging. It has an embedded debugging tool and on-line
configuration. To turn that option on, set DEVELOPMENT to 1 in the 
configuration file. Don't forget to set it off before deployment.

Configuration can be changed during development using the toolkit menues,
toolkit menues apear as popup windows on your web browser when you open
a URL of mrege.pl.
 
Alternate configuration files can appear in B</etc/merge.conf> and B<$HOME/.merge>.

As described in the INSTALL document you B<must> set your web server for
each appliaction and copy (or create) links to merge.pl and B<PUBLIC> files
and templates and create system database tables. If you are using a UNIX
system you can use B<mergecreateinstance> that will do thoes tasks for you.

=head1 FILES

	B<merge.pl> Main script, usually a symbolic link to each instance.

	B<merge.conf> Configuration, unique per each instance.

	B<$PREFIX/share/merge/private> Internal scripts.

	B<$PREFIX/bin/merge.cgi> Main script, central.

	B<$PREFIX/bin/merge.conf> Template for configuration files.

	B<$PREFIX/bin/mergecreateinstance> Instance creating script.

=head1 AUTHOR

=over 4

=item *

Design by Oded S. Resnik.

=item *

Versions 1,2,3.35 - 3.45 written by Roi Illouz.

Versions 3.46 -  manitained by Oded resnik and Gabor Szabo.

=item *

Version 3 written by Ariel Brosh RIP (till ver 3.34).

=item *

Toolbox written by Eial Solodki.

Testing & documentation by Noam cassif.

New test & version 3.46 - Gabor Szabo and Oded Resnik.

=back

=head1 COPYRIGHT

Copyright (c) 1999 - 2008 Raz Information Systems Ltd.
http://www.raz.co.il

This package is distributed under the same terms as Perl itself, see the 
Artistic License on Perl's home page.

=head1 SEE ALSO

perl(1), L<HTML::Merge::Tags>, L<HTML::Merge::Ext>.

=cut

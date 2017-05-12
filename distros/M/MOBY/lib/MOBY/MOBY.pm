package MOBY;

use strict;
use warnings;

use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK};
# add versioning to this module
BEGIN {
	$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
	@ISA       = qw{ Exporter };
	@EXPORT    = qw{};
	@EXPORT_OK = qw{}; 
}



# Preloaded methods go here.

1;
__END__

=head1 NAME

MOBY - API for hosting and/or communicating with a MOBY Central registry

=head1 DESCRIPTION

This module serves 2 purposes:

=over 4

=item * Used to do various transactions with MOBY-Central registry, including registering new Object and Service types, querying for these types, registering new Servers/Services, or queryiong for available services given certain input/output or service type constraints.

=item * Aid in the installation of a custom local MOBY-Central registry.

=back

=head2 Package Installation

Installation of this perl package is straightforward!

On *nix machines, install as follows:

=over 4

=item * C<perl Makefile.PL>

=item * C<make test>

=item * C<make install>

=back

On Window machines, substitute C<nmake> for C<make>!

B<Important> if you are upgrading to newer versions, please make sure to remove any files that may be cached by this module! To help you do this, run the script B<moby-s-caching.pl>. For information on using B<moby-s-caching.pl>, use the -h option!

B<Important II> make sure to run C<moby-s-update-db> with the -h option to see if you need to updgrade the db schemas.

=cut

=head2 Installing A Custom MOBY-Central Registry

Assuming that you have already installed this package, the very first thing that you should do is run the script B<moby-s-install.pl>.

This script will do the following:

=over 4

=item * Check for prerequisite modules and warn you if they are missing

=item * Run you through some configuration details

=item * Optionally help you mirror an already existing registry

=item * Optionally install various scripts used by the registry or its' clients

=back

=cut

=head2 BioMOBY Client Installation

Once the module has been installed using the command B<make install>, there is nothing further left for you to do. You are free to start using the BioMOBY API.

=cut

=head2 BioMOBY Server Installation

To set up your own custom registry, you have to ensure that a few things are ready before hand!

=over 4

=item * You have an apache webserver installed/started on your machine

=item * You have mysql installed/started on your machine

=item * You are aware of the full path to the apache cgi-bin directory

=item * You have a mysql username/password with read/write access available to use

=item * You have root priviledges on your machine!

=back

Once you are sure that you satisfy the above items, go ahead and run the B<moby-s-install.pl> script, by typing C<moby-s-install.pl> at the command line. This file was installed onto your machine when you did your 'make install'!

=head3 What Exactly does moby-s-install.pl do?

Like we said before, the install script helps you install/configure your custom MOBY-Central registry.

First of all, the script ensure that you have all of the proper libraries installed.

The very next thing that the script does is prompt you for some information:

=over 4

=item * What is your base installation path for apache?

=item * Where is the conf/cgi-bin directory for apache located?

=item * What is the path to your Perl executable?

=back

Once that information is entered, the script prompts you to set up apache. 

=head4 Apache setup

The following is done when the installation script sets up apache:

=over 4

=item * A mobycentral configuration file is added to your apache conf directory

=item * mySQL connection information is obtained from you and inserted into the the configuration file

=item * mySQL table names for the registry are chosen

=item * Optionally, httpd.conf is edited adding various environment variables necessary for the registry

=back

=cut

Once apache has been set up, the installation script prompts you to set up mySQL. 

During mySQL setup, you will be prompted to either create a complete clone of an existing registry or to simply add the base tables required for a registry to your database.

The very next thing that will happen, is that you will be prompted to install the RESOURCES script. This script is mandatory for those hosting a registry.

During the installation of the RESOURCES script, you will be prompted for a place to store the RDF cache. This directory needs to read/writable by apache.

After installation of the RESOURCES script, you will be prompted to install the LSID authority script. 

The very last thing that the script does is to prompt you install other auxillary scripts. While they are not required, it is recommended to install them.

Please make sure that any file installed into your cgi-bin directory is executable and that you restart apache so that all changes are reflected!

Assuming that you installed the auxillary scripts, from a web browser, browse to the url:

C<http://localhost/cgi-bin/Moby> 

B<Note:> Of course, we are assuming that your localhost is your valid hostname and that the cgi-bin directory location is correct. 

A helper page with various links should be visible. Go ahead and try them out!

=cut

=cut

=head2 FAQ

=head3 When I run the install script, IO::Prompt complains ...

This could mean that the package C<IO::Prompt> is not installed properly.

What version do you have?

C<perl -MIO::Prompt -e'print "$IO::Prompt::VERSION\n";'>

We have tested version 0.99.2 on both *nix machines and windows. Please make sure that you have  that version. If you do not, please remove the one that you have (the cpan module B<CPAN Plus> is very useful here) and install version 0.99.2! Version 0.99.4 doesn't seem to work too well and produces numerous warnings in our module. Other versions have yet to be tested.

=cut

=head3 How can I make the service tester run every hour?

First of all, the service tester only works on *NIX machines and will not work on Windows. The reason is due to a the module IPC::Shareable which doesn't port to windows.

To set up the service tester simply create a cron job. The following is an illustration of how to do this!

=over 4

=item * Edit your crontab (as root): 

C<crontab -e>

=item * Add the following to the top of the crontab 

C<MOBY_CENTRAL_CONFIG=/etc/apache2/mobycentral.config>

=item * Add the actual job:

C<00 * * * * perl /path/to/the/service_tester.pl>

=back

This will set up a cron job to run every start of the hour!

=cut

=head3 How do I set up the RDF Agent?

Detailed instructions for building, installing and configuring the agent can be found at http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Java/docs/ConfigureRDFAgent.html

=cut

=cut

=head2 Missing Features

=over

=item * automatic installation of the RDF Agent

=back

=cut

=head2 Acknowledgement


=cut

=head2 EXPORT

None by default.


=head1 SEE ALSO

For the most up-to-date documentation, visit the BioMOBY website at L<http://biomoby.org>!

If you have questions or comments, please feel free to message us on the following mailing lists:

=over

=item MOBY discussion list L<http://www.biomoby.org/mailman/listinfo/moby-l>

=item MOBY Developers List L<http://www.biomoby.org/mailman/listinfo/moby-dev>

=item MOBY bugs discussion list L<http://www.biomoby.org/mailman/listinfo/moby-bugs>

=back

=head1 AUTHORS


=cut

=head1 COPYRIGHT

Copyright (c) 2007 The Biomoby Consortium.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=cut


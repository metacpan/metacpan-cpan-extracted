package MOSES::MOBY;

use strict;
use warnings;



use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK};
BEGIN {
	$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;
	@ISA       = qw{ Exporter };
	@EXPORT    = qw{};
	@EXPORT_OK = qw{};
}



# Preloaded methods go here.

1;
__END__

=head1 NAME

MOSES::MOBY - Start here! Documentation for the Perl extension for the automatic generation of BioMOBY web services!

=head1 SYNOPSIS

  # to get started, run the install script
  moses-install.pl

  # generate a service implementation, for example HelloBiomobyWorld from samples.jmoby.net
  moses-generate-services.pl samples.jmoby.net HelloBiomobyWorld

  # add your business logic to the module services/HelloBiomobyWorld.pm

  # assuming that you have deployed it, test it!
  moses-testing-service.pl -e http://localhost/cgi-bin/MobyServer.cgi HelloBiomobyWorld

  # read the POD for more details!

=head1 DESCRIPTION

This is the documentation for Perl MoSeS (Moby Services Support). If you are reading this from the C<perldoc> utility, you may notice that some words are missing or that some phrases are incomplete. In order to view this documentation in the manner intended, please view the html version of this documentation that was installed duing B<make install> or the version on B<CPAN>.

First of all, it is assumed that you are familiar with BioMOBY. If this assumption is false, please go to the BioMOBY homepage (L<http://biomoby.org>). 

In addition, this module is used to generate code for BioMOBY web services that are already registered with the registry of your choosing. If the service doesn't exist already, please register it first before proceeding.

Hopefully, you have chosen to install this package so that you can create BioMOBY web services. BioMOBY is a community driven, interoperability project. While the concept is easy to grasp, implementation isn't! 

=head2 Package Installation

Installation of this helpful perl package is straightforward!

On *nix machines, install as follows:

=over 4

=item C<perl Makefile.PL>

=item C<make test>

=item C<make install>

=back

On Window machines, install as follows:

=over 4

=item 	C<perl Makefile.PL>

=item 	C<nmake test>

=item 	C<nmake install>

=back

B<Important> if you are upgrading to MoSeS-Perl version 0.82 or higher, please remove your C<moby-services.cfg> and remember to L<re-install|"MoSeS Installation"> MoSeS!

=cut

=head2 MoSeS Installation

Assuming that you have already installed this package, the very first thing that you should do is run the script B<moses-install>.

This script will do the following:

=over 4

=item * Check for prerequisite modules

=item * Run you through some configuration for the Perl MoSeS modules

=item * Optionally create a cache directory and fill it for you

=item * Create the logging and service configuration files

=back

Once the installation process is complete, you can create your first service!

=cut

=head2 Moby Services Support in Perl

Perl MoSeS, is a project aiming to help BioMoby service providers develop their code in Perl.

The basic design principles are the same: to provide libraries that allow a full object-oriented
approach to BioMoby entities (data types and service instances) and shielding service developers 
from all XML wrappers and envelopes. The BioMoby entities are taken from the local cache,
mirroring BioMoby registries, and thus allowing fast access to all needed details.

Because Perl offers more ways to do things (a freedom that one pays for by her 
own responsibility to do rather good than bad things) Perl Moses differs 
slightly from its Java brother - mainly by not insisting to create all necessary 
objects in advance but building them on-the-fly.

=head2 New Features

Some of the new features included in this release are:

=over 4

=item * Support for Asynchronous CGI based moby services

=item * Support for CGI based moby services

=item * Support for Asynchronous based moby services

=item * Service developers can now enable the validation of namespaces

=back 

=cut

=head2 Overview

Perl Moses is a generator of Perl code - but this code does not need to be always stored in files, it can be generated on-the-fly every time a service is called. Also, there are up to four things to be generated: objects representing BioMoby data types, classes establishing bases for services, empty (but working) service implementation modules, and cgi-bin scripts, the entry points to BioMoby services.

However, before going to gory details, let's install Perl Moses, create and call the first service. 

=cut


=head3 Quick Start - Five Steps to the First Service

=over

=item 1. Download the MoSeS module, and install it.

=item 2. Run the installation script for MoSeS

This will create/update your local cache of a BioMoby registry. Which may take several minutes when run the first time.

From the command prompt, enter:

C<moses-install>

or, 

C<moses-install.pl>


This works, because part of the installation for the MoSeS module entails the installation of scripts that make MoSeS tasks more simple.

=item 3. Generate a service.

You can pick up almost any service form the registered ones - just type its authority and name:

C<moses-generate-services samples.jmoby.net HelloBiomobyWorld>

or,

C<moses-generate-services.pl samples.jmoby.net HelloBiomobyWorld>


It creates a Perl module Service::HelloBiomobyWorld (in E<lt>your-home-directoryE<gt>/Perl-MoSeS/services/), representing your first BioMoby Web Service . The service is empty - but is already able to accept BioMoby input requests and recognize its own data type, and it produces fake output data - but again, the output data are of the correct type (as registered for this service).

You can even generate more (or all) services for your authority: 

C<moses-generate-services.pl samples.jmoby.net>

=item 4. Make your service available from your Web Server (this is called deploying). 

The only thing you need to do is to tell your Web Server where there is a starting cgi-bin script. The script was already created during the installation in E<lt>your-home-directoryE<gt>/Perl-MoSes/ directory. Make a symbolic link from a cgi-bin directory of your Web Server (e.g on some Linux distributions, using Apache Web server, the cgi-bin directory is /usr/lib/cgi-bin). 

For example:

=begin html

<pre>
cd /usr/lib/cgi-bin
sudo ln -s /home/senger/Perl-MoSeS/MobyServer.cgi .
</pre>

=end html

on windows, you can mimic the L<above|"How can I tell apache to execute MobyServer.cgi on Windows without moving the file to cgi-bin?">

If you cannot create Symbolic links, or apache is not allowed to follow them, try this L<workaround|"Cannot Create Symbolic links">

If you plan on developing asynchronous moby services, then don't forget to also create a symbolic link for B<AsyncMobyServer.cgi> as well!

=item 5. Last but not least: call your service. 

There is a testing client that sends only empty data (so it can be used by any service):

=begin html

<pre>moses-testing-service.pl -e http://localhost/cgi-bin/MobyServer.cgi HelloBiomobyWorld</pre>

=end html

Of course, you can also send real data, from a local file:

=begin html

<pre>moses-testing-service.pl -e http://localhost/cgi-bin/MobyServer.cgi \
     HelloBiomobyWorld  \
     data/my-input.xml
</pre>

=end html

The output (the same with any input data) is not really that exciting:

=begin html

<pre>
&lt;?xml version="1.0"?&gt;
&lt;moby:MOBY xmlns:moby="http://www.biomoby.org/moby"&gt;
  &lt;moby:mobyContent moby:authority="samples.jmoby.net"&gt;
    &lt;moby:serviceNotes&gt;
      &lt;moby:Notes&gt;Response created at Sun Jul 30 12:24:49 2006 (GMT), by the service 'HelloBiomobyWorld'.&lt;/moby:Notes&gt;
    &lt;/moby:serviceNotes&gt;
    &lt;moby:mobyData moby:queryID="job_0"&gt;
      &lt;moby:Simple moby:articleName="greeting"&gt;
        &lt;moby:String moby:id="" moby:namespace=""&gt;this is a value &lt;/moby:String&gt;
      &lt;/moby:Simple&gt;
    &lt;/moby:mobyData&gt;
  &lt;/moby:mobyContent&gt;
&lt;/moby:MOBY&gt;
</pre>

=end html

You immediately notice that the returned value does not even have an expected "hello" greeting but only a plain "this is a value". Well, a fake output is just a fake output. You would need to add your own business logic into your service to do something meaningful (such as saying warmly "Hello, Biomoby").

But even with an empty input and fake output, you can see that the output knows about the HelloBiomobyWorld service (see the output type moby:String and the article name greeting, both coming from the registry knowledge). 

Also, the service provider can see few log entries:

=begin html

<pre>
2007/07/30 13:24:49 (673) INFO&gt; [19345] (eval 127):92 - *** REQUEST START ***
   REMOTE_ADDR: 127.0.0.1, HTTP_USER_AGENT: SOAP::Lite/Perl/0.60,
   CONTENT_LENGTH: 736, HTTP_SOAPACTION: "http://biomoby.org/#HelloBiomobyWorld"
2007/07/30 13:24:49 (721) INFO&gt; [19345] (eval 127):160 - *** RESPONSE READY ***
</pre>

=end html

The number in square brackets is a process ID - it helps to find which response belongs to which request when a site gets more to many requests in the same time. And in parenthesis, there is the number of milliseconds since the program has started. More about the log format in L<logging|"Logging">.

=back

=cut

=head3 Motivation

Many people will be tempted to ask "how does Perl Moses differ from CommonSubs.pm, a library already available (and heavily used) in BioMoby"?

An honest answer is "I do not know". Because I never wrote any BioMoby service based on CommonSubs.pm. As far as I know the CommonSubs.pm are good, reliable and used. I think (guessing), however, that Perl Moses allows few things that CommonSubs.pm have not aimed for:m

=over

=item * Fully object-oriented approach,

 based on objects created on-the-fly (or pre-generated) from the local cache representing a Biomoby registry.

=item * More centralized 

(and therefore easier changeable if/when needed) support for service configuration, for request logging, and even for protocol binding (for example, in your service implementation code there are no visible links to SOAP).

In other words, the services written with the Perl Moses as their back-end are more unified and less prone to be changed when their environment changes. They should differ really only in their business logic (what they do, and not how they communicate with the rest of the world). 

=back

Having said that it is fair also to add that C<CommonSubs.pm> have been used for a while so people already have found and fixed their bugs, a process Perl Moses has yet to go through.

And, of course, the greatest motivation comes from the spirit of the Perl slogan of TMTOWTDI,
 I<There's more than one way to do it>.

=cut

=head2 Bits and Pieces

=cut

=head3 Requirements

The other modules needed are (all available from the CPAN):

=over

=item * File::Spec

=item *
    XML::LibXML - this is always needed because it creates XML BioMoby response. But other (perhaps more efficient) parsers can be used for parsing the input requests. More about it in the L<configuration|"Configuration"> section.

=item * Log::Log4perl 
	- a wonderful port of the famous log4j Java logging system.

=item *
    Template - a modern Perl Template Toolkit, a really fascinating tool.

=item *
    Config::Simple - for a simple service configuration

=item *
    IO::Stringy - a.k.a. IO::Scalar

=item *
    Unicode::String

=item *
    File::HomeDir

=item *
	File::ShareDir

=item *
    SOAP::Lite, of course

=item *
    FindBin

=item *
    IO::Prompt - try to install version 0.99.2 and not 0.99.4

=item *
    WSRF::Lite - for developing asynchronous moby services I<Optional>

=back

=cut

=head3 Local Cache of a BioMOBY Registry

Perl Moses takes all information from a local cache that stores details about registered BioMoby data types and services. The cache is represented by several flat-files (they can contain details about several BioMoby registries). You can consider the cache as configuration files used by your Perl programs.

In order to start anything related to Perl Moses (except perhaps the script moses-config-status), you need to create, or update the cache. Take it as a requirement. 

The script, I<moses-install> intially creates the cache for you, while the scripts I<moses-generate-datatypes> and I<moses-generate-services> update the datatypes and services cache respectively. More on the L<Scripts|"Scripts">" below.

You need to tell Perl Moses (i.e. to tell your service implementation) where the cache is located. It is done through the L<Configuration|"Configuration">.

Okay. Having said all that, have you heard about The Law of Leaky Abstractions? Because - in case our abstraction does not leak - you can move the above to a lower rack in your memory, and let the Perl Moses installation script deal with the local cache. But - as the article says - It's good to know.

=cut

=head3 Installation

The installation script is (as well as the other Perl Moses scripts) installed at module install time and is available from any command prompt. You should run it the first time, and you can run it anytime later again. The files that are already created are not overwritten - unless you want it to be, and the local cache will be updated only after your confirmation.


C<moses-install>

This is an example of a typical conversation and output of the first installation:

=begin html

<pre>
senger@sherekhan:~/$ moses-install

Welcome, BioMobiers. Preparing stage for Perl MoSeS...
------------------------------------------------------
OK. Module FindBin is installed.
OK. Module SOAP::Lite is installed.
OK. Module XML::LibXML is installed.
OK. Module Log::Log4perl is installed.
OK. Module Template is installed.
OK. Module Config::Simple is installed.
OK. Module IO::Scalar is installed.
OK. Module IO::Prompt is installed.
<br/>
Installing in /home/senger/Perl-MoSeS/
<br/>
Created log file '/home/senger/Perl-MoSeS/services.log'.<br/>
Created log file '/home/senger/Perl-MoSeS/parser.log'.
<br/>
Log properties file created: '/home/senger/Perl-MoSeS/log4perl.properties'
<br/>
Web Server file created: '/home/senger/Perl-MoSeS/MobyServer.cgi'
<br/>
Directory for local cache [/home/senger/Perl-MoSeS/myCache]<br/>
Local cache in '/home/senger/Perl-MoSeS/myCache'.
<br/>
Should I try to fill or update the local cache [y]? y<br/>
What registry to use? [default]
     a. IRRI
     b. MIPS
     c. default
     d. iCAPTURE
     e. testing
&nbsp;
> a
Using registry: IRRI (at http://cropwiki.irri.org/cgi-bin/MOBY-Central.pl)<br/>

Creating the local cache (it may take several minutes)...<br/>

Configuration file created: '/home/senger/Perl-MoSeS/moby-services.cfg'<br/>
Done.<br/>

</pre>

=end html

All these things can be done manually, at any time. Installation script just makes it easier for the first comers. Here is what the installation does:

    * It checks if all needed third-party Perl modules are available. 
	Since you got this far, they most likely are! It does not help with 
	installing them, however. Perl has a CPAN mechanism in place to do 
	that. The required modules are listed in requirements. Installation
	stops if some module is not available.

    * It creates a directory called 'Perl-MoSeS' in your user directory.
	Perl MoSeS will stop working if you move this directory because it 
	contains vital configuration information inside it.

    * It creates two empty log files Perl-MoSeS/services.log and
	Perl-MoSeS/parser.log - unless they already exist. In any case,
	it changes their permissions to allow everybody to write to them.
	This helps later, when the same log files are written to by a Web
	Server. The purpose of these two files is described in logging.

    * It creates a Perl-MoSeS/log4perl.properties file from a distributed
	template, and updates their locations to reflect your local
	installation. Again, more about this file in logging.

    * It creates a Perl-MoSeS/MobyServer.cgi file from a distributed
	template, and updates their locations to reflect your local
	installation. This is a cgi-bin script that will be started by
	your web server when a BioMoby request comes. More about it in
	deploying.
	
	* It creates a Perl-MoSeS/AsyncMobyServer.cgi file from a distributed
	template, and updates their locations to reflect your local
	installation. This is a cgi-bin script that will be started by
	your web server when an asynchronous BioMoby request comes. More 
	about it in	deploying.

    * For Perl Moses, the most important configuration option is the location
	of your local cache (a place where a BioMoby registered entities are mirrored).
	The installation script asks for it, unless there already exists a configuration 
	file Perl-MoSeS/moby-services.cfg - in which case the installation scripts 
	tries to take this option from there.

    * Knowing where to cache BioMoby entities, the script asks whether you want
	to do so, and if yes which BioMoby registry to contact to. Then it starts
	updating the cache. Be patient. But even if you interrupt it, next time 
	it will start where it was interrupted, and not at the beginning. Depending
	how your logging in jMoby is configured, you may see the progress on the 
	screen, or in a log file. But usually you do not need it - just wait. If
	there is an error, it will be reported, do not worry.

    * Finally, it creates a configuration file Perl-MoSeS/moby-services.cfg 
	(unless it already exists). See more about how to further configure Perl 
	Moses in configuration.

If you wish to install from the scratch (the same way it was done the first time), start it by using a force option:

C<moses-install -F>

In this mode, it overwrites the files I<moby-services.cfg>, I<services.log>, I<parser.log> and I<log4perl.properties>.

There is a little extra functionality going on behind the scenes: If the configuration file C<moby-services.cfg> exists when you start the installation script, its values are used instead of default ones. It may be useful in cases when you plan to put all Perl Moses directories somewhere else (typically and for example, if your Web Server does not support symbolic links that can point to the current directories). In such cases, edit your moby-services.cfg, put the new locations inside it, and run C<moses-install> again. 

=cut

=head3 What Perl MoSeS Really Does

Perl Moses generates Perl code. Actually, up to four pieces of the code:

=cut

=head4 Perl Objects Representing BioMOBY Datatypes

Each BioMoby data type, as registerd in a BioMoby registry, is represented by a Perl object MOSES::MOBY::Data::<moby-data-type-name>. For example, a GenericSequence object looks like this:

=begin html

<pre>
#-----------------------------------------------------------------
# MOSES::MOBY::Data::GenericSequence
# Generated: 30-Jul-2007 14:55:09 BST
# Contact: Martin Senger &lt;martin.senger@gmail.com&gt; or
#          Edward Kawas &lt;edward.kawas@gmail.com&gt;
#-----------------------------------------------------------------
package MOSES::MOBY::Data::GenericSequence;
no strict;
use vars qw( @ISA );
@ISA = qw( MOSES::MOBY::Data::VirtualSequence );
use strict;
use MOSES::MOBY::Data::Object;
&nbsp;
#-----------------------------------------------------------------
# accessible attributes
#-----------------------------------------------------------------
{
    my %_allowed =
        (
         'SequenceString' =&gt; {type =&gt; 'MOSES::MOBY::Data::String'},
         );<br/>
    sub _accessible {
        my ($self, $attr) = @_;
        exists $_allowed{$attr} or $self-&gt;SUPER::_accessible ($attr);
    }
    sub _attr_prop {
        my ($self, $attr_name, $prop_name) = @_;
        my $attr = $_allowed {$attr_name};
        return ref ($attr) ? $attr-&gt;{$prop_name} : $attr if $attr;
        return $self-&gt;SUPER::_attr_prop ($attr_name, $prop_name);
    }
}<br/><br/>1;<br/>
...
&nbsp;
</pre>

=end html

The BioMoby data type objects are generated either on-the-fly (more about it in a moment), or by using the C<moses-generate-datatypes> L<script|"Scripts">.

=cut

=head4 Perl Modules Representing Bases of Service Implementations

Each Perl Moses service implementation can benefit by inheriting some basic functionality from its base. These bases contain the code specific for the given service (e.g. they know who is the service authority and can, therefore, add it automatically into the response).

The service base takes care about:

    * Logging request/response.
    * Allowing to run a service locally, outside of the SOAP environment (good for early testing).
    * Catching and reporting exceptions if the input is wrong or incomplete.
    * Returning request at once if it is completely empty (this is the recently discussed ping feature).
    * Dealing with more queries (jobs) in a request.
    * Dealing with SOAP::Lite. 

You can see its code by running (for example):

C<moses-generate-services -sb samples.jmoby.net Mabuhay>

Again, the services bases can be generated and loaded on-the-fly, or pre-generated in the files.

=cut

=head4 Perl Modules Representing Empty Service Implementations

This is your playground! What is generated is only an empty service implementation - and you are supposed to add the meat - whatever your service is expected to do.

Well, it is not that empty, after all.

First, because it inherits from its base, it already knows how to do all the features listed in the paragraph above:

=begin html

<pre>
#-----------------------------------------------------------------
# Service name: Mabuhay
# Authority:    samples.jmoby.net
# Created:      29-Jul-2006 23:43:54 BST
# Contact:      martin.senger@gmail.com
# Description:  How to say "Hello" in many languages. Heavily based
#       on a web resource "Greetings in more than 800 languages",
#       maintained at http://www.elite.net/~runner/jennifers/hello.htm
#       by Jennifer Runner.
#-----------------------------------------------------------------
&nbsp;
package Service::Mabuhay;
&nbsp;
use FindBin qw( $Bin ); 
use lib $Bin; 
&nbsp;
#-----------------------------------------------------------------
# This is a mandatory section - but you can still choose one of
# the two options (keep one and commented out the other):
#-----------------------------------------------------------------
use MOSES::MOBY::Base;
# --- (1) this option loads dynamically everything
BEGIN {
    use MOSES::MOBY::Generators::GenServices;
    new MOSES::MOBY::Generators::GenServices->load
	(authority     => 'samples.jmoby.net',
	 service_names => ['Mabuhay']);
} 
&nbsp;
# --- (2) this option uses pre-generated module
#  You can generate the module by calling a script:
#    moses-generate-services -b samples.jmoby.net Mabuhay
#  then comment out the whole option above, and uncomment
#  the following line (and make sure that Perl can find it):
#use net::jmoby::samples::MabuhayBase;
&nbsp;
# (this to stay here with any of the options above)
use vars qw( @ISA );
@ISA = qw( net::jmoby::samples::MabuhayBase );
use MOSES::MOBY::Package;
use MOSES::MOBY::ServiceException;
use strict;
</pre>

=end html

Second, it has the code that reads the input, using methods specific for this service. It does not do anything with the input, but the code shows you what methods you can use and how:

=begin html

<pre>
# read input data (eval to protect against missing data)
my $language = eval { $request->language };
&nbsp;
my $format = eval { $language->format->value };
my $dotall_mode = eval { $language->dotall_mode->value };
my $regex = eval { $language->regex->value };
my $literal_mode = eval { $language->literal_mode->value };
my $multiline_mode = eval { $language->multiline_mode->value };
my $case_insensitive = eval { $language->case_insensitive->value };
my $comments = eval { $language->comments->value };
</pre>

=end html

And finally, it produces a fake output (not related to the input at all). Which is good because you can call the service immediately, without writing a single line of code, and because you see what methods can be used to create the real output:

=begin html

<pre>
# EDIT: PUT REAL VALUES INTO THE RESPONSE
# fill the response
foreach my $elem (0..2) {
    my $hello = new MOSES::MOBY::Data::simple_key_value_pair
        (
         value => "this is a 'value $elem'",   # TO BE EDITED
         key => "this is a 'key $elem'",   # TO BE EDITED
         );
    $response->add_hello ($hello);
}
</pre>

=end html

The service implementations are definitely not generated on-the-fly. They must be pre-generated into a file (because you have to edit them, donn't you?). 

Again, the C<moses-generate-services> script will do it. More in L<scripts|"Scripts">.

=cut

=head4 A Dispatch Table Used By a cgi-bin Entry Point

A small but important piece of code is a dispatch table that contains all service names you wish to be used from your site, using the same launching cgi-bin script. By default, it is named SERVICES_TABLE, and it is updated every time you add (deploy) a new service. For example, this is a dispatch table for all services from the authority samples.jmoby.net:

=begin html

<pre>
$DISPATCH_TABLE = {
    'http://biomoby.org/#HelloBiomobyWorld' => 'Service::HelloBiomobyWorld',
    'http://biomoby.org/#TextExtract' => 'Service::TextExtract',
    'http://biomoby.org/#getRandomImage' => 'Service::getRandomImage',
    'http://biomoby.org/#Mabuhay' => 'Service::Mabuhay',
    'http://biomoby.org/#getRandomImage2' => 'Service::getRandomImage2'
};
</pre>

=end html

The dispatch table is also not generated on-the-fly. It is updated every time a service implementation is generated. Again, the C<moses-generate-services> scripts will do it. More in L<scripts|"Scripts">.

So, how do all of these pieces fit together? Here we go:

=begin html

<a href="http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Java/docs/images/PerlMoses-architecture.jpg">
<img border="0" src="http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Java/docs/images/PerlMoses-architecture-small.jpg"/>
</a>

=end html

=cut

=head3 Scripts

Scripts

The scripts are small programs that generate pieces and that let you test things.

They share some basic features:

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* They are automatically installed with the perl module.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* They can be started from anywhere.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* They all are Perl programs, expecting Perl executable in /usr/bin/perl. If your perl is elsewhere, start them as:

E<nbsp>E<nbsp>E<nbsp>E<nbsp>E<nbsp>E<nbsp>E<nbsp>E<nbsp>perl -w E<lt>script-nameE<gt>

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* They all recognize an option -h, giving a short help. They also have options -v (verbose) and -d (debug) for setting the level of logging.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* Usually, they also need additional information (such as where to find local cache) from the configuration file moby-services.cfg. 

Here they are in the alphabetic order:

=head4 moses-config-status

This script does not do much but gives you overview of your configuration and installation. You can run it to find how Perl Moses will behave when used. For example:

=begin html

<pre>
Perl-MoSeS VERSION: 0.8
&nbsp;
Configuration
-------------
Default configuration file: moby-services.cfg
Environment variable BIOMOBY_CFG_DIR is not set
Successfully read configuration files:
        moby-services.cfg
All configuration parameters:
        Mabuhay.resource.file => /home/senger/Perl-MoSeS/samples-resources/mabuhay.file
        cachedir => /home/senger/Perl-MoSeS/myCache
        default.cachedir => /home/senger/Perl-MoSeS/myCache
        default.registry => default
        generators.impl.outdir => /home/senger/Perl-MoSeS/services
        generators.impl.package.prefix => Service
        generators.impl.services.table => SERVICES_TABLE
        generators.outdir => /home/senger/Perl-MoSeS/generated
        log.level => debug
        registry => default
All imported names (equivalent to parameters above):
        $MOBYCFG::CACHEDIR
        $MOBYCFG::DEFAULT_CACHEDIR
        $MOBYCFG::DEFAULT_REGISTRY
        $MOBYCFG::GENERATORS_IMPL_OUTDIR
        $MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX
        $MOBYCFG::GENERATORS_IMPL_SERVICES_TABLE
        $MOBYCFG::GENERATORS_OUTDIR
        $MOBYCFG::LOG_CONFIG
        $MOBYCFG::LOG_FILE
        $MOBYCFG::LOG_LEVEL
        $MOBYCFG::LOG_PATTERN
        $MOBYCFG::MABUHAY_RESOURCE_FILE
        $MOBYCFG::REGISTRY
        $MOBYCFG::XML_PARSER
XML parser to be used: XML::LibXML::SAX
&nbsp;
Logging
-------
Logger name (use it in the configuration file): services
Available appenders (log destinations):
        Screen: stderr
Logging level FATAL: true
Logging level ERROR: true
Logging level WARN:  true
Logging level INFO:  true
Logging level DEBUG: true 
&nbsp;
Testing log messages (some may go only to a logfile):
2006/07/30 22:44:22 (295) FATAL> [[undef]] config-status.pl:117 - Missing Dunkin' Donuts
2006/07/30 22:44:22 (296) ERROR> [[undef]] config-status.pl:118 - ...and we are out of coffee!
</pre>

=end html

=cut

=head4 moses-generate-datatypes

This script generates Perl objects representing BioMoby data types. Use this script if you wish to pre-generate some or all BioMoby data types. You do not need to - but you can. If your service is called and its data types are not pre-generated, the service knows how to generate and load them on-the-fly.

This will generate all data types (it does not take that long: 300 data types just about 2.4 seconds on my laptop):

C<moses-generate-datatypes>

You may see the progress on your screen if your logging is in debug level, and directed to the screen (more about it in L<logging|"Logging">).

You may generate also only named data types, of course. In which case, the script still asks the generator to generate also related data types (those representing the members of generated data types). It seems a reasonable assumption. For example, for:

C<moses-generate-datatypes -d DNASequenceWithGFFFeatures>

the script reports to a log file (note the -d option to log in debug mode):

=begin html

<pre>
2006/07/30 23:00:33 (492) INFO> [[undef]] GenTypes.pm:125 - Data types will be generated into: '/home/senger/Perl-MoSeS/generated'
2006/07/30 23:00:33 (493) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::BasicGFFSequenceFeature will be generated
2006/07/30 23:00:33 (665) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::DNASequence will be generated
2006/07/30 23:00:33 (669) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::DNASequenceWithGFFFeatures will be generated
2006/07/30 23:00:33 (673) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::GenericSequence will be generated
2006/07/30 23:00:33 (676) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::NucleotideSequence will be generated
2006/07/30 23:00:33 (680) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::VirtualSequence will be generated
2006/07/30 23:00:33 (684) DEBUG> [[undef]] GenTypes.pm:149 - MOSES::MOBY::Data::multi_key_value_pair will be generated
</pre>

=end html

An obvious question is "where are the data types generated to"?

You can always determine this after generation by looking in the log file - the message has the INFO level which means it is almost always logged. But, if you want to know in advance here are the rules:

E<nbsp>E<nbsp>E<nbsp>E<nbsp>1. If there is a generators.outdir parameter in the configuration file, it is used. It defines the directory where data types are created.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>2. Otherwise, program is trying to find an existing directory named 'generated' anywhere in the @INC (a set of directories used by Perl to locate its modules).

E<nbsp>E<nbsp>E<nbsp>E<nbsp>3. If it fails, it creates a new directory 'generated' in the "current" directory.

You can use option I<-s> to get the generated result directly on the screen (in that case no file is created).

You can use the option B<-u> to update the datatype cache.

You can use the option B<-f> to fill the datatype cache.

The B<-R> option allows you to specify a registry endpoint. For instance, -R http://moby.ucalgary.ca/moby/MOBY-Central.pl would cause the script to use UCalgary registry.

The BioMoby primitive types (String, Integer, Float, Boolean and DateTime) are never generated. They were created manually.

For test-oriented geeks, here is how to check that the generated data types are syntactically correct (using Unix and bash commands):

=begin html

<pre>
senger@sherekhan:moses-generate-datatypes
Generating all data types.
Done.
senger@sherekhan:for n in ~/Perl-MoSeS/generated/MOSES/MOBY/Data/*.pm ; do perl -c $n ; done
generated/MOSES/MOBY/Data/ABI_Encoded.pm syntax OK
generated/MOSES/MOBY/Data/Ace_Text.pm syntax OK
generated/MOSES/MOBY/Data/Alignment.pm syntax OK
...
generated/MOSES/MOBY/Data/WU_BLAST_Text.pm syntax OK
generated/MOSES/MOBY/Data/xdom_flatfile.pm syntax OK
generated/MOSES/MOBY/Data/zPDB.pm syntax OK
senger@sherekhan:~/jMoby/src/Perl$
</pre>

=end html

=cut

=head4 moses-generate-services

This is the most important script. You may use only the C<moses-install> and this one - and you will get all what you need. It generates services - all pieces belonging to services (except data types - for that, there is L<moses-generated-datatypes|"moses-generate-datatypes"> script).

Usually, you generate code for one or only several services. And because each service belongs to an authority you need to tell both:

C<moses-generate-services samples.jmoby.net Mabuhay>

If you specify only an authority the code for all services from this authority will be generated:

C<moses-generate-services samples.jmoby.net>

Without any options (as shown above), it will generate service implementation classes, and it will update the dispatch table. However, it does not overwrite already existing service implementation - that would be dangerous because you may have already edited and added the real business logic:

=begin html

<pre>
Generating services from samples.jmoby.net:
Implementation '/home/senger/Perl-MoSeS/services/Service/TextExtract.pm' already exists.
       It will *not* be re-generated. Safety reasons.
Implementation '/home/senger/Perl-MoSeS/services/Service/getRandomImage.pm' already exists.
       It will *not* be re-generated. Safety reasons.
Implementation '/home/senger/Perl-MoSeS/services/Service/HelloBiomobyWorld.pm' already exists.
       It will *not* be re-generated. Safety reasons.
Implementation '/home/senger/Perl-MoSeS/services/Service/Mabuhay.pm' already exists.
       It will *not* be re-generated. Safety reasons.
Done.
</pre>

=end html

[ There is an option to repress this cautious behaviour - look into the script itself.]

There are several L<configurables options|"Configuration"> to influence the result:

C<generators.impl.outdir> dictates where the code is to be generated. If this option does not exists, similar rules as described in C<moses-generate-datatypes> are used (except the default name is services and not generated).

C<generators.impl.package.prefix> tells what package name should be used (the package name always ends with the service name as it is registered in the BioMoby registry). Default is Service.

C<generators.impl.services.table> is a name of a dispatch table. Default is SERVICES_TABLE.

With options, you can generated other Perl Moses pieces:

=begin html

<pre>
   Option <strong>-b</strong> generates <a href="#perl_modules_representing_bases_of_service_implementations">service bases</a>,
&nbsp;
   Option <strong>-t</strong> only updates the <a href="#a_dispatch_table_used_by_a_cgibin_entry_point">dispatch table</a>, and<p/>
   Option <strong>-S</strong> generates both <a href="#perl_modules_representing_bases_of_service_implementations">service bases</a> 
   and service implementations (and it updates dispatch table, as well). 
   This also influences how the service base will be used at run-time: 
   if it is already generated (with the -S option) there is no need to 
   do it again in the run-time - therefore, the service implementation 
   is generated slightly differently - with an option "use the base, 
   rather than load the base" enabled.<p/>
   Option <strong>-c</strong> generates both a <a href="#perl_modules_representing_bases_of_service_implementations">service implementation</a> 
     as well as a CGI dispatcher script.<p/>
   Option <strong>-C</strong> generates both a <a href="#perl_modules_representing_bases_of_service_implementations">service implementation</a> 
     as well as an Asynchronous CGI dispatcher script.<p/>
   Option <strong>-A</strong> generates both a <a href="#perl_modules_representing_bases_of_service_implementations">service implementation</a> 
     as well as an asynchronous module (and it updates the dispatcher table, as well).<p/>
   Option <strong>-u</strong> updates the service cache.<p/>
   Option <strong>-f</strong> fills the service cache.<p/>
   Option <strong>-R</strong> allows you to specify a registry endpoint.
       For instance, 
             <em>-R http://moby.ucalgary.ca/moby/MOBY-Central.pl</em>
       would cause the script to use UCalgary registry.
</pre>

=end html

As with generated data types, here also you can use option I<-s> to get the generated result directly on the screen (in that case no file is created).

For testing (and for fun) you can generate all services from all authorities (this time it is not that fast as data types, it takes almost 17 seconds - but who cares?):

C<moses-generate-services -Sa>

In order to test syntax of all services, don't try the same trick as with data types, but look for the C<moses-universal-testing> script.

=cut

=head4 moses-install

This script is used for L<installation|"Installation">.

=cut

=head4 moses-known-registries

The Perl Moses has a hard-coded list of known BioMoby registries. New entries can be added - check the comments in MOSES::MOBY::Cache::Registries. Each registry has an abbreviation (a synonym) that can be used in Perl Moses configuration - it is easier and less error-prone than using the long registry's endpoint. This script can tell you which registry has which synonym (and few other things about it).

C<moses-known-registries>

At the time of writing this documentation, the response was (note that one of the registries is labeled as the "default" one):

=begin html

<pre>
IRRI, MIPS, default, iCAPTURE, testing
$Registries = {
   'testing' => {
      'namespace' => 'http://bioinfo.icapture.ubc.ca/MOBY/Central',
      'public' => 'yes',
      'name' => 'Testing BioMoby registry',
      'contact' => 'Edward Kawas (edward.kawas@gmail.com)',
      'endpoint' => 'http://bioinfo.icapture.ubc.ca/cgi-bin/mobycentral/MOBY-Central.pl'
      },
   'IRRI' => {
      'namespace' => 'http://cropwiki.irri.org/MOBY/Central',
      'text' => 'The MOBY registry at the International Rice Research
Institute (IRRI) is intended mostly for Generation Challenge Program
(GCP) developers. It allows the registration of experimental moby
entities within GCP.',
       'public' => 'yes',
       'name' => 'IRRI, Philippines',
       'contact' => 'Mylah Rystie Anacleto (m.anacleto@cgiar.org)',
       'endpoint' => 'http://cropwiki.irri.org/cgi-bin/MOBY-Central.pl'
       },
   'iCAPTURE' => {
       'namespace' => 'http://moby.ucalgary.ca/MOBY/Central',
       'text' => 'A curated public registry hosted at the iCAPTURE Centre, Vancouver',
       'public' => 'yes',
       'name' => 'iCAPTURE Centre, Vancouver',
       'contact' => 'Edward Kawas (edward.kawas@gmail.com)',
       'endpoint' => 'http://moby.ucalgary.ca/moby/MOBY-Central.pl'
       },
   'default' => $Registries->{'iCAPTURE'},
   'MIPS' => {
       'namespace' => 'http://mips.gsf.de/MOBY/Central',
       'name' => 'MIPS, Germany',
       'contact' => 'Dirk Haase (d.haase@gsf.de)',
       'endpoint' => 'http://mips.gsf.de/cgi-bin/proj/planet/moby/MOBY-Central.pl'
       }
};
</pre>

=end html

This script does not have any options (nor the help). 

=cut

=head4 moses-user-registries

The Perl Moses has a hard-coded list of known BioMoby registries. New entries can be added by using this script. Each registry has an abbreviation (a synonym) that can be used in Perl Moses configuration - it is easier and less error-prone than using the long registry's endpoint. This script can allow you to add or remove these registries and in combination with the C<moses-known-registries> script, provide a wealth of information regarding the registries that you use.

C<moses-user-registries>

Before we begin, it should be noted that you cannot remove the hard-coded list of known registries using this tool. Only those registries that you have personally added can be removed.

To begin a session of modification of your persistant user registry store, run the script!

=begin html

<pre>

OK. Module Term::ReadLine is installed.
Modify Your Persistant Registries
------------------------------------------------------
&nbsp;
Not in over-write mode ...
&nbsp;
Would you like to add or remove a registry? [a]
     a. Add a new persistent user registry
     b. Remove a persistent user registry
     c. Quit
&nbsp;
</pre>

=end html

When you start the script, you are given 3 choices. 

=over

=item Add a new persistent user registry

=item Remove a persistent user registry

=item Quit

=back

If you choose to add a registry, you will be prompted to enter the various pieces of information need for storing your registry.

Alternatively, you may choose to remove a registry from the list. When you select this option, you will be given the list of registries available and you can attempt to remove them. Only those registries that you have added personally can be removed.

Obviously, choosing to I<Quit> will end the session.

=cut

=head4 moses-local-cache

Local cache is explained in the L<local cache|"Local Cache of a BioMOBY Registry"> section. This script can show what is in the cache. It may be useful for implementing a service because the generated service implementation uses article names as method names - and this script shows all article names.

Show a data type:

C<moses-local-cache -t DNASequence>

=begin html

<pre>
-> MOSES::MOBY::Def::DataType=HASH(0x86026b8)
   'authority' => 'www.illuminae.com'
   'children' => ARRAY(0x86028b0)
        empty array
   'description' => 'Lightweight representation a DNA sequence'
   'email' => 'markw@illuminae.com'
   'lsid' => 'urn:lsid:biomoby.org:objectclass:DNASequence:2001-09-21T16-00-00Z'
   'module_name' => 'MOSES::MOBY::Data::DNASequence'
   'module_parent' => 'MOSES::MOBY::Data::NucleotideSequence'
   'name' => 'DNASequence'
   'parent' => 'NucleotideSequence'
&nbsp;
</pre>

=end html

As you see this did not show all children (members). If you want it, use the -c option instead:

C<moses-local-cache -c DNASequence>

=begin html

<pre>
All children of 'DNASequence':
-> MOSES::MOBY::Def::Relationship=HASH(0x860e608)
   'datatype' => 'String'
   'memberName' => 'SequenceString'
   'module_datatype' => 'MOSES::MOBY::Data::String'
   'original_memberName' => 'SequenceString'
   'relationship' => 'HASA'
-> MOSES::MOBY::Def::Relationship=HASH(0x863a3bc)
   'datatype' => 'Integer'
   'memberName' => 'Length'
   'module_datatype' => 'MOSES::MOBY::Data::Integer'
   'original_memberName' => 'Length'
   'relationship' => 'HASA'
</pre>

=end html

Option -r shows all related (used) data types:

C<moses-local-cache -r DNASequence>

=begin html

<pre>
DNASequence
GenericSequence
Integer
NucleotideSequence
Object
String
VirtualSequence
</pre>

=end html

Options -s shows service definitions.

Both data types and services can be shown in XML, using the -x option. The XML is actually identical with the registration request for the given entity. This is just a side-effect - but perhaps it can be useful:

C<moses-local-cache -xs samples.jmoby.net getRandomImage>

=begin html

<pre>
&lt;moby:registerService xmlns:moby="http://www.biomoby.org/moby"&gt;
  &lt;moby:Category xmlns:moby="http://www.biomoby.org/moby"&gt;moby&lt;/moby:Category&gt;
  &lt;moby:serviceName xmlns:moby="http://www.biomoby.org/moby"&gt;getRandomImage&lt;/moby:serviceName&gt;
  &lt;moby:serviceType xmlns:moby="http://www.biomoby.org/moby"&gt;Retrieval&lt;/moby:serviceType&gt;
  &lt;moby:contactEmail xmlns:moby="http://www.biomoby.org/moby"&gt;martin.senger@gmail.com&lt;/moby:contactEmail&gt;
  &lt;moby:authURI xmlns:moby="http://www.biomoby.org/moby"&gt;samples.jmoby.net&lt;/moby:authURI&gt;
  &lt;moby:Description xmlns:moby="http://www.biomoby.org/moby"&gt;&lt;![CDATA[It brings back a random image.
 But a user can influence the choice of the returned image by requesting an image by sending a particular 
number (unknown numbers are ignored, and a random image is returned).
]]&gt;&lt;/moby:Description&gt;
  &lt;moby:signatureURL xmlns:moby="http://www.biomoby.org/moby"/&gt;
  &lt;moby:URL xmlns:moby="http://www.biomoby.org/moby"&gt;
      http://mobycentral.icapture.ubc.ca:8090/axis/services/getRandomImage
  &lt;/moby:URL&gt;
  &lt;moby:authoritativeService xmlns:moby="http://www.biomoby.org/moby"&gt;1&lt;/moby:authoritativeService&gt;
  &lt;moby:Input xmlns:moby="http://www.biomoby.org/moby"&gt;
    &lt;moby:Simple xmlns:moby="http://www.biomoby.org/moby" moby:articleName="imageNumber"&gt;
      &lt;moby:objectType xmlns:moby="http://www.biomoby.org/moby"&gt;Integer&lt;/moby:objectType&gt;
    &lt;/moby:Simple&gt;
  &lt;/moby:Input&gt;
  &lt;moby:secondaryArticles xmlns:moby="http://www.biomoby.org/moby"/&gt;
  &lt;moby:Output xmlns:moby="http://www.biomoby.org/moby"&gt;
    &lt;moby:Simple xmlns:moby="http://www.biomoby.org/moby" moby:articleName="image"&gt;
      &lt;moby:objectType xmlns:moby="http://www.biomoby.org/moby"&gt;text-base64&lt;/moby:objectType&gt;
    &lt;/moby:Simple&gt;
  &lt;/moby:Output&gt;
&lt;/moby:registerService&gt;
</pre>

=end html

Option -l is for getting list of all names: of data types (when used together with the -t option), or of services (with -s option).

You can also see how many entities are currently cached in your local cache. It shows what is the current registry you are using (it takes it from the configuration option I<registry>), and the numbers for all cached registries. Use option -i (as for information):

C<moses-local-cache -i>

=begin html

<pre>
Currently used registry: default
(it can be changed in moby-services.cfg) 
 &nbsp;
   contact     : Edward Kawas (edward.kawas@gmail.com)
   endpoint    : http://mobycentral.icapture.ubc.ca/cgi-bin/MOBY05/mobycentral.pl
   name        : iCAPTURE Centre, Vancouver
   namespace   : http://mobycentral.icapture.ubc.ca/MOBY/Central
   public      : yes
   text        : A curated public registry hosted at the iCAPTURE Centre, Vancouver 
&nbsp;
Statictics for all locally cached registries: 
&nbsp;
Registry         Data types   Authorities   Services
IRRI                    305            61        553
MIPS                     54             9        165
default                 307            57        451
iCAPTURE                307            57        451
</pre>

=end html

=cut

=head4 moses-testing-parser

A debugging tool. It reads a BioMoby XML data, parses them into Perl Moses data type objects, and prints them or convert them back to XML. It always takes an XML file name as a parameter:

C<moses-testing-parser parser-test-input2.xml>

C<moses-testing-parser -r parser-test-input2.xml>

And interestingly, the -b parameter. It has the form:

C<-b E<lt>  input-nameE<gt>:E<lt>known-typeE<gt>>

and it indicates a backup data type that is used when an unknown XML top-level tag is encountered. This is not usually needed at all - only when your data type definitions, the generated data types, are not up-to-date. If such situation occurs the input data with article name <input-name> will use the <known-type>.

=cut

=head4 moses-testing-service

A script for the first testing of your service. It does not give you the comfort that you can get from other BioMoby clients (Taverna, Simple Panel in the Dashboard, etc.) - but it is well suited for immediate testing.

It calls a BioMoby service in one of the two modes (actually the two modes are completely separated to the point that this script could be two scripts):

=over

=item * Calling the service before it is deployed (known) to a Web Server. This mode is useful for debugging. It sends a BioMoby XML input to a service, but without using any SOAP messages. Of course, the service can be called only locally in this mode.

=item * Calling the service for real, using the Web Server, its cgi-bin script and the SOAP envelope.

=back

In both modes, the script can send an input XML file to the service - but if the file is not given, an empty input is created and sent to the service. Which is not particularly useful, but still it can help with some preliminary testing.

When calling the service locally, you may use the following options/parameters:

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* A mandatory package name - a full package name of the called service.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* Option -l location can be used to specify a directory where is the called service stored. Default is src/Perl/services.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* Options -v and -d make also sense in this mode (but not in the other one).

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* An optional input file name. 

C<moses-testing-service -d Service::HelloBiomobyWorld>

The output of this call was already shown in this L<documentation|"Quick Start - Five Steps to the First Service">. Therefore, just look what debug messages were logged (notice the -d option used):

=begin html

<pre>
    2006/07/31 02:19:37 (561) INFO> [23856] HelloBiomobyWorldBase.pm:92 - *** REQUEST START ***
    2006/07/31 02:19:37 (562) DEBUG> [23856] HelloBiomobyWorldBase.pm:98 - Input raw data:
    &lt;?xml version="1.0" encoding="UTF-8"?&gt;
    &lt;moby:MOBY xmlns:moby="http://www.biomoby.org/moby"&gt;
      &lt;moby:mobyContent&gt;
        &lt;moby:mobyData moby:queryID="job_0"/&gt;
      &lt;/moby:mobyContent&gt;
    &lt;/moby:MOBY&gt;
    2006/07/31 02:19:37 (687) INFO> [23856] HelloBiomobyWorldBase.pm:160 - *** RESPONSE READY ***
</pre>

=end html

The full mode has the following options/parameters:

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* A mandatory service name (not a package name) of the called service.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* A mandatory endpoint -e endpoint defining where is the service located. Actually, presence of this parameter decides which mode is used.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* An optional input file name. 

=begin html

<pre>
    moses-testing-service \
           -e http://localhost/cgi-bin/MobyServer.cgi HelloBiomobyWorld
</pre>

=end html

There are also few other behavioral differences between these two modes: If an input parsing error occurs (e.g. when an input has an unknown article name), it is reported directly to the standard error in the testing mode, but in a real mode it is properly included in the response as an exception. Or (and only if the logging is set to record debug messages), in testing mode the full input raw (not yet parsed) are logged, whereas in the real mode only the first 1000 characters are logged. 

=cut

=head4 moses-universal-testing

A testing tool - but not testing your services but the Perl Moses itself. It may have more functions later, but for now, it simply generates code for all services (except one or two black-listed), and then call all of them (with an empty input).

It can be called also for a subset of services, usually for services from an authority:

C<moses-universal-testing bioinfo.icapture.ubc.ca>

=begin html

<pre>
    Services will be generated into:   /tmp/generated-services
    Services will be in package:       Testing::
    Services outputs will be saved in: /tmp/generated-outputs
    ----------------------------------
    Service: bioinfo.icapture.ubc.ca        getKeggPathwayAsGif
    Service: bioinfo.icapture.ubc.ca        getKeggPathwaysByKeggID
    Service: bioinfo.icapture.ubc.ca        ExplodeOutCrossReferences
    Service: bioinfo.icapture.ubc.ca        getUniprotIdentifierByGeneName
    Service: bioinfo.icapture.ubc.ca        convertIdentifier2KeggID
    Service: bioinfo.icapture.ubc.ca        getGoTerm
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundGetGenBankGFF
    "my" variable $id masks earlier declaration in same scope
           at /tmp/generated-services/Testing/MOBYSHoundGetGenBankGFF.pm line 58.
    Service: bioinfo.icapture.ubc.ca        getKeggIdsByKeggPathway
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundGetGenBankVirtSequence
    Service: bioinfo.icapture.ubc.ca        getJpegFromAnnotatedImage
    Service: bioinfo.icapture.ubc.ca        FASTA2HighestGenericSequenceObject
    Service: bioinfo.icapture.ubc.ca        Parse_GeneMarkHMM_HTML
    Service: bioinfo.icapture.ubc.ca        GeneMarkHMM_Arabidopsis
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundFindAccEMBL2gi
    Service: bioinfo.icapture.ubc.ca        renderGFF
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundGetGenBankFasta
    Service: bioinfo.icapture.ubc.ca        RetrieveGOFromKeywords
    Service: bioinfo.icapture.ubc.ca        getGoTermAssociations
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundGetGenBankWhateverSequence
    Service: bioinfo.icapture.ubc.ca        getTaxChildNodes
    Service: bioinfo.icapture.ubc.ca        getTaxNameFromTaxID
    Service: bioinfo.icapture.ubc.ca        getTaxParent
    Service: bioinfo.icapture.ubc.ca        MOBYSHoundGetGenBankff
    Service: bioinfo.icapture.ubc.ca        getSHoundProteinsFromTaxID
    Service: bioinfo.icapture.ubc.ca        getSHoundDNAFromTaxID
    Service: bioinfo.icapture.ubc.ca        getSHoundDNAFromOrganism
    Service: bioinfo.icapture.ubc.ca        getSHoundProteinFromOrganism
    Service: bioinfo.icapture.ubc.ca        getSHoundNeighboursFromGi
    Service: bioinfo.icapture.ubc.ca        getSHound3DNeighboursFromGi
    Service: bioinfo.icapture.ubc.ca        getSHoundGODBGetParentOf
    Service: bioinfo.icapture.ubc.ca        getSHoundGODBGetChildrenOf
    Service: bioinfo.icapture.ubc.ca        GenericSequence2FASTA
</pre>

=end html

For some services, it produces warnings - but they are just the consequence of the way how the example methods (in service implementation) were generated. They do not mean anything wrong. There may be, however, some other warnings, that are consequence of the fact that a service is registered with empty article names (which should not be, but there are still such services in some registries).

It has one interesting feature that can be useful outside of pure testing: It keeps all outputs from all services in a (temporary) directory. These outputs may have fake values but they are not empty, and they represent correct output data types. For example, a service provider I<tropgenedb.cirad.fr> created this (quite complex) output:

=begin html

<pre>
    &lt;moby:MOBY xmlns:moby="http://www.biomoby.org/moby"&gt;
      &lt;moby:mobyContent moby:authority="tropgenedb.cirad.fr"&gt;
        &lt;moby:serviceNotes&gt;
          &lt;moby:Notes&gt;Response created at Sun Jul 30 23:23:08 2006 (GMT),
    by the service 'getTropgeneMapInformation'.&lt;/moby:Notes&gt;
        &lt;/moby:serviceNotes&gt;
        &lt;moby:mobyData moby:queryID="job_0"&gt;
          &lt;moby:Collection moby:articleName="map"&gt;
            &lt;moby:Simple&gt;
              &lt;moby:GCP_Map moby:id="" moby:namespace=""&gt;
                &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="length"&gt;0.42&lt;/moby:Float&gt;
                &lt;moby:GCP_Locus moby:id="" moby:namespace="" moby:articleName="locus"&gt;
                  &lt;moby:GCP_MapPosition moby:id="" moby:namespace="" moby:articleName="start_stop"&gt;
                    &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="position"&gt;0.42&lt;/moby:Float&gt;
                  &lt;/moby:GCP_MapPosition&gt;
                  &lt;moby:GCP_Allele moby:id="" moby:namespace="" moby:articleName="allele"/&gt;
                &lt;/moby:GCP_Locus&gt;
              &lt;/moby:GCP_Map&gt;
            &lt;/moby:Simple&gt;
            &lt;moby:Simple&gt;
              &lt;moby:GCP_Map moby:id="" moby:namespace=""&gt;
                &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="length"&gt;0.42&lt;/moby:Float&gt;
                &lt;moby:GCP_Locus moby:id="" moby:namespace="" moby:articleName="locus"&gt;
                  &lt;moby:GCP_MapPosition moby:id="" moby:namespace="" moby:articleName="start_stop"&gt;
                    &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="position"&gt;0.42&lt;/moby:Float&gt;
                  &lt;/moby:GCP_MapPosition&gt;
                  &lt;moby:GCP_Allele moby:id="" moby:namespace="" moby:articleName="allele"/&gt;
                &lt;/moby:GCP_Locus&gt;
              &lt;/moby:GCP_Map&gt;
            &lt;/moby:Simple&gt;
            &lt;moby:Simple&gt;
              &lt;moby:GCP_Map moby:id="" moby:namespace=""&gt;
                &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="length"&gt;0.42&lt;/moby:Float&gt;
                &lt;moby:GCP_Locus moby:id="" moby:namespace="" moby:articleName="locus"&gt;
                  &lt;moby:GCP_MapPosition moby:id="" moby:namespace="" moby:articleName="start_stop"&gt;
                    &lt;moby:Float moby:id="" moby:namespace="" moby:articleName="position"&gt;0.42&lt;/moby:Float&gt;
                  &lt;/moby:GCP_MapPosition&gt;
                  &lt;moby:GCP_Allele moby:id="" moby:namespace="" moby:articleName="allele"/&gt;
                &lt;/moby:GCP_Locus&gt;
              &lt;/moby:GCP_Map&gt;
            &lt;/moby:Simple&gt;
          &lt;/moby:Collection&gt;
        &lt;/moby:mobyData&gt;
      &lt;/moby:mobyContent&gt;
    &lt;/moby:MOBY&gt;
</pre>

=end html

=cut

=cut

=head3 Configuration

Configuration means to avoid hard-coding local-specific things (such as file paths) into the code itself but hard-coding them in a separate file, a file that is not shared with other (CVS) users.

Perl Moses stores configuration in a file named I<moby-services.cfg>. The file name is hard-coded (and cannot be changed without changing the I<MOSES::MOBY::Config> module), but its location can be set using an environment variable I<BIOMOBY_CFG_DIR>. Perl MoSeS looks for its configuration place in the following places, in this order:

   1. In the "current" directory (which is not that well defined when used from a Web Server).
   2. In the directory given by BIOMOBY_CFG_DIR environment variable.
   3. In the directory <your-user-dir>/Perl-MoSeS/.
   4. In one of the @INC directories (directories where Perl looks for its modules). 

Therefore, the best place is to keep the configuration file together where the installation script puts it anyway.

The Perl Moses internally uses C<Config::Simple> CPAN module, but wraps it into its own MOSES::MOBY::Config. This allows expansion later, or even changing the underlying configuration system. The Config::Simple is simple (thus the name, and thus we selected it) but has few drawbacks that may be worth to work on later.

The file format is as defined by the C<Config::Simple>. It can be actually of several formats. The most common is the one distributed in the moby-services.cfg.template. This is an example of a configuration file:

=begin html

<pre>
cachedir = /home/senger/Perl-MoSeS/myCache
registry = default
&nbsp;
[generators]
outdir = /home/senger/Perl-MoSeS/generated
impl.outdir = /home/senger/Perl-MoSeS/services
impl.package.prefix = Service
impl.services.table = SERVICES_TABLE
impl.async.services.table = ASYNC_SERVICES_TABLE
&nbsp;
#ignore.existing.types = true
&nbsp;
[log]
config = /home/senger/Perl-MoSeS/log4perl.properties
#file = /home/senger/Perl-MoSeS/services.log
#level = info
#pattern = "%d (%r) %p> [%x] %F{1}:%L - %m%n"
&nbsp;
[xml]
#parser = XML::LibXML::SAX
#parser = XML::LibXML::SAX::Parser
#parser = XML::SAX::PurePerl
&nbsp;
[Mabuhay]
resource.file = /home/senger/Perl-MoSeS/sample-resources/mabuhay.file
</pre>

=end html

The names of the configuration parameters are created by concatenating the "section" name (the one in the square brackets) and the name itself. For example, the XML parser is specified by the parameter I<xml.parser>. Parameters that are outside of any section (e.g. cachedir) has just their name, or they can be referred to as from the I<default> section. For example, these two names are equivalent: I<default.cachedir> and I<cachedir>.

Blank lines are ignored, comments lines start with a hash (#), and boolean properties B<must> have a value ('true' or 'false').

Obviously, important is to know what can be configured, and how. This document on various places already mentioned several configuration options. Here is their list (for more explanations about their purpose you may visit an appropriate section of this document):  

B<cachedir> - Directory with the local cache. No default. 

B<registry> - A synonym of a registry that will be used (when reading from a local cache - it can have multiple registries), or its endpoint. Default is 'default'.

B<generators.outdir> - Directory where to generate data types and service bases. The default value for data types is 'generated', for service bases is 'services'. 

B<generators.impl.outdir> - Directory where to generate service implementations. Default is 'services'. 

B<generators.impl.package.prefix> - A beginning of the package name of the generated service implementations. Default is 'Service'. For example, a service Mabuhay will be represented by a Perl module I<Service::Mabuhay>. 

B<generators.impl.services.table> - A name (without any path) of a file with a services dispatch table. Default is 'SERVICES_TABLE'.

B<generators.impl.async.services.table> - A name (without any path) of a file with an async services dispatch table. Default is 'ASYNC_SERVICES_TABLE'. 

B<generators.ignore.existing.types> - A boolean property. If set to true ('true', 1, ' '+', 'yes', or 'ano') the data types generator will not check if a wanted data type module already exists on a disk but always generates into memory a new one. Default value is 'false' (meaning that the generator tries to use whatever already exists).

B<log.config> - A full file name with the Log4perl properties. No default. If this parameter is given but the file is not existing or not readable, Perl Moses complains on STDERR (which may end up in the Web Server I<error.log> file). 

B<log.file> - A full file name of a log file (where the log messages will be written to). No default. If the value is 'stderr' (case-insensitive) the messages will go to the STDERR. It is not clear what happens when it is used together with the above I<log.config>. 

B<log.level> - A log level. Default is ERROR. 

B<log.pattern> - A format of the log messages. Default is I<'%d (%r) %pE<gt> [%x] %F{1}:%L - %m%n'>.

B<xml.parser> - A preferred XML SAX parser for reading input data. Perl finds available XML parser itself, but sometimes you prefer a different one. Of course, you need to install it first. Note that this parser is used only for reading BioMoby requests (which may be long so an ability to choose a good parser is meaningful). For other XML stuff (creating response and reading from tghe local cache) Perl Moses always uses I<XML::LibXML> module. 

The parameters just described are used by PerlMoses modules - but the configuration system is here also for your own services. You can invent any not-yet-taken name, and add your own parameter. In order not to clash with the future Perl Moses parameters, it is recommended to prefix your configuration properties with the service name. For example, the Mabuhay service needs to read a file with "hellos" in many languages, so it defines:

=begin html

<pre>
[Mabuhay]
resource.file = /home/senger/Perl-MoSeS/samples-resources/mabuhay.file
</pre>

=end html

=head4 How to use configuration in your service implementation?

All configuration parameters are imported to a Perl namespace MOBYCFG. The imported names are changed to all-uppercase and dots are replaces by underscores. You can see this change if you run the config-status.cfg:

=begin html

<pre>
$MOBYCFG::CACHEDIR
$MOBYCFG::DEFAULT_CACHEDIR
$MOBYCFG::DEFAULT_REGISTRY
$MOBYCFG::GENERATORS_IMPL_OUTDIR
$MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX
$MOBYCFG::GENERATORS_IMPL_SERVICES_TABLE
$MOBYCFG::GENERATORS_OUTDIR
$MOBYCFG::LOG_CONFIG
$MOBYCFG::LOG_FILE
$MOBYCFG::LOG_LEVEL
$MOBYCFG::LOG_PATTERN
$MOBYCFG::MABUHAY_RESOURCE_FILE
$MOBYCFG::REGISTRY
$MOBYCFG::XML_PARSER
</pre>

=end html

In your program, you can use the imported names. For example, here is how the Mabuhay service opens its resource file:

=begin html

<pre>
open HELLO, $MOBYCFG::MABUHAY_RESOURCE_FILE
   or $self->throw ('Mabuhay resource file not found.');
</pre>

=end html

You can also change or add parameters during the run-time. For example, the script universal-testing.pl needs to overwrite existing parameters because it wants to create everything in a separate space, in a temporary directory, and within the 'Testing' package. Because the generators read from the configuration files, it is necessary to change it there:

=begin html

<pre>
my $outdir = File::Spec->catfile ($tmpdir, 'generated-services');
MOSES::MOBY::Config->param ('generators.impl.outdir', $outdir);
MOSES::MOBY::Config->param ('generators.impl.package.prefix', 'Testing');
unshift (@INC, $MOBYCFG::GENERATORS_IMPL_OUTDIR);
my $generator = new MOSES::MOBY::Generators::GenServices;
</pre>

=end html

More about how to communicate pragmatically with the configuration can be (hopefully) find in the L<Perl Modules Documentation|"Perl Modules Documentation">.

=cut

=cut

=head3 Logging

The logging system is based on a splendid Perl module Log::Log4perl, a Perl port of the widely popular log4j logging package. The Log4perl is well documented (here is its POD documentation L<http://search.cpan.org/~mschilli/Log-Log4perl-1.06/lib/Log/Log4perl.pm>).

How does it work in Perl Moses?

The logging is available from the moment when Perl Moses knows about the MOSES::MOBY::Base module. All generated service implementations inherit from this class, so all of them have immediate access to the logging system. By default, the MOSES::MOBY::Base creates a logger in a variable $LOG. Which means that in your service implementation you can log events in five different log levels:

=begin html

<pre>
$LOG->debug ("Deep in my mind, I have an idea...");
$LOG->info  ("What a nice day by a keyboard.");
$LOG->warn  ("However, the level of sugar is decreasing!");
$LOG->error ("Missing Dunkin' Donuts");
$LOG->fatal ('...and we are out of coffee!');
</pre>

=end html

The logger name is "services". (The name is used in the logging configuration file - see below).

You can create your own logger. Which may be good if you wish to have, for example, a different logging level for a particular service, or for a part of it (an example of such situation is in I<MOSES::MOBY::Parser.pm> where the parser creates its own I<$PLOG> logger). Here is what you need to do:

=begin html

<pre>
use Log::Log4perl qw(get_logger :levels);
my $mylog = get_logger ('my_log_name');
</pre>

=end html

Then use the name "my_log_name" in the configuration to set its own properties. Which brings also us to the logging configuration.

The logging configuration can be done in three ways:

=over

=item * Do nothing.

=item * Edit log4perl.properties file.

=item * Edit logging configuration options in moby-services.cfg. 

=back

If Perl Moses cannot find a I<log4perl.properties> file, and if there are no logging options in I<moby-services.cfg>, it assumes some defaults (check them in I<MOSES::MOBY::Base>, in its BEGIN section, if you need-to-know).

The better way is to use I<log4perl.properties> file. The file name can be actually different - it is specified by an option log.config in the moby-services.cfg configuration file. This is what PerlMoses installation creates there (of course, using your own path):

=begin html

<pre>
[log]
config = /home/senger/Perl-MoSeS/log4perl.properties
</pre>

=end html

The I<log4perl.properties> is created (in the installation time) from the I<log4perl.properties.template>, by putting there your specific paths to log files. The log4perl (or log4j) documentation explains all details - here is just a brief example what is in the file and what it means:

=begin html

<pre>
log4perl.logger.services = INFO, Screen, Log
&nbsp; 
log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.Threshold = FATAL
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d (%r) %p> [%x] %F{1}:%L - %m%n
&nbsp;
log4perl.appender.Log = Log::Log4perl::Appender::File
log4perl.appender.Log.filename = /home/senger/moby-live/Java/src/scripts/../Perl/services.log
log4perl.appender.Log.mode = append
log4perl.appender.Log.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Log.layout.ConversionPattern = %d (%r) %p> [%x] %F{1}:%L - %m%n
</pre>

=end html


It says: Log only INFO (and above) levels (so no DEBUG messages are logged) on the screen (meaning on the STDERR) and to a file. But because of the "screen appender" has defined a Threshold FATAL - the screen (STDERR) will get only FATAL messages. There is no threshold in the "file appender" so the file gets all the INFO, WARN, ERROR and FATAL messages. In both cases the format of the messages is defined by the "ConversionPattern".

Note that printing to STDERR means that the message will go to the error.log file of your Web Server.

To change the log level to DEBUG, replace INFO by DEBUG in the first line.

The message format (unless you change the Perl Moses default way) means:

=begin html

<pre>
%d                  (%r ) %p   > [%x   ] %F{1}               :%L - %m      %n
2006/07/31 11:38:07 (504) FATAL> [26849] HelloBiomobyWorld.pm:63 - Go away!
1                   2     3      4       5                    6    7       8
</pre>

=end html

Where:

=begin html

<ul>
  <li> <font size="-1"><b>1</b></font> (%d) - Current date
in yyyy/MM/dd hh:mm:ss format
  </li><li> <font size="-1"><b>2</b></font> (%r) - Number of
milliseconds elapsed from program start to logging
   event
  </li><li> <font size="-1"><b>3</b></font> (%p) - Level
(priority) of the logging event
  </li><li> <font size="-1"><b>4</b></font> (%x) - Process ID
(kind of a <em>user session</em>)
  </li><li> <font size="-1"><b>5</b></font> (%F) - File where
the logging event occurred (unfortunately, it is not always that
useful - when it happens in an <em>eval</em> block - which often
does).
  </li><li> <font size="-1"><b>6</b></font> (%L) - Line number
within the file where the log statement was issued
  </li><li> <font size="-1"><b>7</b></font> (%m) - The message
to be logged
  </li><li> <font size="-1"><b>8</b></font> (%n) - Newline

</li></ul>

=end html

The last option how to specify logging properties is to set few configuration options in the moby-service.cfg file. It was already mentioned that there is an option log.config that points to a full log property file. If this option exists, no other logging configuration options are considered. But if you comment it out, you can set the basics in the following options:

=begin html

<pre>
[log]
#config = /home/senger/Perl-MoSeS/log4perl.properties
file = /home/senger/Perl-MoSeS/services.log
level = info
pattern = "%d (%r) %p> [%x] %F{1}:%L - %m%n"
</pre>

=end html

Where log.file defines a log file, I<log.level> specifies what events will be logged (the one mentioned here and above), and the I<log.pattern> creates the format of the log events.

This is meant for a fast change in the logging system (perhaps during the testing phase).

There are definitely more features in the Log4perl system to be explored:

For example, in the mod_perl mode it would be interesting to use the "Automatic reloading of changed configuration files". In this mode, C<Log::Log4perl> will examine the configuration file every defined number of seconds for changes via the file's last modification time-stamp. If the file has been updated, it will be reloaded and replace the current logging configuration.

Or, one can explore additional log appenders (you will need to install additional Perl modules for that) allowing, for example, to rotate automatically log files when they reach a given size. See the Log4perl documentation for details. 

=cut

=head3 Deploying

Deploying means to make your BioMoby service visible via your Web Server.

By contrast to the deployment of the Java-based services, Perl services are invoked by a cgi-bin script directly from a Web Server - there is no other container, such as Tomcat in the Java world. Which makes the life slightly easier. Well, only slightly, because soon you will start to think about using mod_perl module, and it may make things complicated.
To be done
The Perl Moses was not tested in the mod_perl environment, at all. But it should be. I wonder if anybody can explore this a bit.
In order to deploy a Perl Moses BioMoby service, you need:

=begin html

<ul>

  <li> To run a Web Server, such as Apache. It has a directory where
its cgi-bin scripts are located (e.g. <tt>/usr/lib/cgi-bin</tt>). You
may configure your Web Server to allow to have other cgi-bin script
elsewhere, or to link them by symbolic links. An example how to create
a symbolic link is in <a href="#4._Make_your_service_available_from_your_Web_Server_(this_is_called_deploying).">5 steps to your first service</a>.

  </li><li> Then you need the cgi-bin script itself. Its name does not
matter (except that it will become a part of your services
endpoint). The Perl Moses installation script creates two scripts named
<tt>MobyServer.cgi</tt> and <tt>AsyncMobyServer.cgi</tt> in 
<tt>/Perl-MoSeS</tt> directory. Notice that it contains some hard-coded
paths - that comes from the installation time. Feel free to change them
manually, or remove the file and run <tt>install.pl</tt> again to 
re-create it. Here is the whole script (for MobyServer.cgi):
</li>
</ul>
<pre>
      use strict;
&nbsp;
      use SOAP::Transport::HTTP;
&nbsp;
      # --- established in the install.pl time
      use lib '/home/senger/Perl-MoSeS';
      use lib '/home/senger/Perl-MoSeS/generated';
      use lib '/home/senger/Perl-MoSeS/services';
&nbsp;
      # --- list of all services served by this script
      use vars qw ( $DISPATCH_TABLE );
      require "SERVICES_TABLE";
&nbsp;
      # --- accept request and call wanted service
      my $x = new SOAP::Transport::HTTP::CGI;
      $x->dispatch_with ($DISPATCH_TABLE);
      $x->handle;
</pre>

=end html

You see above that the script "requires" SERVICES_TABLE file (its name was taken during installation form the configuration). This is a dispatch table with a list of all BioMoby services served by this script. Yes, one cgi-bin script can serve more services - meaning that more services are registered with the same endpoint (and they are distinguished by their service names - which is, surprisingly, not part of the endpoint; but that's the way how Perl does it). 

These three things (a Web Server knowing about your cgi-bin scripts, a cgi-bin script knowing about Perl Moses code, and a dispatch table knowing what services to serve) are all you need to have your service deployed. 

=cut

=head2 Perl Modules Documentation

After reading so far you may still wonder: Okay, but what should I do in my implementation to gain all the benefits generated for me by Perl Moses? This section will try to answer it - but notice that some particular activities were already explained in corresponding sections about L<logging|"Logging"> and L<configuration|"Configuration">.

=head4 How to write a service implementation

First of all, you need to have a service implementation, at least its starting (empty) phase. Generate it, using the C<moses=generated-services> script. Depending on how you generate it (without any option, or using an -S option) generator enables one of the following options (not that it matters to your business logic code):

=begin html

<pre>
#-----------------------------------------------------------------
# This is a mandatory section - but you can still choose one of
# the two options (keep one and commented out the other):
#-----------------------------------------------------------------
use MOSES::MOBY::Base;
# --- (1) this option loads dynamically everything
BEGIN {
    use MOSES::MOBY::Generators::GenServices;
    new MOSES::MOBY::Generators::GenServices->load
        (authority     => 'samples.jmoby.net',
         service_names => ['Mabuhay']);
}
&nbsp;
# --- (2) this option uses pre-generated module
#  You can generate the module by calling a script:
#    moses-generate-services -b samples.jmoby.net Mabuhay
#  then comment out the whole option above, and uncomment
#  the following line (and make sure that Perl can find it):
#use net::jmoby::samples::MabuhayBase;
</pre>

=end html


Secondly, you need to understand when and how your implementation code is called:

Every BioMoby request can have multiple queries (in the Moses world, called jobs). Your service implementation has to implement method process_it that is called for every individual job contained within every incoming request. The MOSES/MOBY/Service/ServiceBase has details about this method (what parameters it gets, how to deal with exceptions, etc.).

In the beginning of the generated process_it method is the code that tells you what methods are available for reading inputs, and at the end of the same method is the code showing how to fill the response. Feel free to remove the code, extend it, fill it, turn it upside-down, whatever. This is, after all, your implementation. And Perl Moses generator is clever enough not to overwrite the code once is generated. (It is not clever enough, however, to notice that it could be overwritten because you have not touched it yet.)

Perhaps the best way how to close this section is to show a full implementation of (so often mentioned) service Mabuhay:

=begin html

<pre>
sub process_it {
    my ($self, $request, $response, $context) = @_;
&nbsp;
    # read (some) input data
    # (use eval to protect against missing data)
    my $language = eval { $request->language };
    my $regex = eval { $language->regex->value };
    my $ignore_cases = eval { $language->case_insensitive->value };
&nbsp;
    # set an exception if data are not complete
    unless ($language and $regex) {
	$response->record_error ( { code => INPUTS_INVALID,
				    msg  => 'Input regular expression is missing.' } );
	return;
    }
&nbsp;
    # creating an answer (this is the "business logic" of this service)
    my @result_hellos = ();
    my @result_langs = ();
    open HELLO, $MOBYCFG::MABUHAY_RESOURCE_FILE
        or $self->throw ('Mabuhay resource file not found.');
    while (<HELLO>) {
	chomp;
	my ($lang, $hello) = split (/\t+/, $_, 2);
	if ( $ignore_cases ? 
	     $lang =~ /$regex/i :
	     $lang =~ /$regex/ ) {
	    push (@result_hellos, $hello);
	    push (@result_langs, $lang);
	}
    }
    close HELLO;
&nbsp;
    foreach my $idx (0 .. $#result_hellos) {
	$response->add_hello (new MOSES::MOBY::Data::simple_key_value_pair
			      ( key   => $self->as_uni_string ($result_langs[$idx]),
				value => $self->as_uni_string ($result_hellos[$idx])
				));
    }
}
</pre>

=end html

When you go through the code above you notice how to do basic things that almost every service has to do. Which are:

Reading input data:

The possible methods were already pre-generated for you so you know what methods to use. But you should always check if the data are really there (the clients can send you rubbish, of course).

What was not pre-generated are the methods accessing ID and NAMESPACE. Their names are, not surprisingly, id and namespace. For example, the Mabuhay input is named language (as seen in the code above), so you can call:

=begin html

<pre>
    $language->id;
    $language->namespace;
</pre>

=end html

The question is what to do if input (or anything else) is not complete or valid. This brings us to...

Reporting exceptions:

=begin html

<pre>
    One option is to throw an exception:
&nbsp;
    open HELLO, $MOBYCFG::MABUHAY_RESOURCE_FILE
         or $self->throw ('Mabuhay resource file not found.');
</pre>

=end html

This immediately stops the processing of the input request (ignoring all remaining jobs if they are some still there), the text of the error message is put into the response as an exception with the code 600 I<("INTERNAL_PROCESSING_ERROR")>, the same message is logged as an error, and the response is sent back to the client.

Note, however, that the response may already contain some outputs from the previously processed jobs. If you do not like it, you can remove it (find them in the $context parameter).

Another, less drastic, option is to record an exception (and, usually, return):

=begin html

<pre>
    $response->record_error ( { code => INPUTS_INVALID,
    			    msg  => 'Input regular expression is missing.' } );
</pre>

=end html


This creates an exception in the response - you choose what code to use -, and it does not prevent processing of the remaining (if any) jobs.

In addition to using an eval{} block to handle exceptions (as shown above), you can also use a try-catch-finally block structure if Error.pm has been installed in your system. See documentation of MOSES::MOBY::Base for details and examples.

Creating output data:

=begin html

&nbsp;&nbsp;&nbsp;&nbsp;Again, methods for creating response were pre-generated, so you have hints how to use them (they slightly differ for simple and collection outputs; but hopefully in a logical way).
<p/>
&nbsp;&nbsp;&nbsp;&nbsp;Again here you can also set the ID and NAMESPACE. For example, the code above can be extended so the MOSES::MOBY::Data::simple_key_value_pair data type will have also an ID and NAMESPACE:
<p/>
<pre>
    $response->add_hello (new MOSES::MOBY::Data::simple_key_value_pair
                          ( key   => $self->as_uni_string ($result_langs[$idx]),
    			            value => $self->as_uni_string ($result_hellos[$idx]),
    			            id    => 'this is an ID',
                            namespace => 'this is a NAMESPACE'
    	              ));
</pre>

=end html

Creating and adding cross-references:

=begin html

&nbsp;&nbsp;&nbsp;&nbsp;Each output object can have attached zero or more cross-references. See documentation of MOSES::MOBY::Data::Xref. For example, in the HelloBioMobyWorld service one can add two cross-references:<p/>

<pre>
    # create a simple cross-reference
     my $simple_xref = new MOSES::MOBY::Data::Xref
        ( id        => 'At263644',
          namespace => 'TIGR'
        );
&nbsp;
     # create an advanced cross-reference
     my $advanced_xref = new MOSES::MOBY::Data::Xref
        ( id           => 'X112345',
          namespace    => 'EMBL',
          service      => 'getEMBLRecord',
          authority    => 'www.illuminae.com',
          evidenceCode => 'IEA',
          xrefType     => 'transform'
        );
&nbsp;
    # add them to the output object (which has an article name 'greeting')
    $response->greeting->add_xrefs ($simple_xref);
    $response->greeting->add_xrefs ($advanced_xref);
</pre>
<p/>
Creating a service note:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Just use the method serviceNotes on the $context parameter:
<pre>
    $context->serviceNotes ("This is my note...");
</pre>

=end html

=cut

=cut

=head2 FAQ

=head3 How can I tell apache to execute MobyServer.cgi on Windows without moving the file to cgi-bin?

=begin html

<p>This can be done using the following steps <em><strong>(Please make sure to back up the file first!)</strong></em>:</p>
<ol>
  <li> Open the file httpd.conf and search for following text:<br />
  <em>ScriptAlias /cgi-bin/</em></li>
  <li>Underneath this text, enter something like the following (replace Eddie with your username):<br /> 
  <em>ScriptAlias /services/ &quot;C:/Documents and Settings/Eddie/Perl-MoSeS/&quot;</em></li>
  <li> Just below this, after the <em>&lt;/IfModule&gt;</em> line, add the following text (replace Eddie with your username and the directory with your directory):
    <pre>
      &lt;Directory &quot;C:/Documents and Settings/Eddie/Perl-MoSeS&quot;&gt;
         AllowOverride None
         Options +ExecCGI
         Order allow,deny
         Allow from all
      &lt;/Directory&gt;
    </pre>
  </li>
  <li>Save the file and restart apache.  </li>
  <li>The very last thing to do is to open up the file <em><strong>MobyServer.cgi</strong></em> and change the header <br />
  &nbsp;&nbsp;<strong><em>&nbsp;#!/usr/bin/perl -w </em></strong><br />
  to <br />
  &nbsp;&nbsp;&nbsp;<strong><em>#!C:/path/to/perl/bin/perl.exe -w</em></strong></li>
  <li>Now anytime you read about http://localhost/cgi-bin/MobyServer.cgi, replace it with http://localhost/services/MobyServer.cgi </li>
</ol>

=end html

=cut

=head3 How Can Apache Follow Symbolic links?

Add the following to the end of your httpd.conf file:

=begin html

<pre>
    &lt;Directory &quot;/path/to/cgi-bin&quot; &gt;
	    Options +FollowSymLinks
	&lt;/Directory&gt;
</pre>

=end html

Make sure to change I</path/to/cgi-bin> to be the real path to your cgi-bin directory!

=cut

=head3 Cannot Create Symbolic links

If you cannot create symbolic links, another tested alternative would be to copy your file B<MobyServer.cgi> to the I<cgi-bin> directory of your web server.

It is B<highly recommended> that you change the name of the file if you anticipate other users B<copying their files> to the cgi-bin directory as well!

Once the file has been copied, change the ownership of the file to the web servers' user/group. Also, make sure that the path (and its parents) to all of the directories in the 'use lib ...' are readable by your web server. 

That's all there is to it! Now when you test your services, remember that your file may no longer be called MobyServer.cgi, but something else that you named it!

=cut

=head3 When I run the install script, IO::Prompt complains ...

This could mean that the package C<IO::Prompt> is not installed properly.

What version do you have?

C<perl -MIO::Prompt -e'print "$IO::Prompt::VERSION\n";'>

We have tested version 0.99.2 on both *nix machines and windows. Please make sure that you have  that version. If you do not, please remove the one that you have (the cpan module B<CPAN Plus> is very useful here) and install version 0.99.2! Version 0.99.4 doesnt seem to work too well and produces numerous warnings in our module. Other versions have yet to be tested.

=cut

=cut

=head2 Missing Features

There will be always bugs waiting to be fixed. Please let us know about them.

And there are features (and known) bugs that should or could be implemented (or fixed). Here are those I am aware of (B = bug, N = not yet implemented, F = potential future feature):

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* (B) Article names containing dashes and spaces are still "escaped" in the XML output. They should be kept as registered.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* (N) Documentation of the Perl Modules is unfinished, and links to it are not yet included in this document. This is an important part of the documentation because it expands hints how to write your own service implementation.

E<nbsp>E<nbsp>E<nbsp>E<nbsp>* (N) The generated service implementation could have a better Perl documentation, listing all available methods for inputs and outputs (the methods are already shown in the code, but having them also in the POD would help).

I will try to keep up-to-date the list of the recent changes in the Changes file included with the distribution. 

=cut

=head2 Acknowledgement

The main developers (whom please direct your suggestions and reports to) are Martin Senger and Edward Kawas.

However, there would be no MoSeS without BioMoby - the BioMoby project was established through an award from Genome Prairie and Genome Alberta, in part through Genome Canada, a not-for-profit corporation leading Canada's national strategy on genomics.  We acknowledge the support of the EPSRC through the myGrid (GR/R67743/01, EP/C536444/1, EP/D044324/1, GR/T17457/01) e-Science projects, the INB (Spanish National Institute for Bioinformatics), funded by FundaciE<oacute>n Genoma EspaE<ntilde>a, and the Generation Challenge Programme (GCP; http://www.generationcp.org) of the CGIAR.

Martin Senger was developing the project in the frame of the Generation Challenge Programme, getting no-nonsense support from Richard Bruskiewich from the International Rice Research Institute in Philippines, and high motivation to work with Perl from Mathieu Rouard from INIBAP. 

=cut

=head1 EXPORT

None by default.


=head1 SEE ALSO

=head2 Tutorials on building services

For some tutorials on using Perl MoSeS:

=begin html

	<a href='http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Docs/MOBY-S_API/Perl/construct_moses_soap_service.html' target='_blank'>Tutorial for creating SOAP based Biomoby Services</a><br/>
	<a href='http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Docs/MOBY-S_API/Perl/construct_moses_cgi_service.html' target='_blank'>Tutorial for creating CGI based Biomoby Services</a><br/>
	<a href='http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Docs/MOBY-S_API/Perl/construct_moses_cgi_async_service.html' target='_blank'>Tutorial for creating Asynchronous CGI based Biomoby Services</a><br/>
	<a href='http://biomoby.open-bio.org/CVS_CONTENT/moby-live/Docs/MOBY-S_API/Perl/construct_moses_async_service.html' target='_blank'>Tutorial for creating Asynchronous SOAP based Biomoby Services</a><br/>

=end html

=cut

If you have questions or comments, please feel free to message us on the following mailing lists:

=over

=item MOBY discussion list L<http://www.biomoby.org/mailman/listinfo/moby-l>

=item MOBY Developers List L<http://www.biomoby.org/mailman/listinfo/moby-dev>

=item MOBY bugs discussion list L<http://www.biomoby.org/mailman/listinfo/moby-bugs>

=back

Please visit the BioMOBY website at L<http://biomoby.org>!

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

=head1 COPYRIGHT

Copyright (c) 2007 Martin Senger, Edward Kawas.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=cut

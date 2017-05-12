use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.34 2005/11/05 23:19:32 lem Exp $

my $checker = 0;

if ($] <= 5.006)
{
    warn <<EOT;

Your version of Perl is not supported by Params::Validate. This
warning is being produce because sometimes the code will work anyway,
though ocassional core dumps and similar problems are not unheard
of. I thought you might want to know.

Please consider upgrading your Perl to 5.6.1 or better, which seems to
be the recomendation that comes with Params::Validate. See its README
file for more information.

EOT
    ;
}

eval { require Template::Plugin; };
if ($@)
{
    print <<EOF;

This distribution includes plugins for the Template::Toolkit that
require Template::Plugin, which is not available on this system. The
plugins cannot be tested without prerequisites, but will be installed
anyway. If you later want to use them, simply install
Template::Toolkit.

EOF
    ;
}

eval { require Test::Pod;
       $checker = 1; };

unless ($checker)
{
    print <<EOF;

Looks like this host does not have Test::Pod installed. Without this module,
the Pod documentation cannot be tested. This is not a big deal really, but
you might want to install Test::Mod by issuing the following command:

    perl -MCPAN -e "install('Test::Pod')"

at a nearby shell. This is nice because it allows easy tests of your own
documentation.

EOF
    ;
}

$checker = 0;

eval { require IO::Scalar;
       $checker = 1; };

unless ($checker)
{
    print <<EOF;

Looks like this host does not have IO::Scalar installed. This module
is used in some tests, but is not required for the production
code. This is not a big deal really, but you might want to install
Test::Mod by issuing the following command:

    perl -MCPAN -e "install('IO::Scalar')"

at a nearby shell. This is nice because it allows easy tests of your own
documentation.

EOF
    ;
}

$checker = 0;
eval { require URI::URL;
       require Mail::Mailer;
       require HTML::Entities;
       require HTML::LinkExtor;
       require LWP::RobotUA;
       $checker = 1; };

unless ($checker)
{
    print <<EOF;

Looks like this host does not have a number of modules that are
required by utilities in the bin/ directory of this
distribution. Generally, it would be a good idea to install the
modules by following the recipe given below:

    perl -MCPAN -e shell
    cpan> install URI::URL
    cpan> install LWP::RobotUA
    cpan> install Mail::Mailer
    cpan> install HTML::Entities
    cpan> install HTML::LinkExtor
    cpan> quit

at a nearby shell. The supplied scripts are intended to be useful to
many audiences. If you have reasons not to install those modules, take
a look at the scripts and see if they apply to your environment.

EOF
    ;
}

WriteMakefile
    (
     'NAME'		=> 'Mail::Abuse',
     'VERSION_FROM'	=> 'lib/Mail/Abuse.pm', # finds $VERSION
     'EXE_FILES'	=> [ 'bin/abuso', 
			     'bin/acat', 
			     'bin/scan', 
			     'bin/popfetch',
			     'bin/requester',
			     'bin/maps-scan',
			     'bin/spews-scan',
			     'bin/maps-gather',
			     'bin/google-gather',
			     ],
     'INSTALLSCRIPT'	=> '/usr/local/bin',
     'PREREQ_PM'	=> 
     {
	 'DBI'			=> 1.48,

	 # DBI 1.48 is needed for some of the tests. However, the actual
	 # modules can run under older DBIs. 1.46 is known to work
	 # flawlessly.

	 'IO::File'		=> 0,
	 'PerlIO::gzip'		=> 0,
	 'Storable'		=> 0,
	 'DBD::CSV'		=> 0,
	 'Net::POP3'		=> 2.23, # ->getfh() is required
	 'Test::More'		=> 0,
	 'File::Path'		=> 0,
	 'File::Spec'		=> 0,
	 'File::Find'		=> 0,
	 'Date::Parse'		=> 0,
	 'NetAddr::IP'		=> 3.00,
	 'Date::Manip'		=> 0,
	 'Date::Parse'		=> 0,
	 'Digest::MD5'		=> 0,
	 'MIME::Entity'		=> 0,
	 'MIME::Parser'		=> 0,
	 'HTML::Parser'		=> 0,
	 'Mail::Mailer'		=> 0,
	 'Text::CSV_XS'		=> 0,
#	 'Config::Auto'		=> 0.03,
	 'Params::Validate'	=> 0,
	 'Tie::NetAddr::IP'	=> 1.51,
	 'WWW::Mechanize'	=> 0,
#	 'WWW::Google::Groups'	=> 0,
     }, # e.g., Module::Name => 1.1
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM	=> 'lib/Mail/Abuse.pm',
       AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),
     );

package MY;

sub postamble
{
    '
install ::
	@echo ==============================================================
	@echo "                           NOTICE"
	@echo ==============================================================
	@echo 
	@echo This package contains various scripts that have been installed
	@echo in /usr/local/bin. Please check the bin directory in this
	@echo distribution for specific information.
	@echo 
	@echo Each script includes its own documentation in POD. Use
	@echo 
	@echo "  perldoc bin/acat"
	@echo "  perldoc bin/scan"
	@echo "  perldoc bin/abuso"
	@echo "  perldoc bin/popfetch"
	@echo "  perldoc bin/requester"
	@echo "  perldoc bin/maps-scan"
	@echo "  perldoc bin/spews-scan"
	@echo "  perldoc bin/maps-gather"
	@echo "  perldoc bin/google-gather"
	@echo 
	@echo to see it. Please read the documentation of each module 
	@echo thoroughly before reporting bugs or asking for help.
	@echo
	@echo Under ./etc in this distribution, you should see some config
	@echo files. Please review and edit them prior to using this
	@echo software.
';
}

use 5.008000;
use ExtUtils::MakeMaker;

use Getopt::Long ();
use strict;

my $apache_include = undef;
my $apr_include = undef;

Getopt::Long::GetOptions('apache-include=s' => \$apache_include,
                         'apr-include=s' => \$apr_include,
                        );

$apache_include = "-I$apache_include" if $apache_include;  

sub NeedToInstallApache
{
	my $Error = shift;
	warn $Error .
	"\nYou should install Apache 1.3.X or Apache 2.X first!\n" .
	"Sources of Apache available here: http://https.apache.org/\n".
	"You may also define the set params --apache-include and --apr-include.";
	exit;
}

my $mod_perl;

# Get Apache includes
eval { require Apache::src; };
unless ($@)
{
	$mod_perl = 1;
	$apache_include ||= Apache::src -> new -> inc;
}

unless ($mod_perl)
{
	eval { require Apache2::ParseSource; };
	unless ($@)
	{
		$mod_perl = 2;
		$apache_include ||= '-I' . join(' -I', @{Apache2::ParseSource -> new -> includes});
	}
}

print "perl thinks the current OS is '$^O'\n";

unless ($mod_perl) { NeedToInstallApache('Cannot find mod_perl modules.'); }
unless ($apache_include) { NeedToInstallApache("Cannot find header file httpd.h"); exit; }



my $apr_cflags;
my $apr_libs;
my $BUILD_REQ = {};

# Include APR
if ($mod_perl == 2 )
{
	$BUILD_REQ = {'ExtUtils::PkgConfig' => '1.03'};
	eval { require ExtUtils::PkgConfig; };
	unless ($@)
	{
		my %apr_info = ExtUtils::PkgConfig -> find('apr-1');
		$apr_cflags = defined $apr_include ? " -I$apr_include " : $apr_info{cflags};
		$apr_libs = defined $apr_include ? "" : $apr_info{libs};
	}
}

WriteMakefile(
	NAME              => 'Dendral::HTTP::Response',
	VERSION_FROM      => 'lib/Dendral/HTTP/Response.pm', 
	($] >= 5.005 ?
		(ABSTRACT_FROM    => 'lib/Dendral/HTTP/Response.pm', 
		 AUTHOR           => 'Dmitry Kosenkov & <d.kosenkov@rambler-co.ru>') : ()
	),
	($ExtUtils::MakeMaker::VERSION >= 6.56 ? 
		(BUILD_REQUIRES    => $BUILD_REQ) :
		(PREREQ_PM         => $BUILD_REQ) 
	),	
	DEFINE            => '', 
	INC               => "$apache_include -I/usr/include -I/usr/local/include -I. ",
	CCFLAGS           => $apr_cflags,
	LIBS              => $apr_libs,
);

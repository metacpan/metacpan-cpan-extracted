#!perl

use 5.006;
use ExtUtils::MakeMaker;

use strict;
use warnings;

use File::Basename;
use File::Spec;

require JavaScript;

my @incs;

# Additional inc
if (-f "/usr/include/smjs/jsapi.h") {
    push @incs, "/usr/include/smjs/";
}
elsif(-f "/usr/local/include/smjs/jsapi.h") {
    push @incs, "/usr/local/include/smjs/";
}
elsif(-f "/usr/include/mozjs/jsapi.h") {
    push @incs, "/usr/include/mozjs/";
}
elsif(-f "/usr/local/include/mozjs/jsapi.h") {
    push @incs, "/usr/local/include/mozjs/";
}

# test for gentoo
if(-f "/etc/gentoo-release") {
    # Gentoo puts libjs in a slightly hidden spot.
    @incs = qw(/usr/lib/MozillaFirefox/include/js/
              /usr/lib/MozillaFirefox/);

}

# test for DarwinPorts
if (-d "/opt/local/include/spidermonkey") {
    push @incs, "/opt/local/include/spidermonkey";
}
if (-d "/opt/local/include/js") {
    push @incs, "/opt/local/include/js";
}

# Override with  $ENV{JS_INC}
if (exists $ENV{JS_INC}) {
    @incs = do {
		my $path_separator = $^O eq 'Win32' ? ';' : ':';
		map { s/^\s+//; s/\s+$//; $_ } split/$path_separator/, $ENV{JS_INC};
	};
}

# Figure out some paths we need
my $pm_dir = dirname($INC{'JavaScript.pm'});
my $inc_dir = File::Spec->catdir($pm_dir, 'auto', 'JavaScript');
push @incs, $inc_dir;
my $typemap_path = File::Spec->catfile($inc_dir, 'typemap');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'JavaScript::Runtime::OpcodeCounting',
    VERSION_FROM      => 'lib/JavaScript/Runtime/OpcodeCounting.pm', # finds $VERSION
    PREREQ_PM         => {
		'JavaScript'	=> 1.03,
		'Test::More'  	=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JavaScript/Runtime/OpcodeCounting.pm', # retrieve abstract from module
       AUTHOR         => 'Claes Jakobsson <claesjac@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => join(" ", map { "-I$_" } @incs),
	TYPEMAPS		  => [$typemap_path],
	LICENSE			  => 'perl',
);

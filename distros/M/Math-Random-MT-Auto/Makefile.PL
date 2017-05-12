# Module makefile for Math::Random::MT::Auto (using ExtUtils::MakeMaker)

require 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

# Check for C compiler
sub check_cc
{
    require File::Spec;

    my $cmd = $_[0];
    if (-x $cmd or MM->maybe_command($cmd)) {
        return (1);       # CC command found
    }
    for my $dir (File::Spec->path(), '.') {
        my $abs = File::Spec->catfile($dir, $cmd);
        if (-x $abs or MM->maybe_command($abs)) {
            return (1);   # CC command found
        }
    }
    return;
}

sub have_cc
{
    eval { require Config_m; };     # ExtUtils::FakeConfig (+ MSWin32)
    if ($@) {
        eval { require Config; };   # Everyone else
    }
    my @chunks = split(/ /, $Config::Config{cc});
    # $Config{cc} may contain args; try to find out the program part
    while (@chunks) {
        if (check_cc("@chunks")) {
            return (1);   # CC command found
        }
        pop(@chunks);
    }
    return;
}

if (! have_cc()) {
    die("OS unsupported:  ERROR: No 'C' compiler found to build Math::Random::MT::Auto\n");
}


# Construct make file
WriteMakefile(
    'NAME'          => 'Math::Random::MT::Auto',
    'AUTHOR'        => 'Jerry D. Hedden <jdhedden AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Math/Random/MT/Auto.pm',
    'ABSTRACT_FROM' => 'lib/Math/Random/MT/Auto.pm',
    'PREREQ_PM'     => { 'Exception::Class'  => 1.32,
                         'Object::InsideOut' => 3.88,
                         'strict'            => 0,
                         'warnings'          => 0,
                         'Carp'              => 0,
                         'Fcntl'             => 0,
                         'XSLoader'          => 0,
                         'Test::More'        => 0,
                         'Scalar::Util'      => 1.23,
                         'Data::Dumper'      => 0,
                         'Config'            => 0,
                       },
    'OBJECT'        => 'MRMA.o',
    (($ExtUtils::MakeMaker::VERSION lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    (($ExtUtils::MakeMaker::VERSION gt '6.30') ?
        ('LICENSE'  => 'unrestricted') : ()),
);


package MY;

# Add to metafile target
sub metafile
{
    my $inherited = shift->SUPER::metafile_target(@_);
    $inherited .= <<'_MOREMETA_';
	$(NOECHO) $(ECHO) 'recommends:' >>$(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '  LWP::UserAgent: 0' >>$(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '  Win32::API: 0' >>$(DISTVNAME)/META.yml
_MOREMETA_

    return $inherited;
}

# Additional 'make' targets
sub postamble
{
    return <<'_EXTRAS_';
fixfiles:
	@dos2unix `cat MANIFEST`
	@$(CHMOD) 644 `cat MANIFEST`
	@$(CHMOD) 755 examples/*.pl

ppport:
	@( cd /tmp; perl -e 'use Devel::PPPort; Devel::PPPort::WriteFile("ppport.h");' )
	@if ! cmp -s ppport.h /tmp/ppport.h; then \
	    ( tkdiff ppport.h /tmp/ppport.h & ); \
	    perl /tmp/ppport.h; \
	fi
_EXTRAS_
}

# EOF

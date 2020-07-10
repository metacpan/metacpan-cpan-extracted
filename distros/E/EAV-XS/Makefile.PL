use strict;
use ExtUtils::MakeMaker 5.62;
use Config;

# The libeav options:
# * RFC6531_FOLLOW_RFC20 = ON | OFF     - disallow some chars by RFC 20
# * RFC6531_FOLLOW_RFC5322 = ON | OFF   - white-space chars depricated in quotes
# * FORCE_IDN = idn | idn2 | idnkit     - force build with specific idn library
# * DESTDIR = /path/to/install/libeav
# * INDKIT_DIR = /path/with/idnkit


sub myconfigure() {
    if (prompt("Use default options (y/n)?", "y") =~ /^y/i) {
        my $cfg = &build_auto();

        if ($^O =~ /^(free|net)bsd$/i || $^O eq "dragonfly") {
            $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.bsd";
        }
        elsif ($^O eq "openbsd") {
            $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.openbsd";
        }
        elsif ($^O eq "solaris") {
            $cfg->{'DEFINE'} = "-DEAV_EXTRA -m64";
            $cfg->{'dynamic_lib'}->{'OTHERLDFLAGS'} = "-m64";
        }
        elsif ($^O eq "MSWin32") {
            $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.windows-gmake";

            if ($Config{'cf_by'} eq "strawberry-perl") {
                $cfg->{'macro'}->{'LIBEAV_OPTIONS'} .= " CC=$Config{'ccname'}";
            }
        }
        elsif ($^O eq "cygwin") {
            $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.windows-gmake";
            $cfg->{'macro'}->{'LIBEAV_OPTIONS'} .= ' RM="rm -f"';
            $cfg->{'LD'} = "cc"; # either g++, but need install gcc-g++
        }

        return $cfg;
    }

    my $cfg;
    my $with_idn = prompt
        "Select IDN library to build with (auto/idn/idn2/idnkit):",
        "auto";

    if ($with_idn =~ /^auto$/i) {
        $cfg = &build_auto();
    }
    elsif ($with_idn =~ /^idn1?$/i) {
        $cfg = &build_with_idnX('idn');
    }
    elsif ($with_idn =~ /^idn2$/i) {
        $cfg = &build_with_idnX('idn2');
    }
    elsif ($with_idn =~ /^idnkit$/i) {
        $cfg = &build_with_idnkit();
    }
    else {
        print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

ERROR: Invalid IDN library.

Bye!
EOF
        exit 3;
    }

    my $rfc_opts = join(" ", &set_rfc_options());
    $cfg->{'macro'}->{'LIBEAV_OPTIONS'} .= " ${rfc_opts}";

    if ($^O =~ /^(free|net)bsd$/i) {
        $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.bsd";
    }
    elsif ($^O eq "openbsd") {
        $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.openbsd";
    }
    elsif ($^O eq "solaris") {
        $cfg->{'DEFINE'} = "-DEAV_EXTRA -m64";
        $cfg->{'dynamic_lib'}->{'OTHERLDFLAGS'} = "-m64";
    }
    elsif ($^O eq "MSWin32") {
        $cfg->{'macro'}->{'LIBEAV_MAKEFILE'} = "-f Makefile.windows-gmake";

        if ($Config{'cf_by'} eq "strawberry-perl") {
            $cfg->{'macro'}->{'LIBEAV_OPTIONS'} .= " CC=$Config{'ccname'}";
        }
    }

    return $cfg;
}


WriteMakefile(
    dist              => {
        'PREOP'    => 'pod2text lib/EAV/XS.pm'
                    . ' | tee README >$(DISTVNAME)/README;'
                    . ' chmod -R u=rwX,go=rX . ;',
        'COMPRESS' => 'gzip -9v',
        'SUFFIX'   => '.gz',
    },
    NAME              => 'EAV::XS',
    VERSION_FROM      => 'lib/EAV/XS.pm',
    PREREQ_PM         => {
        'XSLoader' => 0,
    },
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 5.62,
        'ExtUtils::PkgConfig' => 1.16,
    },
    ABSTRACT          => 'Email Address Validation Library',
    AUTHOR            => 'Vitaliy V. Tokarev <vitaliy.tokarev@gmail.com>',
    LICENSE           => 'freebsd',
    INC               => '-Ilibeav/include',
    DEFINE            => '-DEAV_EXTRA',
    OBJECT            => '$(O_FILES)',
    MYEXTLIB          => 'libeav/libeav.a',
    depend => {
        # also clean libeav files
        'clean_subdirs'     => 'clean-libeav',
        # libeav internal checks
        'check'             => 'check-libeav',
    },
    CONFIGURE => \&myconfigure,
);


# We don't want the default subdir rule, as it creates 
# a race condition with the rule we add below.
sub MY::subdir_x {
    return '';
}


sub MY::postamble {
    return <<'EOL';
$(MYEXTLIB): libeav/Makefile
	$(MAKE) -C libeav static $(LIBEAV_OPTIONS) $(LIBEAV_MAKEFILE) \
		INCLUDES="$(DEFINE)"

clean-libeav:
	$(MAKE) -C libeav clean $(LIBEAV_OPTIONS) $(LIBEAV_MAKEFILE) \
		INCLUDES="$(DEFINE)"

check-libeav:
	$(MAKE) -C libeav check $(LIBEAV_OPTIONS) $(LIBEAV_MAKEFILE) \
		INCLUDES="$(DEFINE)" LDFLAGS="$(OTHERLDFLAGS)"

EOL
}


sub set_rfc_options() {
    my @options;

    print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

In RFC 20 has been said that the following characters SHOULD NOT
to be used in international interchange without determining that
there is agreement between sender and recipient, such as
#, ~, ^, |, {, } and `.

Disabled by default.

WARNING: enabling this option will break tests.

EOF

    if (prompt ("Use RFC 20 rules (y/n)?", "n") =~ /^[yY]/) {
        push @options, "RFC6531_FOLLOW_RFC20=ON";
    }

    print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

RFC 5322 does NOT permit white-space characters (shortly WSP) in double 
quotes. Thats includes SPACE and TAB characters. According to this
RFC they must be specified as quote pair, e.g. "SPACE | TAB".

Also RFC 5322 allows some control characters in double quotes and
quoted pairs, such as Form Feed (\f), Line Feed (\n) and others.

Disabled by default.

WARNING: enabling this option will break tests.

EOF

    if (prompt("Use RFC 5322 syntax (y/n)?", "n") =~ /^[yY]/) {
        push @options, "RFC6531_FOLLOW_RFC5322=ON";
    }

    return @options;
}


# test if idnkit is installed properly; no critic
sub test_idnkit($) {
    my ($dir) = @_;

    return (-e "${dir}/include/idn/api.h");
}

# set idnkit installation directory and returns whether
# or not it is correct.
sub set_idnkit_dir($) {
    my ($dir_ref) = @_;
    $dir_ref =
    return &test_idnkit();
}

# define options when build with idnkit
sub build_with_idnkit() {
    # directory where idnkit was installed
    my $idnkit_dir = $ENV{'IDNKIT_DIR'} || '/usr/local';
    my @options;

    if (! &test_idnkit($idnkit_dir)) {
        do {
            print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Could not find idnkit header files. Please, set proper directory,
for instance, /opt/local.

EOF
            my $retry = prompt
                "Would you try to set idnkit install directory (y/n)?",
                "n";

            if ($retry =~ /^[nN]/) {
                print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

Sorry, can not build this module when idnkit is not installed.

Bye!
EOF
                exit 1;
            }

            $idnkit_dir = prompt
                "Directory where idnkit installed:",
                "$idnkit_dir";
        } while (! &test_idnkit($idnkit_dir));
    }

    push @options, "FORCE_IDN=idnkit";
    push @options, "IDNKIT_DIR=${idnkit_dir}";
    my $libs = "-L${idnkit_dir}/lib -lidnkit";

    return {
        LIBS => $libs,
        macro => {
            LIBEAV_OPTIONS => join(" ", @options),
        },
    };
}


sub build_auto() {
    my $libs = "";
    my @options;
    my $result;

    eval {
        require ExtUtils::PkgConfig;

        foreach my $idnname ('idn2', 'idn') {
            my $idnpkg = "lib" . $idnname;
            next if not ExtUtils::PkgConfig->exists ($idnpkg);
            my %pkg_info = ExtUtils::PkgConfig->find ($idnpkg);
            $libs = $pkg_info{'libs'};
            push @options, "FORCE_IDN=${idnname}";
            last;
        }

        if (! $libs) {
            print <<'EOF';

 *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

WARNING: Could not found libidn2 and libidn libraries on this system.
         Looking for idnkit...

EOF
            $result = return &build_with_idnkit();
        }
    };

    if ($@) {
        print STDERR $@;
        exit 1;
    }

    if ($result) {
        return $result;
    }

    return {
        LIBS => $libs,
        macro => {
            LIBEAV_OPTIONS => join(" ", @options)
        },
    };
}


sub build_with_idnX($) {
    my ($idnname) = @_;
    my $idnpkg = "lib" . $idnname;
    my @options;
    my $libs;

    eval {
        require ExtUtils::PkgConfig;

        if (!ExtUtils::PkgConfig->exists($idnpkg)) {
            die "Could not found ${idnpkg} on this system.";
        }

        my %pkg_info = ExtUtils::PkgConfig->find($idnpkg);
        $libs = $pkg_info{'libs'};
        push @options, "FORCE_IDN=${idnname}";
    };

    if ($@) {
        print STDERR $@;
        exit 2;
    }

    return {
        LIBS => $libs,
        macro => {
            LIBEAV_OPTIONS => join(" ", @options)
        },
    };
}

sub get_glibtop_config {

    my $GTOP_LIB = "";
    if (my $path = $ENV{GTOP_LIB}) {
        $GTOP_LIB = "-L$path ";
    }
    my $GTOP_INCLUDE = "";
    if (my $path = $ENV{GTOP_INCLUDE}) {
        $GTOP_INCLUDE = "-I$path ";
    }

    my %config = get_glibtop_config_core();

    # if none can be found will try the defaults
    unless ($GTOP_LIB || $config{libs}) {
        #needed for remote connection
        my $xlibs = "-L/usr/X11/lib -L/usr/X11R6/lib -lXau";
        my $GTOP_LIB_DEFAULT = 
            "-lgtop -lgtop_sysdeps -lgtop_common -lglib $xlibs ";
        $GTOP_LIB = $GTOP_LIB_DEFAULT;
    }

    my ($ginc, $gver);
    if ($config{ver} && $config{ver_maj} == 2 && $config{ver_min} >= 5) {
        $ginc = '';
        $gver = '-DGTOP_2_5_PLUS';
    }
    else {
        chomp($ginc = `glib-config --cflags`);
        $gver = '';
    }

    my $inc     = join " ", $GTOP_INCLUDE, $ginc, $config{incs};
    my $libs    = join " ", $GTOP_LIB, $config{libs};
    my $defines = $gver;

    return ($inc, $libs, $defines);
}

sub get_glibtop_config_core {
    my %c = ();

    if (system('pkg-config --exists libgtop-2.0') == 0) {
        # 2.x
        chomp($c{incs} = qx|pkg-config --cflags libgtop-2.0|);
        chomp($c{libs} = qx|pkg-config --libs   libgtop-2.0|);

        # 2.0.0 bugfix
        chomp(my $libdir = qx|pkg-config --variable=libdir libgtop-2.0|);
        $c{libs} =~ s|\$\(libdir\)|$libdir|;

        chomp($c{ver} = qx|pkg-config --modversion libgtop-2.0|);
        ($c{ver_maj}, $c{ver_min}) = split /\./, $c{ver};
    }
    elsif (system('gnome-config --libs libgtop') == 0) {
        chomp($c{incs} = qx|gnome-config --cflags libgtop|);
        chomp($c{libs} = qx|gnome-config --libs   libgtop|);

        # buggy ( < 1.0.9?) versions fixup
        $c{incs} =~ s|^/|-I/|;
        $c{libs} =~ s|^/|-L/|;

        # XXX: don't have that old setup anymore to figure out how to
        # check the version

    }

    return %c;
}

1;

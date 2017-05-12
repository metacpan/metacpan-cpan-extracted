use 5.006;

use lib '.';
use Inline::MakeMaker; # bundled

# see ExtUtils::MY documentation
sub MY::top_targets {
    package MY;
    my $out = shift->SUPER::top_targets(@_);
    my $link_code =
	"# Remove Inline::C configuration code\n"
	. "\t"
	. q{@$(PERL) -n -i -e '$$a=1 if/^\s*#\s*removed on install.*/;print if!$$a;$$a=0if/^\s*#\s*end[^\n]*/;' blib/lib/Mail/ClamAV.pm
};
    $out =~ s/\n\n/\n\nremove_on_install:\n$link_code\n/;
    $out =~ s/all :: pure_all/all :: pure_all remove_on_install/;

    return $out;
}

my $minclversion = "0.95.1";  # minimum clamav lib version
my $DEFAULT_LIBS = q(-lz -lbz2 -lgmp -lpthread);
my $DEFAULT_INC = '-I/usr/include';
my $AUTHOR = 'David P.C. Wollmann <converter42@gmail.com>';

# based on list posted at http://clamav.net/doc/latest/html/node7.html
my %supported_OS = (
    mswin32 => 'MSWin32',  # ClamAV wiki lists a few Win ports. We have not tested on Windows and make no guarantees this mod will work.
    cygwin => 'cygwin',
    linux => 'linux',
    solaris => 'solaris',
    freebsd => 'freebsd',
    openbsd => 'openbsd',
    macos => 'MacOS',
    netbsd => 'netbsd',    # NetBSD isn't listed on the web page, if it fails I'll remove it later.
);

my $warned = 0;


exit(main());


sub main {

    unless ($supported_OS{lc $^O}) {
        warn "The '$^O' OS is not supported by Clam AV (supported OSs: "
            . join(', ' => map {$supported_OS{$_}} sort keys %supported_OS)
            . ')';
        die 'No support for OS';
    }

    my $clver = get_cl_version();
    return warn_cl_version_bad() if $clver lt $minclversion;

    my $inc = get_cl_inc_paths();
    my $libs = get_cl_libs();

    $libs .= ' -clamav';

    write_config_pl($inc, $libs) or return 0;

    # NOTE: most of these options are ignored by Inline::MakeMaker
    my $rc = WriteMakefile(
        NAME                => 'Mail::ClamAV',
        VERSION_FROM        => 'ClamAV.pm', # finds $VERSION
        PREREQ_PM           => {}, # e.g., Module::Name => 1.1
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
          (ABSTRACT_FROM    => 'ClamAV.pm', # retrieve abstract from module
           AUTHOR           => $AUTHOR) : ()),
        LIBS                => ['-lclamav'],
        DEFINE              => '', # e.g., '-DHAVE_SOMETHING'
        PM                  => { 'ClamAV.pm' => 'blib/lib/Mail/ClamAV.pm' },
        # prevent EU::MM replacing our META.yml with a default one that's
        # missing important information, like "provides"
        NO_META             => 1,
            # Un-comment this if you add C files to link with later:
        # 'OBJECT'          => '$(O_FILES)', # link all the C files too
    );

    unless ($rc) {
        warn "WriteMakefile failed with return code: $rc";
        return -1;
    }

    return 0;
}

sub warn_cl_version_bad {
    warn "The clamav version you are using is too old. Please upgrade to at least $minclversion\n";
    return 0;
}

sub get_cl_version {
    my $version = `clamav-config --version`;
    chomp $version;

    return $version;
}

sub get_cl_inc_paths {
    my $inc = join " ", (`clamav-config --cflags` =~ /(-I\S+)/g);
    if ($?) {
        config_warn();
        warn "guessing include path is $DEFAULT_INC";
        $inc = $DEFAULT_INC;
    }
    else {
        chomp $inc;
    }

    return $inc;
}

sub get_cl_libs {
    my $libs = `clamav-config --libs`;
    if ($?) {
        config_warn();
        warn "guessing libraries needed are $DEFAULT_LIBS";
        $libs = $DEFAULT_LIBS;
    }
    else {
        chomp $libs;
    }
    $libs .= " -lclamav";

    return $libs;
}

sub write_config_pl {
    my ($inc, $libs) = @_;

    my $fh;
    unless (open $fh, ">", "config.pl") {
        warn "Could not open config.pl: $!";
        return;
    }
    print $fh <<END;
use Inline C => Config =>
    VERSION  => \$Mail::ClamAV::VERSION,
    PREFIX   => 'clamav_perl_',
    NAME     => "Mail::ClamAV",
    INC      => "$inc",
    LIBS     => "$libs";
1;
END
    close $fh;

    return 1;
}

sub config_warn {
    unless ($warned) {
        $warned++;
        warn "WARNING ------------------------------------------------\n";
        warn "WARNING You have an older version of clamav or\n";
        warn "WARNING clamav-config is not in your path\n";
        warn "WARNING If you get compile errors you will either\n";
        warn "WARNING need to upgrade clamav to at least $minclversion\n";
        warn "WARNING or make sure clamav-config is in your path\n";
        warn "WARNING ------------------------------------------------\n";
    }
}


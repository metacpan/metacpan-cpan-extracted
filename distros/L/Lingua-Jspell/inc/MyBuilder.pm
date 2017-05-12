package MyBuilder;
use base 'Module::Build';
use warnings;
use strict;
use Config;
use Carp;
use Config::AutoConf;
use ExtUtils::LibBuilder;
use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;
use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;

my $pedantic = $ENV{AMBS_PEDANTIC} || 0;

sub ACTION_pre_install {
    my $self = shift;

    # Fix the path to the library in case the user specified it during install
    if (defined $self->{properties}{install_base}) {
        my $usrlib = catdir($self->{properties}{install_base} => 'lib');
        $self->install_path( 'usrlib' => $usrlib );
        warn "libjspell.so will install on $usrlib. Be sure to add it to your LIBRARY_PATH\n"
    }

    if ($^O ne "MSWin32") {
        # Create and prepare for installation the .pc file if not under windows.
        _interpolate('jspell.pc.in' => 'jspell.pc',
                     VERSION    => $self->notes('version'),
                     EXECPREFIX => $self->install_destination('bin'),
                     LIBDIR     => $self->install_destination('usrlib'));
        $self->copy_if_modified( from   => "jspell.pc",
                                 to_dir => catdir('blib','pcfile'),
                                 flatten => 1 );

        $self->copy_if_modified( from   => catfile('src','jslib.h'),
                                 to_dir => catdir('blib','incdir'),
                                 flatten => 1);
    }

    ## FIXME - usar o Module::Build para isto?
    for (qw.ujspell jspell-dict jspell-to jspell-installdic.) {

        $self->copy_if_modified( from   => catfile("scripts",$_),
                                 to_dir => catdir('blib','script'),
                                 flatten => 1 );
        $self->fix_shebang_line( catfile('blib','script',$_ ));
        $self->make_executable(  catfile('blib','script',$_ ));
    }
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->dispatch("pre_install");
    $self->SUPER::ACTION_fakeinstall;
}

sub ACTION_install {
    my $self = shift;
    $self->dispatch("pre_install");
    $self->SUPER::ACTION_install;

    # Run ldconfig if root
    if ($^O =~ /linux/ && $ENV{USER} eq 'root') {
        my $ldconfig = Config::AutoConf->check_prog("ldconfig");
        system $ldconfig if (-x $ldconfig);
    }

    print STDERR "Type 'jspell-installdic pt en' to install portuguese and english dictionaries.\n";
    print STDERR "Note that dictionary installation should be performed by a superuser account.\n";
}

sub ACTION_code {
    my $self = shift;

    for my $path (catdir("blib","bindoc"),
                  catdir("blib","pcfile"),
                  catdir("blib","incdir"),
                  catdir("blib","script"),
                  catdir("blib","bin")) {
        mkpath $path unless -d $path;
    }

    my $libbuilder = ExtUtils::LibBuilder->new;
    $self->notes(libbuilder => $libbuilder);

    my $x = $self->notes('libdir');
    $x =~ s/\\/\\\\/g;
    _interpolate("src/jsconfig.in" => "src/jsconfig.h",
                 VERSION => $self->notes('version'),
                 LIBDIR  => $x,
                );

    $self->dispatch("create_manpages");
    $self->dispatch("create_yacc");
    $self->dispatch("create_objects");
    $self->dispatch("create_library");
    $self->dispatch("create_binaries");

    # $self->dispatch("compile_xscode");

    $self->SUPER::ACTION_code;
}

sub ACTION_create_yacc {
    my $self = shift;

    my $ytabc  = catfile('src','y.tab.c');
    my $parsey = catfile('src','parse.y');

    return if $self->up_to_date($parsey, $ytabc);

    my $yacc = Config::AutoConf->check_prog("yacc","bison");
    if ($yacc) {
        `$yacc -o $ytabc $parsey`;
    }
}

sub ACTION_create_manpages {
    my $self = shift;

    my $pods = $self->rscan_dir("src", qr/\.pod$/);

    my $version = $self->notes('version');
    for my $pod (@$pods) {
        my $man = $pod;
        $man =~ s!.pod!.1!;
        $man =~ s!src!catdir("blib","bindoc")!e;
        next if $self->up_to_date($pod, $man);
        ## FIXME
        `pod2man --section=1 --center="Lingua::Jspell" --release="Lingua-Jspell-$version" $pod $man`;
    }

    my $pod = 'scripts/jspell-dict';
    my $man = catfile('blib','bindoc','jspell-dict.1');
    unless ($self->up_to_date($pod, $man)) {
        `pod2man --section=1 --center="Lingua::Jspell" --release="Lingua-Jspell-$version" $pod $man`;
    }

    $pod = 'scripts/jspell-installdic';
    $man = catfile('blib','bindoc','jspell-installdic.1');
    unless ($self->up_to_date($pod, $man)) {
        `pod2man --section=1 --center="Lingua::Jspell" --release="Lingua-Jspell-$version" $pod $man`;
    }
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $c_files = $self->rscan_dir('src', qr/\.c$/);

    my $extra_compiler_flags = "-g " . $self->notes('ccurses');
    $extra_compiler_flags = "-Wall -Werror $extra_compiler_flags" if $pedantic;

    for my $file (@$c_files) {
        my $object = $file;
        $object =~ s/\.c/.o/;
        next if $self->up_to_date($file, $object);
        $cbuilder->compile(object_file  => $object,
                           source       => $file,
                           include_dirs => ["src"],
                           extra_compiler_flags => $extra_compiler_flags);
    }
}


sub ACTION_create_binaries {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $libbuilder = $self->notes('libbuilder');
    my $EXEEXT = $libbuilder->{exeext};
    my $extralinkerflags = $self->notes('lcurses').$self->notes('ccurses');

    my @toinstall;
    my $exe_file = catfile("src" => "jspell$EXEEXT");
    $self->config_data("jspell" => catfile($self->config_data("bindir") => "jspell$EXEEXT"));
    push @toinstall, $exe_file;
    my $object   = catfile("src" => "jmain.o");
    my $libdir   = $self->install_path('usrlib');
    if (!$self->up_to_date($object, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     objects  => [ $object ],
                                     extra_linker_flags => "-Lsrc -ljspell $extralinkerflags");
    }

    $exe_file = catfile("src","jbuild$EXEEXT");
    $self->config_data("jbuild" => catfile($self->config_data("bindir") => "jbuild$EXEEXT"));
    push @toinstall, $exe_file;
    $object   = catfile("src","jbuild.o");
    if (!$self->up_to_date($object, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     objects  => [ $object ],
                                     extra_linker_flags => "-Lsrc -ljspell $extralinkerflags");
    }

    for my $file (@toinstall) {
        $self->copy_if_modified( from    => $file,
                                 to_dir  => "blib/bin",
                                 flatten => 1);
    }
}

sub ACTION_create_library {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $libbuilder = $self->notes('libbuilder');
    my $LIBEXT = $libbuilder->{libext};

    my @files = qw!correct defmt dump gclass good hash jjflags
                   jslib jspell lookup makedent sc-corr term
                   tgood tree vars xgets y.tab!;

    my @objects = map { catfile("src","$_.o") } @files;

    my $libpath = $self->notes('libdir');
    $libpath = catfile($libpath, "libjspell$LIBEXT");
    my $libfile = catfile("src","libjspell$LIBEXT");

    my $extralinkerflags = $self->notes('lcurses').$self->notes('ccurses');
    $extralinkerflags.=" -install_name $libpath" if $^O =~ /darwin/;

    if (!$self->up_to_date(\@objects, $libfile)) {
        $libbuilder->link(module_name => 'libjspell',
                          extra_linker_flags => $extralinkerflags,
                          objects => \@objects,
                          lib_file => $libfile,
                         );
    }

    my $libdir = catdir($self->blib, 'usrlib');
    mkpath( $libdir, 0, 0777 ) unless -d $libdir;

    $self->copy_if_modified( from   => $libfile,
                             to_dir => $libdir,
                             flatten => 1 );
}

sub ACTION_test {
    my $self = shift;

    if ($^O =~ /mswin32/i) {
        my $oldpath = $ENV{PATH};
        $ENV{PATH} = catdir($self->blib, "usrlib").";$oldpath";
    } elsif ($^O =~ /darwin/i) {
        $ENV{DYLD_LIBRARY_PATH} = catdir($self->blib, "usrlib");
    }
    elsif ($^O =~ /(?:linux|bsd|sun|sol|dragonfly|hpux|irix)/i) {
        $ENV{LD_LIBRARY_PATH} = catdir($self->blib, "usrlib");
    }
    elsif ($^O =~ /aix/i) {
        my $oldlibpath = $ENV{LIBPATH} || '/lib:/usr/lib';
        $ENV{LIBPATH} = catdir($self->blib, "usrlib").":$oldlibpath";
    }

    $self->SUPER::ACTION_test
}


sub _interpolate {
    my ($from, $to, %config) = @_;
	
    print "Creating new '$to' from '$from'.\n";
    open FROM, $from or die "Cannot open file '$from' for reading.\n";
    open TO, ">", $to or die "Cannot open file '$to' for writing.\n";
    while (<FROM>) {
        s/\[%\s*(\S+)\s*%\]/$config{$1}/ge;		
        print TO;
    }
    close TO;
    close FROM;
}


1;

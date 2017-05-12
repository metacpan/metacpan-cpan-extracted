package MyBuilder;
use base 'Module::Build';
use warnings;
use strict;

use Pod::Man;

use Config;
use Config::AutoConf;
use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;
use Capture::Tiny 'capture';
use ExtUtils::LibBuilder;
use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;
use ExtUtils::PkgConfig;
use Parse::Yapp;

my $pedantic = $ENV{AMBS_PEDANTIC} || 0;

my %app_deps = (
                'pre'       => ['pre.o'],
                'grep'      => ['grep.o'],
                'mergeidx'  => ['invindexjoin.o'],
                'initmat'   => ['initmat.o', 'matrix.o'],
                'ipfp'      => ['ipfp.o', 'matrix.o'],
                'samplea'   => ['samplea.o', 'matrix.o'],
                'sampleb'   => ['sampleb.o', 'matrix.o'],
                'mat2dic'   => ['mat2dic.o', 'tempdict.o', 'matrix.o'],
                'words2id'  => ['words2id.o'],
                'css'       => ['ssentence.o'],
                'sentalign' => ['sent_align.o'],
                'postbin'   => ['postbin.o', 'tempdict.o'],
                'mkntd'     => ['mkdict.o'],
                'ntd-add'   => ['adddic.o'],
                'ntd-dump'  => ['ntdump.o'],
                'ngrams'    => ['ngrams_bdb.o'],
                'server'    => ['server.o'],
               );

my %lib_deps = (
                'words.o'      => ['words.c'   , 'NATools/words.h' ],
                'corpus.o'     => ['corpus.c'  , 'NATools/corpus.h'],
                'standard.o'   => ['standard.c', 'standard.h'],
                'dictionary.o' => ['dictionary.c', 'dictionary.h'],
                'natdict.o'    => ['natdict.c', 'natdict.h'],
                'natlexicon.o' => ['natlexicon.c', 'natlexicon.h'],
                'invindex.o'   => ['invindex.c', 'invindex.h'],
                'bucket.o'     => ['bucket.c', 'bucket.h'],
                'partials.o'   => ['partials.c', 'partials.h'],
                'corpusinfo.o' => ['corpusinfo.c', 'corpusinfo.h'],
                'parseini.o'   => ['parseini.c', 'parseini.h'],
                'srvshared.o'  => ['srvshared.c', 'srvshared.h'],
                'ngramidx.o'   => ['ngramidx.c', 'ngramidx.h'],
                'unicode.o'    => ['unicode.c', 'unicode.h'],
             );

my %o_deps = (
              %lib_deps,
              'samplea.o'      => ['samplea.c'],
              'sampleb.o'      => ['sampleb.c'],
              'mat2dic.o'      => ['mat2dic.c'],
              'tempdict.o'     => ['tempdict.c', 'tempdict.h'],
              'invindexjoin.o' => ['invindexjoin.c'],
              'grep.o'         => ['grep.c'],
              'postbin.o'      => ['postbin.c'],
              'server.o'       => ['server.c'],
              'adddic.o'       => ['adddic.c'],
              'ipfp.o'         => ['ipfp.c'],
              'ntdump.o'       => ['ntdump.c'],
              'matrix.o'       => ['matrix.c', 'matrix.h'],
              'initmat.o'      => ['initmat.c'],
              'mkdict.o'       => ['mkdict.c'],
              'ngrams_bdb.o'   => ['ngrams_bdb.c'],
              'ssentence.o'    => ['search_sentence.c'],
              'sent_align.o'   => ['sent_align.c'],
              'words2id.o'     => ['words2id.c'],
              'pre.o'          => ['pre.c'],
             );

sub _CC_ {
    my ($builder, %ops) = @_;
    my ($stdout, $stderr, $result) = capture { eval { $builder->compile(%ops); } };
    if (!$result) {
        print STDERR $stderr;
        print STDOUT $stdout;
    } else {
        no warnings;
        print LOG $stdout;
    }
}

sub _LD_ {
    my ($builder, %ops) = @_;
    my ($stdout, $stderr, $result) = capture { eval { $builder->link_executable(%ops) } };
    if (!$result) {
        print STDERR $stderr;
        print STDOUT $stdout;
    } else {
        no warnings;
        print LOG $stdout;
    }
}

sub _LOG_ {
    print LOG @_,"\n";
    print @_,"\n";
}

sub ACTION_pre_install {
    my $self = shift;

    # Fix the path to the library in case the user specified it during install
    if (defined $self->{properties}{install_base}) {
        my $usrlib = catdir($self->{properties}{install_base} => 'lib');
        $self->install_path( 'usrlib' => $usrlib );
        warn "libnatools will install on $usrlib. Be sure to add it to your LIBRARY_PATH\n"
    }

## XXX
#    if ($^O ne "MSWin32") {
#        # Create and prepare for installation the .pc file if not under windows.
#         _interpolate('jspell.pc.in' => 'jspell.pc',
#                      VERSION    => $self->notes('version'),
#                      EXECPREFIX => $self->install_destination('bin'),
#                      LIBDIR     => $self->install_destination('usrlib'));
#         $self->copy_if_modified( from   => "jspell.pc",
#                                  to_dir => catdir('blib','pcfile'),
#                                  flatten => 1 );

#         $self->copy_if_modified( from   => catfile('src','jslib.h'),
#                                  to_dir => catdir('blib','incdir'),
#                                  flatten => 1);
#     }

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

        my $libdir = $self->notes('libdir');

        my $found = 0;
        # 1. check if libdir is available
        my $lines = `$ldconfig -v`;
        for my $line (split /\n/, $lines) {
            $found++ if $line =~ /^$libdir:/;
        }
        if (!$found && open X, ">>", '/etc/ld.so.conf') {
            print X "$libdir\n";
            close X;
        }

        system $ldconfig if -x $ldconfig;
    }
}

sub ACTION_code {
    my $self = shift;

    open LOG, ">", "build.log" or die "Can't write on build.log";

    for my $path (
                  catdir("blib","bindoc"),
#                  catdir("blib","pcfile"),
#                   catdir("blib","incdir"),
#                   catdir("blib","script"),
                  catdir("blib","bin")
                 ) {
        mkpath $path unless -d $path;
    }

    $self->_set_libbuilder();

    my_yapp(module => 'Lingua::NATools::PatternRules',
            output => 'lib/Lingua/NATools/PatternRules.pm',
            input => 'lib/Lingua/NATools/PatternRules.yp');

    $self->dispatch("create_manpages");
    $self->dispatch("create_objects");
    $self->dispatch("create_library");
    $self->dispatch("create_apps");

    $self->dispatch("compile_xscode");

    $self->SUPER::ACTION_code;
}

sub ACTION_create_manpages {
    my $self = shift;
    my $pods = $self->rscan_dir("pods", qr/\.pod$/);
    my $version = $self->notes('version');
    my $pod2man = Pod::Man->new(release => "Lingua-NATools-$version",
                                center  => 'Lingua::NATools',
                                section => 1);

    for my $pod (@$pods) {
        my $man = $pod;
        $man =~ s!.pod!.1!;
        $man =~ s!pods!catdir("blib","bindoc")!e;
        next if $self->up_to_date($pod, $man);

        _LOG_ "  [pod2man] $pod";
        $pod2man->parse_from_file($pod => $man);
    }

#     my $pod = 'scripts/jspell-dict';
#     my $man = catfile('blib','bindoc','jspell-dict.1');
#     unless ($self->up_to_date($pod, $man)) {
#         `pod2man --section=1 --center="Lingua::Jspell" --release="Lingua-Jspell-$version" $pod $man`;
#     }

#     $pod = 'scripts/jspell-installdic';
#     $man = catfile('blib','bindoc','jspell-installdic.1');
#     unless ($self->up_to_date($pod, $man)) {
#         `pod2man --section=1 --center="Lingua::Jspell" --release="Lingua-Jspell-$version" $pod $man`;
#     }
}

sub ACTION_create_objects {
    my $self = shift;
    my $libbuilder = $self->notes('libbuilder');

    mkpath "_build/objects" unless -d "_build/objects";

    my $cflags = $self->notes('cflags');
    $cflags .= " -DMISSES_WCSDUP" unless $self->notes('have_wcsdup');
    $cflags .= " -g -Wall -Werror" if $pedantic;

    for my $object (keys %o_deps) {
        my @deps = map { "src/$_" } @{$o_deps{$object}};
        my $obj = "_build/objects/$object";

        next if $self->up_to_date(\@deps, $obj);

        _LOG_ "  [cc] $deps[0]";
        _CC_ $libbuilder => (object_file  => $obj,
                             source       => $deps[0],
                             include_dirs => ["src"],
                             extra_compiler_flags => $cflags);
    }
}


sub ACTION_create_apps {
    my $self = shift;

    mkpath "_build/apps" unless -d "_build/apps";

    my $libs = $self->notes('libs');

    if ($self->notes('lddlflags_had_local_lib')
        ||
        $self->notes('ldflags_had_local_lib'))
    {
       $libs = " -L/usr/local/lib $libs";
    }

    $libs = "-L_build/lib -lnatools $libs";


    my $libbuilder = $self->notes('libbuilder');
    my $EXE = $libbuilder->{exeext};
    for my $app (keys %app_deps) {
        my @deps = map { "_build/objects/$_" } @{$app_deps{$app}};

        my $exe = "nat-$app$EXE";
        my $exepath = "_build/apps/$exe";

        next if $self->up_to_date(\@deps, $exepath);

        _LOG_ "  [ld] $exe";
        _LD_ $libbuilder => (exe_file  => $exepath,
                             objects   => \@deps,
                             extra_linker_flags => $libs);

        $self->copy_if_modified(from => $exepath, to_dir => "blib/script", flatten => 1);
    }
}

sub ACTION_create_library {
    my $self = shift;
    my $libbuilder = $self->notes('libbuilder');
    my $LIBEXT = $libbuilder->{libext};

    my @objects = map { "_build/objects/$_" } keys %lib_deps;

    my $libpath = $self->notes('libdir');
    $libpath = catfile($libpath, "libnatools$LIBEXT");

    mkpath "_build/lib" unless -d "_build/lib";
    my $libfile = catfile("_build","lib","libnatools$LIBEXT");

    my $extralinkerflags = $self->notes('libs');
    $extralinkerflags.= " -install_name $libpath" if $^O =~ /darwin/;

    if (!$self->up_to_date(\@objects, $libfile)) {
        _LOG_ "  [ld] building libnatools$LIBEXT";


        if ($self->notes('lddlflags_had_local_lib')
            ||
            $self->notes('ldflags_had_local_lib'))
        {
          $extralinkerflags = "-L/usr/local/lib $extralinkerflags";
        }


        my ($stdout, $stderr, $result) = capture {
            eval {
                $libbuilder->link(module_name => 'libnatools',
                                  extra_linker_flags => $extralinkerflags,
                                  objects => \@objects,
                                  lib_file => $libfile,
                                 );
            }
        };
        if (!$result) {
            print STDERR $stderr;
            print STDOUT $stdout;
            exit 1;
        }
     }

    my $libdir = catdir($self->blib, 'usrlib');
    mkpath( $libdir, 0, 0777 ) unless -d $libdir;

    $self->copy_if_modified( from   => $libfile,
                             to_dir => $libdir,
                             flatten => 1 );
}

sub ACTION_create_test_binaries {
    my $self = shift;

    my %tests = (
                 'words'  => ['words_t.c'],
                 'corpus' => ['corpus_t.c'],
                );

    my $libbuilder = $self->notes('libbuilder');

    my $cflags = $self->notes('cflags');
    $cflags .= " -DMISSES_WCSDUP" unless $self->notes('have_wcsdup');
    $cflags .= " -g -Wall -Werror" if $pedantic;

    my $ldlibs = "";
    if ($self->notes('lddlflags_had_local_lib')
        ||
        $self->notes('ldflags_had_local_lib'))
    {
       $ldlibs = " -L/usr/local/lib ";
    }

    my $libs = join(" ",
                    "-L_build/lib -lnatools",
                    $ldlibs,
                    $self->notes('libs'));
    my $EXE = $libbuilder->{exeext};
    for my $test (keys %tests) {
        my @deps = map { "t/bin/$_" } @{$tests{$test}};
        my $exe = $test.$EXE;
        my $object = "t/bin/$test.o";
        my $exepath = "t/bin/$exe";

        next if $self->up_to_date(\@deps, $exepath);

        _CC_ $libbuilder => (object_file => $object,
                             source      => $deps[0],
                             include_dirs => ["src"],
                             extra_compiler_flags => $cflags);

        _LD_ $libbuilder => (exe_file  => $exepath,
                             objects   => [$object],
                             extra_linker_flags => $libs);
    }
}

sub ACTION_test {
     my $self = shift;

     $self->_set_libbuilder;

     $self->dispatch('create_test_binaries');

     if ($^O =~ /mswin32/i) {
         $ENV{PATH} = join(";",
                           catdir($self->blib,"script"),
                           catdir($self->blib,"usrlib"),
                           $ENV{PATH});;
     }
     elsif ($^O =~ /darwin/i) {
         $ENV{DYLD_LIBRARY_PATH} = catdir($self->blib,"usrlib");
         $ENV{PATH} = catdir($self->blib,"script") . ":$ENV{PATH}";
     }
     elsif ($^O =~ /(?:linux|bsd|sun|sol|dragonfly|hpux|irix)/i) {
         $ENV{LD_LIBRARY_PATH} = catdir($self->blib,"usrlib");
         $ENV{PATH} = catdir($self->blib,"script") . ":$ENV{PATH}";
     }
     elsif ($^O =~ /aix/i) {
         my $oldlibpath = $ENV{LIBPATH} || '/lib:/usr/lib';
         $ENV{LIBPATH} = catdir($self->blib,"usrlib").":$oldlibpath";
         $ENV{PATH} = catdir($self->blib,"script") . ":$ENV{PATH}";
     }

    $self->SUPER::ACTION_test
}


sub _set_libbuilder {
    my $self = shift;
    my ($out, $err, $libbuilder) = capture {ExtUtils::LibBuilder->new(); };

    ## Mac OS X hack
    $libbuilder->{config}{ccflags} =~ s/-arch \S+//g;
    $libbuilder->{config}{lddlflags} =~ s/-arch \S+//g;
    $libbuilder->{config}{ldflags} =~ s/-arch \S+//g;

    if ($libbuilder->{config}{lddlflags} =~ 
        s{ -L\s*/usr/local/lib(?:$|\b)}{}) {
      $self->notes(lddlflags_had_local_lib => 1);
    }

    if ($libbuilder->{config}{ldflags} =~
        s{ -L\s*/usr/local/lib(?:$|\b)}{}) {
      $self->notes(ldflags_had_local_lib => 1);
    } 

    $self->notes(libbuilder => $libbuilder);
}


sub ACTION_compile_xscode {
    my $self = shift;
    my $libbuilder = $self->notes('libbuilder');

    my $archdir = catdir( $self->blib, 'arch', 'auto', 'Lingua', 'NATools');
    mkpath( $archdir, 0, 0777 ) unless -d $archdir;

    my $cfile = catfile("xs","NATools.c");
    my $xsfile= catfile("xs","NATools.xs");

    if (!$self->up_to_date($xsfile, $cfile)) {
        _LOG_ "  [XS] natools.xs";
        ExtUtils::ParseXS::process_file( filename   => $xsfile,
                                         prototypes => 0,
                                         typemap    => 'typemap',
                                         output     => $cfile);
    }

    my $ofile = catfile "xs","NATools.o";
    if (!$self->up_to_date($cfile, $ofile)) {
        my $cflags = $self->notes('cflags');
        $cflags .= " -DMISSES_WCSDUP" unless $self->notes('have_wcsdup');
        $cflags .= " -g -Wall -Werror" if $pedantic;

        _LOG_ "  [CC] natools.c";
        _CC_ $libbuilder => ( source               => $cfile,
                              include_dirs         => [ "src" ],
                              extra_compiler_flags => $cflags,
                              object_file          => $ofile);
    }

    # Create .bs bootstrap file, needed by Dynaloader.
    my $bs_file = catfile $archdir, "NATools.bs";
    if ( !$self->up_to_date( $ofile, $bs_file ) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if ( !-f $bs_file ) {
            # Create file in case Mkbootstrap didn't do anything.
            open( my $fh, '>', $bs_file ) or warn "Can't open $bs_file: $!";
        }
        utime( (time) x 2, $bs_file );    # touch
    }

    my $objects = [ $ofile ];
    # .o => .(a|bundle)
    my $lib_file = catfile $archdir, "NATools.$Config{dlext}";
    if ( !$self->up_to_date( $objects, $lib_file ) ) {
        my $libdir = $self->install_path('usrlib');
        my $libs = $self->notes('libs');

        if ($self->notes('lddlflags_had_local_lib')
            ||
            $self->notes('ldflags_had_local_lib'))
        {
           $libs = " -L/usr/local/lib $libs";
        }

        $libs = "-L_build/lib -lnatools $libs";

        _LOG_ "  [LD] NATools.$Config{dlext}";
        my ($std, $err, $ret) = capture {
            eval {
                $libbuilder->link(
                                  module_name => 'Lingua::NATools',
                                  extra_linker_flags => $libs,
                                  objects     => $objects,
                                  lib_file    => $lib_file,
                                 );
            }
        };
        if (!$ret) {
            print STDOUT $std;
            print STDERR $err;
        }
    }
}


sub set_version {
    my ($builder, $CAC) = @_;
    $CAC->msg_checking("NATools version");

    my $version = undef;
    open PM, "lib/Lingua/NATools.pm" or die "Cannot open 'NAT.pm.in' for reading: $!\n";
    while (<PM>) {
        if (m!^our\s+\$VERSION\s*=!) {
            $version = eval;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on the .pm file. Weirdo!\n" unless $version;

    $CAC->msg_result($version);

    $builder->notes('version'  => $version);
    $builder->config_data("version" => $version);
}

# C::AC here is only needed for pretty output printing. Probably get rid of it?
sub pkg_config_check {
    my ($builder, $CAC, $package, $version) = @_;
    $CAC->msg_checking("for $package >= $version");

    if (!ExtUtils::PkgConfig->atleast_version($package, $version)) {
        $CAC->msg_result("no");
        $CAC->msg_error("$package version $version or greater is required.");
    }
    $CAC->msg_result("yes");
    my %pkg = ExtUtils::PkgConfig->find($package);
    $builder->notes('libs'   => $builder->notes('libs')  . " " . $pkg{libs});
    $builder->notes('cflags' => $builder->notes('cflags'). " " . $pkg{cflags});
}


sub compute_lib_dir {
    my $builder = shift;

    ## HACK  HACK  HACK  HACK
    my $bindir = $builder->install_destination("bin");
    my $libdir = $bindir;
    my $pkgdir = $libdir;
    my $incdir = $libdir;
    if ($^O =~ /mswin32/i) {
        $libdir = undef;
        # Find a place where we can write.
        my @folders = split /;/, $ENV{PATH};
        my $installed = 0;
        my $target = "nat-test.$$";
        while(@folders && !$installed) {
            $libdir = shift @folders;	

            copy("MANIFEST", catfile($libdir,$target));
            $installed = 1 if -f catfile($libdir, $target);
        }
        if (!$installed) {
            warn("Wasn't able to find a suitable place for libnatools.dll!");
        } else {
            print STDERR "libnatools.dll will be installed in $libdir\n";
            unlink catfile($libdir, $target);
        }
        $pkgdir = undef;
        $incdir = undef;
    } else {
        $libdir =~ s/\bbin\b/lib/;
        $incdir =~ s/\bbin\b/include/;
        $pkgdir =~ s/\bbin\b/catdir("lib","pkgconfig")/e;
    }

    $builder->config_data('libdir' => $libdir);
    $builder->config_data('bindir' => $bindir);

    $builder->notes('libdir' => $libdir);
    $builder->notes('incdir' => $incdir);
    $builder->notes('pkgdir' => $pkgdir);

}

sub write_config_h {
    my $builder = shift;
    open H, ">", "src/NATools/config.h";

    print H "#define VERSION \"",$builder->notes('version'),"\"\n";
    print H "#define PACKAGE \"Lingua::NATools\"\n";
    print H "#define DB_HEADER <db.h>\n";

    close H;
}

sub check_sqlite3 {
    my ($builder, $CAC) = @_;
    $CAC->msg_checking("for sqlite3 binary");
    my $sqlite = $CAC->check_prog("sqlite3");
    if (!defined($sqlite)) {
        $CAC->msg_result("no");
        $builder->FAIL;
    } else {
        $builder->config_data('sqlite3' => $sqlite);
        $CAC->msg_result("yes");
    }
}

sub check_berkeley_db {
    my ($builder, $CAC, $version) = @_;

    my ($minvermajor, $minverminor, $minverpatch) = split /\./, ($version || "");
    $minvermajor ||= 0;
    $minverminor ||= 0;
    $minverpatch ||= 0;

    my $prologue = "#include <db.h>";
    my $body = <<"EOP";
         #if !((DB_VERSION_MAJOR  > ($minvermajor)  || \\
	       (DB_VERSION_MAJOR == ($minvermajor)  && \\
	        DB_VERSION_MINOR  > ($minverminor)) || \\
	       (DB_VERSION_MAJOR == ($minvermajor)  && \\
                DB_VERSION_MINOR == ($minverminor)  && \\
                DB_VERSION_PATCH >= ($minverpatch))))
            #error "too old version"
         #endif

   DB *db;
   db_create(&db, NULL, 0);
EOP

    my $app = $CAC->lang_build_program( $prologue, $body );

    $CAC->msg_checking("for Berkeley DB header >= $minvermajor.$minverminor.$minverpatch");
    $CAC->compile_if_else($app,
                          {
                            action_on_true => sub {
                               $CAC->msg_result("yes");
                            },
                            action_on_false => sub {
                              $CAC->msg_result("no");
                              $builder->FAIL
                            }} );

    $CAC->msg_checking("for Berkeley DB library >= $minvermajor.$minverminor.$minverpatch");
    $CAC->push_libraries("db");
    $CAC->link_if_else($app,
                       {
                        action_on_true => sub { $CAC->msg_result("yes"); },
                        action_on_false => sub { $CAC->msg_result("no"); $builder->FAIL }});

    $builder->notes('libs' => $builder->notes('libs') . " -ldb");
}

sub FAIL { print "Error, can't continue\n"; exit 0; }

sub my_yapp {
    my %ops = @_;

    my ($parser) = Parse::Yapp->new(inputfile => $ops{input});

    open OUT, ">", $ops{output} or die "Can't create $ops{output} file";
    print OUT $parser->Output(classname => $ops{module},
                              standalone => 0,
                              linenumbers => 1,
                              template => "");
    close OUT;
}

1;

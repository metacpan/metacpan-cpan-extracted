package ExtUtils::MakeMaker::BigHelper;

use strict;
use warnings;

require File::Find;
require Data::Dumper;

use ExtUtils::MakeMaker::Config qw(Config);
use base qw(Exporter);

our %EXPORT_TAGS = (
  'all' => [ qw(
    find_files
    find_directories
    init_dirscan
    init_xs
    init_PM
    clean_subdirs
    clean
    postamble
    dynamic_bs
    dynamic_lib
    test
    %Is
  ) ],
  'find' => [ qw(
    find_files
    find_directories
  ) ],
  'MY' => [ qw(
    init_dirscan
    init_xs
    init_PM
    clean_subdirs
    clean
    postamble
    dynamic_bs
    dynamic_lib
    test
    %Is
  ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.92';

my $debugf;

our %Is;
$Is{OS2}     = $^O eq 'os2';
$Is{Win32}   = $^O eq 'MSWin32' || $Config{osname} eq 'NetWare';
$Is{Dos}     = $^O eq 'dos';
$Is{VMS}     = $^O eq 'VMS';
$Is{OSF}     = $^O eq 'dec_osf';
$Is{IRIX}    = $^O eq 'irix';
$Is{NetBSD}  = $^O eq 'netbsd';
$Is{Interix} = $^O eq 'interix';
$Is{SunOS4}  = $^O eq 'sunos';
$Is{Solaris} = $^O eq 'solaris';
$Is{SunOS}   = $Is{SunOS4} || $Is{Solaris};
$Is{BSD}     = ($^O =~ /^(?:free|net|open)bsd$/ or grep( $^O eq $_, qw(bsdos interix dragonfly) ));

=head1 NAME

ExtUtils::MakeMaker::BigHelper - for helping ExtUtils::MakeMaker with big XS
projects.

=head1 SYNOPSIS

  use ExtUtils::MakeMaker::BigHelper qw(:find);

    This exports find_files and find_directories, which might be useful with
    WriteMakefile from ExtUtils::MakeMaker.

  use ExtUtils::MakeMaker::BigHelper qw(:MY);

    Use this after a "package MY;" statement.  It will export methods that
    are used by ExtUtils::MakeMaker and available for customization.  These
    customized methods will alter the behaviour of ExtUtils::MakeMaker as
    documented below.

=head1 DESCRIPTION

This package extends or alters the functionality of ExtUtils::MakeMaker,
in a way more suitable perhaps for large projects using a lot of perl XS.

This allows multiple .xs files in your project, strewn about the lib directory
hierarchy, hopefully side by each with the corresponding .pm file.  Multiple t
directories are also allowed, hopefully located next to the .pm files they test.

See the man page for perlxs for more information about perl XS.

With ExtUtils::MakeMaker there can only be one .xs file, which limits the size
of the project.  Well, there is a way to have more, but you're left with one
master .xs file responsible for bootstrapping all the other ones.  The way
to have two .xs files is documented, but not easy, and the way to have more
than two is, well, unnatural.

With ExtUtils::MakeMaker you're allowed to provide customizations for various
MakeMaker methods in the package MY.  This gives you the ability to make a
total overhaul of ExtUtils::MakeMaker.

This package uses the customization facility built in to ExtUtils::MakeMaker
to allow multiple .xs files, multiple t files, and multiple subproject
(Makefile.PL and Build.PL) directories in the lib hierarchy rather than at
the top level of the project.  This allows you to more conveniently use
perlxs in your project, without having to package up multiple Makefile.PL
projects embedded in your directories.  It also allows you to convert all
those .pm files with Inline code into real perlxs without using dynamite.

The methods here are meant to be exported into the package MY, to provide
customizations of the ExtUtils::MakeMaker methods.

For example, here's a possible project layout:

  Changes
  lib/Big/Project.pm
  lib/Big/Project/Collections/MyLRU.xs
  lib/Big/Project/Collections/MyLRU.pm
  lib/Big/Project/Collections/t/00-usage.t
  lib/Big/Project/Collections/t/10-testlru.t
  lib/Big/Project/Worker.pm
  lib/Big/Project/Slave.pm
  lib/Big/Project/Dispatcher/Scheduler.xs
  lib/Big/Project/Dispatcher/Scheduler.pm
  lib/Big/Project/Dispatcher/t/00-usage.t
  lib/Big/Project/Dispatcher/t/10-roundrobin.t
  lib/Big/Project/clib/Makefile
  lib/Big/Project/clib/toolbox.c
  lib/Big/Project/clib/toolbox.h
  lib/Big/Project/clib/hashmaker.c
  lib/Big/Project/clib/hashmaker.h
  Makefile.PL
  MANIFEST
  README

The Makefile.PL would look like this:

  use ExtUtils::MakeMaker;

  WriteMakefile(
    NAME => "Big::Project",
    VERSION_FROM => "lib/Big/Project.pm",
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Big Project',
       AUTHOR         => 'John Bigbooty <john.bigbooty@yoyodyne.com>') : ()),
    DEFINE            => '',
    LIBS              => ['-lm' ], # e.g., '-lm'
    INC               => '-I. -Ilib/Big/Project/clib',
    MYEXTLIB          => 'lib/Big/Project/clib/libmyextlib.a',
  );

  package MY;

  use ExtUtils::MakeMaker::BigHelper qw(:MY);

That should do it.  It uses File::Find to descend the hierarchy and find all
the .xs files and t directories.

=head2 B<$found = find_files($regex, @directories)>

This function is exported by the :find tag, and looks up all files matching
the regex, under the listed directories.  It returns them in a hashref where
the keys are the files found and the value is 1.

=cut

sub find_files {
  my ($pat, @dirs) = @_;

  my %found;
  File::Find::find({wanted => sub { $found{$File::Find::name}=1 if /$pat/ && -f $File::Find::name }, no_chdir  => 1}, @dirs);

  return \%found;
}

=head2 B<$found = find_directories($regex, @directories)>

This function is exported by the :find tag, and looks up all directories
matching the regex, under the listed directories.  It returns them in a
hashref where the keys are the directories found and the value is 1.

=cut

sub find_directories {
  my ($pat, @dirs) = @_;

  my %found;
  File::Find::find({wanted => sub { $found{$File::Find::name}=1 if /$pat/ && -d $File::Find::name }, no_chdir  => 1}, @dirs);

  return \%found;
}

sub make_hashref_of_found_files {
  my ($pat, @dirs) = @_;

  my %found;
  File::Find::find({wanted => sub { $found{$File::Find::name}=1 if /$pat/ }, no_chdir  => 1}, @dirs);

  return \%found;
}

=head2 B<$obj->init_dirscan>

This function is exported by the :MY tag.  It extends the MM init_dirscan.

The MM init_dirscan only looks for .xs files in the top level directory.
This extension descends into lib to find all .xs files, and sets them into
the $self XS setting.

Note that the XS setting is supposed to be a hashref of .xs files,
where the value is the corresponding .c file.  However, with these
overrides, the value need only be 1 if the .c file is as expected.

=cut

sub init_dirscan {
  my ($self) = @_;

  # the init_dirscan in MM_Unix does not recursively search directories
  # here we want to recursively search for .xs files

  $self->{XS} ||= ExtUtils::MakeMaker::BigHelper::make_hashref_of_found_files(qr/\.xs$/, 'lib');

  my $result = $self->MM::init_dirscan;
  print STDERR "debug: after init_dirscan PM is ", Data::Dumper::Dumper($self->{PM}) if $debugf;
  return $result;
}

=head2 B<$obj->test>

This function is exported by the :MY tag.  It extends the MM test.

The MM test only looks for t directories at the top level directory.  This
extension descends into lib to find all t directories, and sets them into
the $self TESTS setting.

The $self TESTS setting is supposed to be a blank separated list
of t files (with shell wildcards) to run.

Note that the XS setting is supposed to be a hashref of .xs files,
where the value is the corresponding .c file.  However, with these
overrides, the value need only be 1 if the .c file is as expected.

=cut

sub test {
  my ($self, %attribs) = @_;

  # recurses to find deeper t directories
  # allows you to put the t/*.t tests next to any deeper xs or pm files that need testing.
  # todo: filter out DIR Makefile.PL Build.PL directories
  # todo: filter out MYLIBEXT directories

  unless ($attribs{TESTS}) {
    my %dir = map { ($_ => $_) } @{$self->{DIR}};
    my %found;
    File::Find::find(
      {
        no_chdir  => 1,
        wanted => sub {
          if (-d $_) {
            if ($dir{$_}) {
              $File::Find::prune = 1;
            }

            return;
          }

          if (/\.t$/ && -f $File::Find::name) {
            if ($File::Find::dir =~ /^t$/) {
              $found{File::Spec->catfile('t', '*.t')}=1;
            } elsif ($File::Find::dir =~ /^t\//) {
              $found{File::Spec->catfile('t', $', '*.t')}=1;
            } elsif ($File::Find::dir =~ /\/t$/) {
              $found{File::Spec->catfile($`, 't', '*.t')}=1;
            } elsif ($File::Find::dir =~ /\/t\//) {
              $found{File::Spec->catfile($`, 't', $', '*.t')}=1;
            }
          }
        },
      },
      grep -d $_, 't', 'lib', 'bin');

    $attribs{TESTS} = join(' ', sort keys %found);
  }

  print STDERR "debug: test attribs TESTS = $attribs{TESTS}\n" if $debugf;

  $self->MM::test(%attribs);
}

#sub init_PM {
#    my ($self) = @_;
#    $self->MM::init_PM;
#}

=head2 B<$obj->init_PM>

This function is exported by the :MY tag.  It extends/replaces the MM
init_PM.

This method only puts .pm files into the $self PM setting.

The default init_PM puts all files into the $self PM setting.

=cut

sub init_PM {
  my ($self) = @_;

  # Some larger extensions often wish to install a number of *.pm/pl
  # files into the library in various locations.

  # The attribute PMLIBDIRS holds an array reference which lists
  # subdirectories which we should search for library files to
  # install. PMLIBDIRS defaults to [ 'lib', $self->{BASEEXT} ].  We
  # recursively search through the named directories (skipping any
  # which don't exist or contain Makefile.PL files).

  # For each *.pm or *.pl file found $self->libscan() is called with
  # the default installation path in $_[1]. The return value of
  # libscan defines the actual installation location.  The default
  # libscan function simply returns the path.  The file is skipped
  # if libscan returns false.

  # The default installation location passed to libscan in $_[1] is:
  #
  #  ./*.pm           => $(INST_LIBDIR)/*.pm
  #  ./xyz/...        => $(INST_LIBDIR)/xyz/...
  #  ./lib/...        => $(INST_LIB)/...
  #
  # In this way the 'lib' directory is seen as the root of the actual
  # perl library whereas the others are relative to INST_LIBDIR
  # (which includes PARENT_NAME). This is a subtle distinction but one
  # that's important for nested modules.

  unless( $self->{PMLIBDIRS} ) {
    if( $Is{VMS} ) {
      # Avoid logical name vs directory collisions
      $self->{PMLIBDIRS} = ['./lib', "./$self->{BASEEXT}"];
    }
    else {
      $self->{PMLIBDIRS} = ['lib', $self->{BASEEXT}];
    }
  }

  #only existing directories that aren't in $dir are allowed

  # Avoid $_ wherever possible:
  my %dir = map { ($_ => 1) } @{$self->{DIR}};
  my @todel;
  for (my $ii = 0; $ii < @{$self->{PMLIBDIRS}}; $ii++) {
      my $pmlibdir = $self->{PMLIBDIRS}[$ii];
      push @todel, $ii if !-d $pmlibdir || $dir{$pmlibdir};
  }
  delete @{$self->{PMLIBDIRS}}[@todel] if @todel;

  @{$self->{PMLIBPARENTDIRS}} = ('lib') unless $self->{PMLIBPARENTDIRS} && @{$self->{PMLIBPARENTDIRS}};

  return if ($self->{PM} && $self->{ARGS}{PM}) || !@{$self->{PMLIBDIRS}};

  print "Searching PMLIBDIRS: @{$self->{PMLIBDIRS}}\n" if 2 <= $ExtUtils::MakeMaker::Verbose;

  my $parentlibs_re = join '|', @{$self->{PMLIBPARENTDIRS}};
  $parentlibs_re = qr/$parentlibs_re/;

  File::Find::find(sub {
    if (-d $_){
      unless ($self->libscan($_)){
        $File::Find::prune = 1;
      }
      return;
    }

    return if /\#/  ||
              /~$/  ||         # emacs temp files
              /,v$/ ||         # RCS files
              /\.swp$/;        # vim swap files

    return unless /\.pm$/;

    my $path   = $File::Find::name;
    my $prefix = $self->{INST_LIBDIR};
    my $striplibpath;

    $prefix =  $self->{INST_LIB} if ($striplibpath = $path) =~ s{^(\W*)(?:$parentlibs_re)\W}{$1}i;

    my($inst) = $self->catfile($prefix,$striplibpath);
    local($_) = $inst; # for backwards compatibility
    $inst = $self->libscan($inst);
    print "libscan($path) => '$inst'\n" if 2 <= $ExtUtils::MakeMaker::Verbose;

    return unless $inst;

    $self->{PM}{$path} = $inst;
  }, @{$self->{PMLIBDIRS}});
}

=head2 B<$obj->init_XS>

This function is exported by the :MY tag.  It extends the MM init_XS.

This sets up macros INST_STATIC, INST_DYNAMIC, INST_BOOT, and uses
INST_ARCHLIB.

note: init_dirscan will set XS and DIR to defaults.  However, init_dirscan
has limitations, mostly that it cannot handle large projects.

input and output:

  XS          as documented in ExtUtils::MakeMaker, this is a hashref.
              the key is the relative path of the xs file.
              the value can be the target c file as documented.
              EXTENSION: the value can be simply 1 if the c file can be
                         simply generated from the xs file.
              EXTENSION: the value can be the package name XXX::YYY::ZZZ for
                         the xs code.
              EXTENSION: the value can be an array of c dependencies
              EXTENSION: the XS hash is reworked by this code.

  DIR         as documented, an arrayref of subdirectories containing
              Makefile.PL
              EXTENSION: may be an arrayref of pathnames for Makefile.PLs
                         and Build.PLs init_dirscan only looks one deep for
                         Makefile.PLs, and does not look for Build.PLs.
                         With this extension, you could do a recursive file
                         find for all Makefile.PLs and Build.PLs no matter
                         how deep.
              
  MYEXTLIB

output

  MY_XS_DEPENDENCIES
  MY_SUBDIRS
  MY_EXTENSION_LIBS
  MY_XS_TARGETS

=cut

sub init_xs {
  my $self = shift;

  print STDERR "debug: ", Data::Dumper::Dumper($self), "\n" if $debugf;

  my %c_files = $self->{C} ? map { ( $_ => 1 ) } (ref($self->{C}) ? @{ $self->{C} } : split(/\s+/, $self->{C})) : ();

  foreach my $xs ( keys %{ $self->{XS} } ) {
    my $c_file = $self->{XS}{$xs};
    my $package;

    if (ref($c_file) eq 'ARRAY') {
      ## $c_file is a list of dependencies
      $self->{MY_XS_DEPENDENCIES}{$xs} = $c_file;
      undef $c_file;
    }

    # we need the package name so that we can generate the correct bootstrap

    $package = $c_file if $c_file && $c_file =~ /::/;

    if (!$c_file || $c_file !~ /\.c$/) {
      # ignore the value from XS, generate the c file name from the xs file name
      ($c_file = $xs) =~ s/\.xs$/.c/;
      $self->{XS}{$xs} = $c_file;
    }

    $c_files{$c_file}++ if $c_file;

    if (!$package && (!$c_file || $c_file =~ /\.c$/)) {
      # scan the xs file for the package name

      if (open(my $fh, $xs)) {
        while (<$fh>) {
          chomp;
          if (/^\s*MODULE\s*=\s*(\S+)\s+PACKAGE\s*=\s*(\S+)/) {
            $package = $1;
            last;
          }
        }
        close($fh);
      }
    }

    if (!$package && $xs =~ /^lib\//) {
      # generate the package name from the file name since the file name looks sane

      ($package = $') =~ s/\.xs//;
      $package =~ s/\//::/g;
    }

    $self->{MY_XS_TARGETS}{$xs} = $package unless $self->{MY_XS_TARGETS}{$xs};
  }

  $self->{C} = [ sort keys %c_files ]; # has_link_code may rely on this

  if ($self->{DIR} || $self->{MYEXTLIB}) {
    my @myextlib = ref($self->{MYEXTLIB}) eq 'ARRAY'
        ?  @{ $self->{MYEXTLIB} }
        : split /\s+/, $self->{MYEXTLIB};

    my %PL_dirs;
    my %cleanup_makefile_dirs;
    my %c_extension_libs;
    my @c_extension_libs;
    my @c_myextlib_replacement;

    foreach my $subdir ( @{ $self->{DIR} }, @myextlib ) {
      if ($subdir =~ /^(.+)\/lib([^\/]+)\.(?:a|so)$/) {
        # $subdir is actually the pathname of a lib
        $c_extension_libs{$1}{$subdir} = 1;
        $cleanup_makefile_dirs{$1} = 1;
        push @c_extension_libs, $2;
        push @c_myextlib_replacement, $subdir;
      } elsif ($subdir =~ /\/(?:Makefile|Build)\.PL$/) {
        $PL_dirs{$`} = 1;
        $cleanup_makefile_dirs{$`} = 1 if -f "$`/Makefile.PL";
      }
    }

    $self->{MY_CLEANUP_MAKEFILE_DIRS} = [ keys %cleanup_makefile_dirs ];

    if (%c_extension_libs) {
      # have to re-write the DIR setting
      $self->{DIR} = %PL_dirs ? [ keys %PL_dirs ] : [ ];

      $self->{MY_EXTENSION_LIBS} = \%c_extension_libs;
      $self->{MY_EXTENSION_LIBS_IN_ORDER} = \@c_extension_libs;
      $self->{MYEXTLIB} = join(' ', @c_myextlib_replacement);
    }
  }

  $self->MM::init_xs;

  print STDERR "debug: my init_xs, ", join(',', sort keys %{ $self->{MY_XS_TARGETS} }), "\n" if $debugf;
  print STDERR "debug: my init_xs, before INST_DYNAMIC=$self->{INST_DYNAMIC}\n" if $debugf;

  if ($self->has_link_code) {
    if ($self->{MY_XS_TARGETS}) {
      my @so_targets;
      my @bs_targets;
      while (my ($xs, $place) = each %{ $self->{MY_XS_TARGETS} }) {
        $place =~ s/::/\//g;
        (my $basename = $place) =~ s/^.*\///;
        push @so_targets, $self->catdir('$(INST_ARCHLIB)', 'auto', $place, $basename.'.$(DLEXT)');
        push @bs_targets, $self->catdir('$(INST_ARCHLIB)', 'auto', $place, $basename.'.bs');
      }
      $self->{INST_DYNAMIC} = join(' ', @so_targets);
      $self->{INST_BOOT} = join(' ', @bs_targets);
    }
  }

  print STDERR "debug: my init_xs, after INST_DYNAMIC=$self->{INST_DYNAMIC}\n" if $debugf;
}

=head2 B<$obj->clean_subdirs>

This function is exported by the :MY tag.  It replaces the MM clean_subdirs.

This handles cleaning up subdirectories with their own Makefile, such
as Makefile.PL, Build.PL, and extension libraries.

=cut

sub clean_subdirs {
  my $self = shift;

  #$self->MM::clean_subdirs_target(@_);

  my $make = '
clean_subdirs :
';
  foreach my $subdir (@{ $self->{MY_CLEANUP_MAKEFILE_DIRS} } ) {
    $make .= '
	cd '.$subdir.' && $(MAKE) clean
';
  }

  return $make;
}

=head2 B<$obj->clean>

This function is exported by the :MY tag.  It extends the MM clean.

This handles cleaning up all the debris left by building .xs files,
without having to have the .c files named explicitly in the $self
XS setting.

=cut

sub clean {
  my ($self, %attribs) = @_;

  my $make = $self->MM::clean(%attribs);
  return $make unless $self->{XS};

  my @objects;
  while (my ($xs, $c_file) = each %{ $self->{XS} }) {
    (my $object = $c_file) =~ s/\.c$/\$(OBJ_EXT)/;
    (my $bootstrap = $c_file) =~ s/\.c$/.bs/;
    push @objects, "$object $bootstrap";
  }

  if (@objects) {
    my $objects = join(" \\\n\t  ", @objects);
    $make =~ s/\*\$\(OBJ_EXT\)/$& \\\n\t  $objects \\\n\t /;
  }

  return $make;
}

=head2 B<$obj->postamble>

This function is exported by the :MY tag.  It extends the MM postamble.

This handles setting up the compilation of the .xs files with a VERSION
for each.  The bootstrap code checks the VERSION, and it has to match.

=cut

sub postamble {
  my $self = shift;

  print STDERR "debug: my postamble, ", join(',', sort keys %{ $self->{MY_XS_TARGETS} }), "\n" if $debugf;
  print STDERR "debug: ", Data::Dumper::Dumper($self), "\n" if $debugf;

  my $make = '';
  foreach my $subdir (keys %{ $self->{MY_EXTENSION_LIBS} }) {
    foreach my $extlib (keys %{ $self->{MY_EXTENSION_LIBS}{$subdir} }) {
      $make .= '

'.$extlib.':
	BUILDDIR=`pwd`/; \
	cd '.$subdir.' && \
	$(MAKE) AR="$(FULL_AR)" ARFLAGS="$(AR_STATIC_ARGS)" RANLIB="$(RANLIB)" CC="$(CCCMD)" CPPFLAGS="-I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE)" CFLAGS="$(CCCDLFLAGS)" LD="$(LD)" LDFLAGS="$(LDDLFLAGS)" all

subdirs-test ::
	-BUILDDIR=`pwd`/; \
	cd '.$subdir.' && \
	$(MAKE) AR="$(FULL_AR)" ARFLAGS="$(AR_STATIC_ARGS)" RANLIB="$(RANLIB)" CC="$(CCCMD)" CPPFLAGS="-I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE)" CFLAGS="$(CCCDLFLAGS)" LD="$(LD)" LDFLAGS="$(LDDLFLAGS)" test

pure_perl_install ::
	-BUILDDIR=`pwd`/; \
	cd '.$subdir.' && \
	$(MAKE) AR="$(FULL_AR)" ARFLAGS="$(AR_STATIC_ARGS)" RANLIB="$(RANLIB)" CC="$(CCCMD)" CPPFLAGS="-I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE)" CFLAGS="$(CCCDLFLAGS)" LD="$(LD)" LDFLAGS="$(LDDLFLAGS)" \
	INSTALLPRIVLIB=$(DESTINSTALLPRIVLIB) INSTALLARCHLIB=$(DESTINSTALLARCHLIB) INSTALLBIN=$(DESTINSTALLBIN) INSTALLSCRIPT=$(DESTINSTALLSCRIPT) INSTALLMAN1DIR=$(DESTINSTALLMAN1DIR) INSTALLMAN3DIR=$(DESTINSTALLMAN3DIR) \
	install

pure_site_install ::
	-BUILDDIR=`pwd`/; \
	cd '.$subdir.' && \
	$(MAKE) AR="$(FULL_AR)" ARFLAGS="$(AR_STATIC_ARGS)" RANLIB="$(RANLIB)" CC="$(CCCMD)" CPPFLAGS="-I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE)" CFLAGS="$(CCCDLFLAGS)" LD="$(LD)" LDFLAGS="$(LDDLFLAGS)" \
	INSTALLPRIVLIB=$(DESTINSTALLSITELIB) INSTALLARCHLIB=$(DESTINSTALLSITEARCHLIB) INSTALLBIN=$(DESTINSTALLSITEBIN) INSTALLSCRIPT=$(DESTINSTALLSITESCRIPT) INSTALLMAN1DIR=$(DESTINSTALLSITEMAN1DIR) INSTALLMAN3DIR=$(DESTINSTALLSITEMAN3DIR) \
	install

pure_vendor_install ::
	-BUILDDIR=`pwd`/; \
	cd '.$subdir.' && \
	$(MAKE) AR="$(FULL_AR)" ARFLAGS="$(AR_STATIC_ARGS)" RANLIB="$(RANLIB)" CC="$(CCCMD)" CPPFLAGS="-I$(PERL_INC) $(PASTHRU_DEFINE) $(DEFINE)" CFLAGS="$(CCCDLFLAGS)" LD="$(LD)" LDFLAGS="$(LDDLFLAGS)" \
	INSTALLPRIVLIB=$(DESTINSTALLVENDORLIB) INSTALLARCHLIB=$(DESTINSTALLVENDORARCHLIB) INSTALLBIN=$(DESTINSTALLVENDORBIN) INSTALLSCRIPT=$(DESTINSTALLVENDORSCRIPT) INSTALLMAN1DIR=$(DESTINSTALLVENDORMAN1DIR) INSTALLMAN3DIR=$(DESTINSTALLVENDORMAN3DIR) \
	install
';

    }
  }
  
  return $make unless $self->{MY_XS_TARGETS};

  my @dirs;
  my @compile;
  while (my ($xs, $place) = each %{ $self->{MY_XS_TARGETS} }) {
    print STDERR "debug: postamble $xs $place\n" if $debugf;
    #next if $place eq $self->{NAME};

    (my $place_dir = $place) =~ s/::/\//g;
    (my $basename = $place_dir) =~ s/^.*\///;
    (my $object = $xs) =~ s/\..*?$/.o/;
    (my $c_file = $xs) =~ s/\..*?$/.c/;
    (my $xs_basename = $xs) =~ s/\..*?$//;
    (my $bootstrap = $xs) =~ s/\..*?$/.bs/;
    my $INST_ARCHAUTODIR = $self->catdir('$(INST_ARCHLIB)', 'auto', $place_dir);

    push @dirs, $INST_ARCHAUTODIR unless $place eq $self->{NAME};

    my $version = $self->parse_version("lib/${place_dir}.pm");
    print STDERR "debug: place_dir=$place_dir\n" if $debugf;
    print STDERR "debug: $place is $version\n" if $debugf;
    print STDERR "debug: CONST_CCCMD=$$self{CONST_CCCMD}\n" if $debugf;
    my $cccmd = $self->{CONST_CCCMD};
    $cccmd =~ s/^\s*CCCMD\s*=\s*//;
    $cccmd =~ s/\$\(DEFINE_VERSION\)/-DVERSION=\\"$version\\"/;
    $cccmd =~ s/\$\(XS_DEFINE_VERSION\)/-DXS_VERSION=\\"$version\\"/;
    print STDERR "debug: new CCCMD=$cccmd\n" if $debugf;

    my $tmp_str = '

'.$object.' : '.$xs.'
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c
	'.$cccmd.' $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -o $@ $*.c
';
    push @compile, $tmp_str;
  }

  my @exists = map { $_.'$(DFSEP).exists' } @dirs;

  $make .= sprintf <<'MAKE_FRAG', join(' ', @exists);

blibdirs : %s

MAKE_FRAG

  $make .= $self->dir_target(@dirs);
  $make .= join('', @compile);

  return $make;
}

=head2 B<$obj->dynamic_bs>

This function is exported by the :MY tag.  It extends the MM dynamic_bs.

This handles the .bs files for multiple non-chained .xs files.

=cut

sub dynamic_bs {
  my($self, %attribs) = @_;

  return $self->MM::dynamic_bs(%attribs) unless $self->{MY_XS_TARGETS};
  print STDERR "debug: my dynamic_bs, ", join(',', sort keys %{ $self->{MY_XS_TARGETS} }), "\n" if $debugf;

  return '
BOOTSTRAP =
' unless $self->has_link_code();

  my $str = '
BOOTSTRAP = $(BASEEXT).bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
';

  while (my ($xs, $place) = each %{ $self->{MY_XS_TARGETS} }) {
    $place =~ s/::/\//g;
    (my $basename = $place) =~ s/^.*\///;
    (my $object = $xs) =~ s/\..*?$/.o/;
    (my $xs_basename = $xs) =~ s/\..*?$//;
    (my $bootstrap = $xs) =~ s/\..*?$/.bs/;
    my $INST_ARCHAUTODIR = $self->catdir('$(INST_ARCHLIB)', 'auto', $place);
    my $install_target = $self->catdir($INST_ARCHAUTODIR, $basename.'.bs');
    my $exists = $self->catdir($INST_ARCHAUTODIR, '.exists');

    #my $make_target = $Is{VMS} ? '$(MMS$TARGET)' : '$@';
    my $make_target = '$@';

    my $tmp_str = '
'.$bootstrap.' : $(FIRST_MAKEFILE) $(BOOTDEP) '.$exists.'
	$(NOECHO) $(ECHO) "Running Mkbootstrap for '.$xs.' ($(BSLOADLIBS))"
	$(NOECHO) $(PERLRUN) "-MExtUtils::Mkbootstrap" -e "Mkbootstrap(\''.$xs_basename.'\',\'$(BSLOADLIBS)\');"
	$(NOECHO) $(TOUCH) %s
	$(CHMOD) $(PERM_RW) %s

'.$install_target.' : '.$bootstrap.' '.$exists.'
	$(NOECHO) $(RM_RF) %s
	- $(CP) '.$bootstrap.' %s
	$(CHMOD) $(PERM_RW) %s
';

    $str .= sprintf $tmp_str, ($make_target) x 5;
  }

  return $str;
}

=head2 B<$obj->dynamic_lib>

This function is exported by the :MY tag.  It extends the MM dynamic_lib.

This handles building multiple .xs files into .so.

=cut

sub dynamic_lib {
  my($self, %attribs) = @_;

  return $self->MM::dynamic_lib(%attribs) unless $self->{MY_XS_TARGETS};

  print STDERR "debug: my dynamic_lib, ", join(',', sort keys %{ $self->{MY_XS_TARGETS} }), "\n" if $debugf;

  return '' unless $self->needs_linking(); #might be because of a subdir

  return '' unless $self->has_link_code;

  my(@m);
  my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
  my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
  my($armaybe) = $attribs{ARMAYBE} || $self->{ARMAYBE} || ":";
  my($ldfrom) = '$(LDFROM)';
  $armaybe = 'ar' if ($Is{OSF} and $armaybe eq ':');
  my $ld_opt = $Is{OS2} ? '$(OPTIMIZE) ' : '';  # Useful on other systems too?
  my $ld_fix = $Is{OS2} ? '|| ( $(RM_F) $@ && sh -c false )' : '';
  push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = '.$armaybe.'
OTHERLDFLAGS = '.$ld_opt.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'
INST_DYNAMIC_FIX = '.$ld_fix.'
');
  while (my ($xs, $place) = each %{ $self->{MY_XS_TARGETS} }) {
    $place =~ s/::/\//g;
    (my $basename = $place) =~ s/^.*\///;
    (my $object = $xs) =~ s/\..*?$/.o/;
    (my $bootstrap = $xs) =~ s/\..*?$/.bs/;
    my $INST_ARCHAUTODIR = $self->catdir('$(INST_ARCHLIB)', 'auto', $place);
    my $target = $self->catdir($INST_ARCHAUTODIR, $basename.'.$(DLEXT)');
    my $exists = $self->catdir($INST_ARCHAUTODIR, '.exists');

    push(@m,'

'.$target.': '.$object.' $(MYEXTLIB) '.$bootstrap.' '.$exists.' $(EXPORT_LIST) $(PERL_ARCHIVE) $(PERL_ARCHIVE_AFTER) $(INST_DYNAMIC_DEP)
');

    if ($armaybe ne ':') {
      $ldfrom = 'tmp$(LIB_EXT)';
      push(@m,'	$(ARMAYBE) cr '.$ldfrom.' $(OBJECT)'."\n");
      push(@m,'	$(RANLIB) '."$ldfrom\n");
    }
    $ldfrom = "-all $ldfrom -none" if $Is{OSF};

    # The IRIX linker doesn't use LD_RUN_PATH
    my $ldrun = $Is{IRIX} && $self->{LD_RUN_PATH} ? '-rpath "'.$self->{LD_RUN_PATH}.'"' : '';

    # For example in AIX the shared objects/libraries from previous builds
    # linger quite a while in the shared dynalinker cache even when nobody
    # is using them.  This is painful if one for instance tries to restart
    # a failed build because the link command will fail unnecessarily 'cos
    # the shared object/library is 'busy'.
    push(@m,'	$(RM_F) $@
');

    my $libs = '$(LDLOADLIBS)';

    if (($Is{NetBSD} || $Is{Interix}) && $Config{'useshrplib'} eq 'true') {
      # Use nothing on static perl platforms, and to the flags needed
      # to link against the shared libperl library on shared perl
      # platforms.  We peek at lddlflags to see if we need -Wl,-R
      # or -R to add paths to the run-time library search path.
      if ($Config{'lddlflags'} =~ /-Wl,-R/) {
          $libs .= ' -L$(PERL_INC) -Wl,-R$(INSTALLARCHLIB)/CORE -Wl,-R$(PERL_ARCHLIB)/CORE -lperl';
      } elsif ($Config{'lddlflags'} =~ /-R/) {
          $libs .= ' -L$(PERL_INC) -R$(INSTALLARCHLIB)/CORE -R$(PERL_ARCHLIB)/CORE -lperl';
      }
  }

    my $ld_run_path_shell = "";
    if ($self->{LD_RUN_PATH} ne "") {
      $ld_run_path_shell = 'LD_RUN_PATH="$(LD_RUN_PATH)" ';
    }

    my @extlibs;
    push @extlibs, map { "-L$_" } sort keys %{ $self->{MY_EXTENSION_LIBS} };
    push @extlibs, map { "-l$_" } @{ $self->{MY_EXTENSION_LIBS_IN_ORDER} };

    push @m, sprintf <<'MAKE', $ld_run_path_shell, $ldrun, '$<', join(' ', @extlibs), $libs;
	%s$(LD) %s $(LDDLFLAGS) %s $(OTHERLDFLAGS) -o $@ %s	\
	  $(PERL_ARCHIVE) %s $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST)	\
	  $(INST_DYNAMIC_FIX)
MAKE

    push @m, <<'MAKE';
	$(CHMOD) $(PERM_RWX) $@
MAKE
  }

  return join('',@m);
}

1;

__END__

=head2 EXPORT

None by default.  Use the tags :find and :MY to export the useful things.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rob Janes, E<lt>edgewise@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Rob Janes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

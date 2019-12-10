# Copyright (C) 2010-2013 Torsten Schoenfeld <kaffeetisch@gmx.de>
#
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
#
# See the LICENSE file in the top-level directory of this distribution for the
# full license terms.

BEGIN { require 5.008; }

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Config;
use Cwd;

my %RUNTIME_REQ_PM = (
  'Glib' => 1.320,
);

my %CONFIG_REQ_PM = (
  'ExtUtils::Depends'   => 0.300,
  'ExtUtils::PkgConfig' => 1.000,
  'Glib'                => $RUNTIME_REQ_PM{Glib},
);

my %BUILD_REQ = (
  'gobject-introspection-1.0' => '0.10.0',
  'gmodule-2.0'               => '2.0.0',
  'libffi'                    => '3.0.0',
);

my @xs_files = qw(GObjectIntrospection.xs);
my %pm_files = (
  'lib/Glib/Object/Introspection.pm' => '$(INST_LIBDIR)/Introspection.pm',
);
my %pod_files = (
   'lib/Glib/Object/Introspection.pm'
     => '$(INST_MAN3DIR)/Glib::Object::Introspection.$(MAN3EXT)',
);
my @exe_files = qw(bin/perli11ndoc);

my %meta_merge = (
        q(meta-spec)          => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        author              =>
            ['Glib::Object::Introspection Team <gtk-perl-list at gnome dot org>'],
        #release_status      => 'unstable',
        release_status      => 'stable',
        # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
        license             => 'lgpl_2_1',
        resources => {
            license     => 'http://www.gnu.org/licenses/lgpl-2.1.html',
            homepage    => 'http://gtk2-perl.sourceforge.net',
            x_MailingList =>
                'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
            x_IRC => "irc://irc.gimp.org/#gtk-perl",
            bugtracker  => {
                    web     =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Glib-Object-Introspection',
                    mailto  => 'bug-Glib-Object-Introspection [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'git@gitlab.gnome.org:GNOME/perl-glib-object-introspection.git',
                    type    => 'git',
                    web     => 'https://gitlab.gnome.org/GNOME/perl-glib-object-introspection',
            },
        },
        prereqs => {
            configure => {
                requires => {%CONFIG_REQ_PM}, # no direct ref for 5.14 compatibility
            },
            runtime => {
                requires => {%RUNTIME_REQ_PM}, # no direct ref for 5.14 compatibility
            },
        },
        no_index => {
            file    => \@xs_files,
            package => [ 'MY', 'Glib::Object::Introspection::_FuncWrapper' ],
        },
);

my $dep_success = eval <<__EOE__;
  use ExtUtils::Depends $CONFIG_REQ_PM{'ExtUtils::Depends'};
  use ExtUtils::PkgConfig $CONFIG_REQ_PM{'ExtUtils::PkgConfig'};
  use Glib $CONFIG_REQ_PM{'Glib'};
  use Glib::MakeHelper;
  1;
__EOE__
if (!$dep_success) {
  warn $@;
  exit 0;
}

my %cfg;
my $cfg_success = eval {
  %cfg = ExtUtils::PkgConfig->find (
    "gobject-introspection-1.0 >= $BUILD_REQ{'gobject-introspection-1.0'}");
  1;
};
if (!$cfg_success) {
  warn $@;
  exit 0;
}

$cfg_success = eval {
  my %cfg_gmod = ExtUtils::PkgConfig->find (
    "gmodule-2.0 >= $BUILD_REQ{'gmodule-2.0'}");
  $cfg{cflags} .= " $cfg_gmod{cflags}";
  $cfg{libs} .= " $cfg_gmod{libs}";
  1;
};
if (!$cfg_success) {
  warn $@;
  exit 0;
}

$cfg_success = eval {
  my %cfg_ffi = ExtUtils::PkgConfig->find (
    "libffi >= $BUILD_REQ{'libffi'}");
  $cfg{cflags} .= " $cfg_ffi{cflags}";
  $cfg{libs} .= " $cfg_ffi{libs}";
  1;
};
if (!$cfg_success) {
  warn $@;
  exit 0;
}

mkdir 'build', 0777;

compile_test_libraries();

my $have_gi_1_60 = ExtUtils::PkgConfig->atleast_version('gobject-introspection-1.0', '1.60.0');
if (!$have_gi_1_60) {
  ExtUtils::PkgConfig->write_version_macros (
    "build/gi-version.h",
    "gobject-introspection-1.0" => "GI",
  );
}

my $deps = ExtUtils::Depends->new ('Glib::Object::Introspection' => 'Glib');
$deps->set_inc ($cfg{cflags});
$deps->set_libs ($cfg{libs});
$deps->add_pm (%pm_files);
$deps->add_xs (@xs_files);
$deps->save_config ('build/IFiles.pm');

WriteMakefile(
  NAME		=> 'Glib::Object::Introspection',
  VERSION_FROM	=> 'lib/Glib/Object/Introspection.pm',
  ABSTRACT_FROM	=> 'lib/Glib/Object/Introspection.pm',
  PREREQ_PM	=> \%CONFIG_REQ_PM,
  XSPROTOARG	=> '-noprototypes',
  MAN3PODS	=> \%pod_files,
  EXE_FILES     => \@exe_files,
  META_MERGE	=> \%meta_merge,
  $deps->get_makefile_vars,
);

sub compile_test_libraries {
  chdir 'build';
  my $build_dir = cwd();

  local $| = 1;
  print 'Trying to build test libraries... ';

  my $success = eval {
    my $lib_ext;
    if ( $^O =~ /darwin/ ) {
       $lib_ext = $Config{so};
    } else {
       $lib_ext = $Config{dlext};
    }
    my $gidatadir = ExtUtils::PkgConfig->variable ('gobject-introspection-1.0',
                                                   'gidatadir');
    die 'Could not find gobject-introspection-1.0' unless defined $gidatadir;
    my $testsdir = $gidatadir . '/tests';
    my $have_cairo_gobject = !system (qw/pkg-config --exists cairo-gobject/);
    my %cairo_flags = ExtUtils::PkgConfig->find ('cairo');
    my %cairo_gobject_flags = $have_cairo_gobject ?
      ExtUtils::PkgConfig->find ('cairo-gobject') :
      (cflags => '', libs => '');
    my %gio_flags = ExtUtils::PkgConfig->find ('gio-2.0');

    my @commands;
    my $c_flags = qq(-shared -fPIC);
    my $gir_cmd = qq(LD_LIBRARY_PATH=$build_dir:\$LD_LIBRARY_PATH g-ir-scanner);
    my $prefix = q();
    my $pipe = qq(1>/dev/null 2>/dev/null);

    if ($^O eq 'MSWin32') {
      my @path = File::Spec->path;
      my $found = 0;

      foreach my $base (map { File::Spec->catfile ($_, 'g-ir-scanner') } @path) {
        if (-f $base) {
          $gir_cmd = qq(python $base);
          $found = 1;
          last;
        }
      }

      return 0 unless $found;

      $c_flags = qq(-shared);
      $pipe = qq(1>NUL 2>NUL);
      # XXX: We need the lib prefix for --library argument to G-O-I on Win32,
      #      else DLL resolution fails...
      $prefix = 'lib';
    }

    push @commands,
         qq(gcc $c_flags -g \\
            $cairo_flags{cflags} $cairo_gobject_flags{cflags} $gio_flags{cflags} \\
            $testsdir/regress.c \\
            $cairo_flags{libs} $cairo_gobject_flags{libs} $gio_flags{libs} \\
            -o libregress.$lib_ext $pipe);
    push @commands,
         qq($gir_cmd \\
            --include=cairo-1.0 --include=Gio-2.0 \\
            --namespace=Regress --nsversion=1.0 \\
            --quiet --warn-all --warn-error \\
            --library=${prefix}regress \\
            --output=Regress-1.0.gir \\
            $testsdir/regress.h $testsdir/regress.c \\
            $pipe);
    push @commands,
         qq(g-ir-compiler Regress-1.0.gir -o Regress-1.0.typelib \\
            $pipe);
    push @commands,
         qq(gcc $c_flags -g \\
            $gio_flags{cflags} \\
            $testsdir/gimarshallingtests.c \\
            $gio_flags{libs} \\
            -o libgimarshallingtests.$lib_ext $pipe);
    push @commands,
         qq($gir_cmd \\
            --include=Gio-2.0 \\
            --namespace=GIMarshallingTests \\
            --symbol-prefix=gi_marshalling_tests --nsversion=1.0 \\
            --quiet --warn-all --warn-error \\
            --library=${prefix}gimarshallingtests \\
            --output=GIMarshallingTests-1.0.gir \\
            $testsdir/gimarshallingtests.h $testsdir/gimarshallingtests.c \\
            $pipe);
    push @commands,
         qq(g-ir-compiler GIMarshallingTests-1.0.gir \\
            -o GIMarshallingTests-1.0.typelib $pipe);

    if ($^O eq 'MSWin32') {
      my $path = $ENV{PATH};

      # XXX: G-O-I defaults to CC=cc
      $ENV{CC} = 'gcc' unless exists $ENV{CC};
      $ENV{PATH} .= ';' . $build_dir;

      foreach my $command (@commands) {
        # XXX: Cmd.exe do not support \ as line break ...
        $command =~ s/\\\n//mg;
        $command =~ s/\s\s+/ /mg;

        system ($command) == 0 or return 0;
      }

      $ENV{PATH} = $path;
    }
    else {
      foreach my $command (@commands) {
        system ($command) == 0 or return 0;
      }
    }

    1;
  };

  print $success ? "OK\n" : "not OK\n";
  if ($@) {
    print "Error: $@";
    print "Continuing without test library support...\n";
  }

  chdir '..';
}

package MY; # so that "SUPER" works right

sub test {
  my $inherited = shift->SUPER::test(@_);
  my $target = qr/test_dynamic :: (?:pure_all|subdirs-test_dynamic)\n\t/;
  if ($^O eq 'MSWin32') {
    # put "build" into PATH for the tests
    # FIXME: Might need tweaking for nmake...
    $inherited =~ s/($target)/.IMPORT: PATH\nPATH += ;build\n.EXPORT: PATH\n$1/;
  }
  else {
    # put "build" into LD_LIBRARY_PATH for the tests
    $inherited =~ s/($target)/${1}LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:build /;
  }
  $inherited;
}

sub postamble {
  my $additional_deps = "\n\n\$(OBJECT) : gperl-i11n-*.c\n\n";
  if ($^O eq 'MSWin32') {
    # FIXME: Might need tweaking for nmake...
    $additional_deps = "\n\n\$(OBJECT) : \$(wildcard gperl-i11n-*.c)\n\n";
  }
  return Glib::MakeHelper->postamble_clean () . $additional_deps;
}

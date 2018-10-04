# Copyright (C) 2003-2009, 2013 by the gtk2-perl team (see the file AUTHORS
# for the full list)
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
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

BEGIN { require 5.008; }

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Cwd;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'glib' => '2.0.0',
);
our %PREREQ_PM = (
	'ExtUtils::Depends'   => '0.300',
	'ExtUtils::PkgConfig' => '1.000',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$PREREQ_PM{'ExtUtils::Depends'}';"
           . "use ExtUtils::PkgConfig '$PREREQ_PM{'ExtUtils::PkgConfig'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         NAME         => 'Glib',
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%PREREQ_PM,
   );
   exit 1; # not reached
}

# client modules may use Glib::MakeHelper -- he's not installed at this
# point, so we have to require him directly.
require './lib/Glib/MakeHelper.pm';

mkdir 'build', 0777;

# If the package can't be found, warn and exit with status 0 to indicate to
# CPAN testers that their system is not supported.
my %glibcfg;
unless (eval { %glibcfg = ExtUtils::PkgConfig->find ("gobject-2.0 >= $build_reqs{glib}"); 1; })
{
	warn $@;
	exit 0;
}

# this is the order in which we want the api docs from the XS files to
# appear in Glib::xsapi
our @xs_files = qw(
	Glib.xs
	GError.xs
	GUtils.xs
	GLog.xs
	GType.xs
	GBoxed.xs
	GObject.xs
	GValue.xs
	GClosure.xs
	GSignal.xs
	GMainLoop.xs
	GIOChannel.xs
	GParamSpec.xs
);

# Check version before including
if (ExtUtils::PkgConfig->atleast_version ('glib-2.0', '2.6.0')) {
	push @xs_files, 'GKeyFile.xs';
	push @xs_files, 'GOption.xs';
}

if (ExtUtils::PkgConfig->atleast_version ('glib-2.0', '2.12.0')) {
	push @xs_files, 'GBookmarkFile.xs';
}

if (ExtUtils::PkgConfig->atleast_version ('glib-2.0', '2.24.0')) {
	push @xs_files, 'GVariant.xs';
}

my %meta_merge = (
        q(meta-spec)          => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        author              =>
            ['gtk2-perl Team <gtk-perl-list at gnome dot org>'],
        #release_status      => 'unstable',
        release_status      => 'stable',
        # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
        license             => 'lgpl_2_1',
        resources => {
            license       => 'http://www.gnu.org/licenses/lgpl-2.1.html',
            homepage      => 'http://gtk2-perl.sourceforge.net',
            x_IRC         => "irc://irc.gimp.org/#gtk-perl",
            x_MailingList =>
                'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
            bugtracker  => {
                    web     =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Glib',
                    mailto  => 'bug-Glib [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'git@gitlab.gnome.org:GNOME/perl-glib.git',
                    type    => 'git',
                    web     => 'https://gitlab.gnome.org/GNOME/perl-glib',
            },
        },
        prereqs => {
            configure => {
                requires => {%PREREQ_PM}, # no direct ref for 5.14 compatibility
            },
        },
        no_index => {
            file => [@xs_files, qw/Makefile.PL xsapi.pod.head xsapi.pod.foot/],
            package => 'MY',
        },
);

our %pm_files = (
     'lib/Glib.pm'                 => '$(INST_LIBDIR)/Glib.pm',
     'lib/Glib/Object/Subclass.pm' => '$(INST_LIBDIR)/Glib/Object/Subclass.pm',
     'lib/Glib/ParseXSDoc.pm'      => '$(INST_LIBDIR)/Glib/ParseXSDoc.pm',
     'lib/Glib/GenPod.pm'          => '$(INST_LIBDIR)/Glib/GenPod.pm',
     'lib/Glib/CodeGen.pm'         => '$(INST_LIBDIR)/Glib/CodeGen.pm',
     'lib/Glib/MakeHelper.pm'      => '$(INST_LIBDIR)/Glib/MakeHelper.pm',
     'devel.pod'                   => '$(INST_LIBDIR)/Glib/devel.pod',
);
our %pod_files = (
   'lib/Glib.pm'                 => '$(INST_MAN3DIR)/Glib.$(MAN3EXT)',
   'lib/Glib/Object/Subclass.pm' => '$(INST_MAN3DIR)/Glib::Object::Subclass.$(MAN3EXT)',
   'lib/Glib/ParseXSDoc.pm'      => '$(INST_MAN3DIR)/Glib::ParseXSDoc.$(MAN3EXT)',
   'lib/Glib/GenPod.pm'          => '$(INST_MAN3DIR)/Glib::GenPod.$(MAN3EXT)',
   'lib/Glib/CodeGen.pm'         => '$(INST_MAN3DIR)/Glib::CodeGen.$(MAN3EXT)',
   'lib/Glib/MakeHelper.pm'      => '$(INST_MAN3DIR)/Glib::MakeHelper.$(MAN3EXT)',
   'devel.pod'                        => '$(INST_MAN3DIR)/Glib::devel.$(MAN3EXT)',
   '$(INST_LIB)/$(FULLEXT)/xsapi.pod' => '$(INST_MAN3DIR)/Glib::xsapi.$(MAN3EXT)',
   Glib::MakeHelper->do_pod_files (@xs_files),
);

# optional thread-safety
my $nothreads;
if($Config::Config{usethreads}) {
	$nothreads = grep /disable[-_]threadsafe/i, @ARGV;
} else {
	$nothreads = 1;
}
my %gthreadcfg;
if (!$nothreads) {
	eval {
		%gthreadcfg = ExtUtils::PkgConfig->find ('gthread-2.0');
	};
	$nothreads = 1 if $@;
}
else
{
	warn " *** \n";
	warn " *** configuring Glib to build without thread safety\n";
	warn " *** \n";
	%gthreadcfg = (
		cflags => ' -DGPERL_DISABLE_THREADSAFE ',
		libs => '',
	);
}

our $glib = ExtUtils::Depends->new ('Glib');

# add -I. and -I./build to the include path so we can find our own files.
# this will be inherited by dependant modules, so they can find their
# generated files.
$glib->set_inc (' -I. ' . $glibcfg{cflags} . ' ' . $gthreadcfg{cflags});
$glib->set_libs ($glibcfg{libs} . ' ' . $gthreadcfg{libs});
my $cwd = cwd();
$glib->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'typemap');
$glib->add_pm (%pm_files);
$glib->add_xs (@xs_files);
$glib->add_c (qw(gperl-gtypes.c));
$glib->install (qw(gperl.h gperl_marshal.h doctypes));
$glib->save_config ('build/IFiles.pm');

# exports list needed for win32, unused on others
our @exports;
require './Glib.exports';

# On OpenBSD, any program that directly or indirectly wants to load
# libpthread.so must do so from the start.  But when perl is built without
# ithreads, it will also most likely not be compiled with "-pthread".  When
# libglib/libgobject then go and try to load libpthread.so, the loader will
# error out.
my @openbsd_compat_flags = ();
if ($^O eq 'openbsd' && $Config::Config{ldflags} !~ m/-pthread\b/) {
  warn " ***\n *** on OpenBSD, we either need perl linked with '-pthread',\n",
       " ***   or we need to set LD_PRELOAD=libpthread.so; doing the latter now...\n ***\n";
  @openbsd_compat_flags = (
    macro => {FULLPERLRUN => 'LD_PRELOAD=libpthread.so $(FULLPERL)'},
  );
}

WriteMakefile(
    NAME		=> 'Glib',
    VERSION_FROM	=> 'lib/Glib.pm', # finds $VERSION
    ABSTRACT_FROM	=> 'lib/Glib.pm', # retrieve abstract from module
    PREREQ_PM		=> \%PREREQ_PM,
    XSPROTOARG		=> '-noprototypes',
    MAN3PODS		=> $glib ? \%pod_files : {},
    FUNCLIST		=> \@exports,
    DL_FUNCS		=> { Glib => [] },
    META_MERGE		=> \%meta_merge,
    $glib ? $glib->get_makefile_vars : (),
    @openbsd_compat_flags,
);

=unstable

print <<__EOW__;
WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

   This is an unstable development release of Glib.  The API is not
   frozen and things are subject to change at any time.  Report any
   bugs to gtk-perl-list AT gnome DOT org as soon as possible.
   Please use the 1.32x series for important work.

WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
__EOW__

=cut

=frozen

print <<__EOW__;
WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

   This is an unstable development release of Glib.  The API is frozen in
   accordance with the GNOME 2.16 schedule.  Report any bugs to gtk-perl-list
   AT gnome DOT org as soon as possible.

WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
__EOW__

=cut

# rule to build the documentation
sub MY::postamble
{
	require './lib/Glib/MakeHelper.pm';
	# $glib will be undefined if any of our dependencies couldn't be found;
	# don't do anything in this case.
	return unless defined $glib;
	return "
# these are special for Glib since it's providing the modules,
# it just has to make sure that they are ready before it can go
build/doc.pl :: \$(INST_LIB)/Glib/ParseXSDoc.pm

build/podindex :: \$(INST_LIB)/Glib/GenPod.pm

\$(INST_LIB)/\$(FULLEXT)/xsapi.pod :: build/doc.pl apidoc.pl xsapi.pod.head xsapi.pod.foot
	\$(NOECHO) \$(ECHO) Creating XS API documentation...
	\$(NOECHO) \$(FULLPERLRUN) apidoc.pl xsapi.pod.head xsapi.pod.foot build/doc.pl > \$@

"
	     . Glib::MakeHelper->postamble_precompiled_headers (qw/gperl.h/)
	     . Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
			DEPENDS => $glib,
			DOCTYPES => 'doctypes',
			COPYRIGHT_FROM => 'copyright.pod',
	       )
	     . Glib::MakeHelper->postamble_rpms (
			'GLIB' => $build_reqs{'glib'},
			'PERL_EXTUTILS_DEPENDS' =>
				$PREREQ_PM{'ExtUtils::Depends'},
			'PERL_EXTUTILS_PKGCONFIG' =>
				$PREREQ_PM{'ExtUtils::PkgConfig'},
		);
}


__END__

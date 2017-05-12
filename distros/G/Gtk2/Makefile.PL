# Copyright (C) 2003-2011, 2013 by the gtk2-perl team (see the file AUTHORS
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
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

BEGIN { require 5.008; }

use strict;
use warnings;
# use only standard modules here!  any non-standard module, or anything which is
# a dependency which may not be installed, should be use'd from the dependency
# test eval, below.
use ExtUtils::MakeMaker;
use File::Spec;
use Cwd;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.300',
	'perl-ExtUtils-PkgConfig' => '1.030',
	'perl-Glib'               => '1.280',
	'perl-Pango'              => '1.220',
	'perl-Cairo'              => '1.000',
	'Gtk+'                    => '2.0.0',
);

our %PREREQ_PM = (
	'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
	'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
	'Glib'                => $build_reqs{'perl-Glib'},
	'Pango'               => $build_reqs{'perl-Pango'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;" # for do_pod_files()
           . "use Pango '$build_reqs{'perl-Pango'}';"
           . "1") {
	warn "$@\n";
	WriteMakefile(
		PREREQ_FATAL => 1,
		PREREQ_PM    => \%PREREQ_PM,
	);
	exit 1; # not reached
}

# other modules should 'use Gtk2::CodeGen;' -- we can't because it's not
# installed yet.
require './lib/Gtk2/CodeGen.pm';

# all the generated stuff will go into this subdir...
mkdir 'build', 0777;

#
# look for our packages.  if they can't be found, warn and exit with status 0
# to indicate to CPAN testers that their system isn't supported.
#
my %pkgcfg_gtk;
unless (eval { %pkgcfg_gtk = ExtUtils::PkgConfig->find ("gtk+-2.0 >= $build_reqs{'Gtk+'}");
                1; })
{
	warn $@;
	exit 0;
}

#
# retrieve gtk's version
#
my @gtk_version = split /\./, $pkgcfg_gtk{modversion};

#
# decide what files to use in the build based on the version we found.
#
our @xs_files = ();
our @xs_lists = (
	Glib::MakeHelper->select_files_by_version ("xs_files", @gtk_version),
);
foreach my $filename (@xs_lists) {
	my @names = Glib::MakeHelper->read_source_list_file ($filename);
	#print "Loaded ".scalar(@names)." xs files from $filename\n";
	push @xs_files, @names;
}
my $target = ExtUtils::PkgConfig->variable ('gtk+-2.0', 'target');
if ($target =~ /x11/) {
	push @xs_files, 'xs/GdkX11.xs';
}

# if gtk+ >= 2.8, we depend on Cairo
my $have_cairo = 0;
if ($gtk_version[0] > 2 || ($gtk_version[0] == 2 && $gtk_version[1] >= 8)) {
	$PREREQ_PM{Cairo} = $build_reqs{'perl-Cairo'};
	unless (eval "use Cairo '$build_reqs{'perl-Cairo'}'; 1;") {
		warn "$@\n";
		WriteMakefile(
			PREREQ_FATAL => 1,
			PREREQ_PM    => \%PREREQ_PM,
		);
		exit 1; # not reached
	}
	$have_cairo = 1;
}

#
# generate the constants wrappers
#
my @gtk_constants_lists =
	Glib::MakeHelper->select_files_by_version ('constants', @gtk_version);
my $gtk_constants_file = File::Spec->catfile ('build', 'constants.xs');
Gtk2::CodeGen->generate_constants_wrappers (
	prefix => 'Gtk2',
	lists => \@gtk_constants_lists,
	xs_file => $gtk_constants_file,
	header => 'gtk2perl.h',
        export_tag => 'constants');
push @xs_files, $gtk_constants_file;

#
# create version macros for atk
#
ExtUtils::PkgConfig->write_version_macros(
	"build/gtk2perl-versions.h",
	atk => "ATK",
);

#
# since we've started down the dark path of breaking from standard 
# MakeMaker, forever will it dominate our destiny; we must specify
# install paths for the modules and man files by hand.
#
our %pm_files = (
	'lib/Gtk2.pm'            => '$(INST_LIBDIR)/Gtk2.pm',
	'build/Keysyms.pm'       => '$(INST_LIBDIR)/Gtk2/Gdk/Keysyms.pm',
	'lib/Gtk2/CodeGen.pm'    => '$(INST_LIBDIR)/Gtk2/CodeGen.pm',
	'lib/Gtk2/Helper.pm'     => '$(INST_LIBDIR)/Gtk2/Helper.pm',
	'lib/Gtk2/Pango.pm'      => '$(INST_LIBDIR)/Gtk2/Pango.pm',
	'lib/Gtk2/SimpleList.pm' => '$(INST_LIBDIR)/Gtk2/SimpleList.pm',
	'lib/Gtk2/SimpleMenu.pm' => '$(INST_LIBDIR)/Gtk2/SimpleMenu.pm',
	'lib/Gtk2/TestHelper.pm' => '$(INST_LIBDIR)/Gtk2/TestHelper.pm',
	'lib/Gtk2/api.pod'       => '$(INST_LIBDIR)/Gtk2/api.pod',
	'lib/Gtk2/devel.pod'     => '$(INST_LIBDIR)/Gtk2/devel.pod',
);
our %pod_files = (
	'lib/Gtk2.pm'            => '$(INST_MAN3DIR)/Gtk2.$(MAN3EXT)',
	# Keysyms is generated by Makefile.PL.
	'build/Keysyms.pm'       => '$(INST_MAN3DIR)/Gtk2::Gdk::Keysyms.$(MAN3EXT)',
	'lib/Gtk2/CodeGen.pm'    => '$(INST_MAN3DIR)/Gtk2::CodeGen.$(MAN3EXT)',
	'lib/Gtk2/Helper.pm'     => '$(INST_MAN3DIR)/Gtk2::Helper.$(MAN3EXT)',
	'lib/Gtk2/Pango.pm'      => '$(INST_MAN3DIR)/Gtk2::Pango.$(MAN3EXT)',
	'lib/Gtk2/SimpleList.pm' => '$(INST_MAN3DIR)/Gtk2::SimpleList.$(MAN3EXT)',
	'lib/Gtk2/SimpleMenu.pm' => '$(INST_MAN3DIR)/Gtk2::SimpleMenu.$(MAN3EXT)',
	'lib/Gtk2/api.pod'       => '$(INST_MAN3DIR)/Gtk2::api.$(MAN3EXT)',
	'lib/Gtk2/devel.pod'     => '$(INST_MAN3DIR)/Gtk2::devel.$(MAN3EXT)',
	# enums.pod is generated by rules we add to the postamble, below.
	# it is generated straight into blib to avoid dependency problems.
	'$(INST_LIB)/$(FULLEXT)/enums.pod'
	                   => '$(INST_MAN3DIR)/Gtk2::enums.$(MAN3EXT)',
	# we will be installing a whole slew of pod files generated directly
	# from the xs source -- but to have them installed and manified
	# properly, we have to know their names at Makefile.PL time.
	#   This is a bit of a chicken and egg problem, and this solution
	# basically means that if you create a new package name in the xs
	# code, you'll need to re-run Makefile.PL.  you already need to
	# re-run to pick up new XS files, so that's not such a big deal. 
	Glib::MakeHelper->do_pod_files (@xs_files),
);

if (grep /enable[-_]faq/i, @ARGV)
{
	print STDERR "Including FAQ in pod, retrieved from Gtk2-Perl site.\n";
	# Writing a fake Makefile ensures that CPAN will pick up the correct
	# dependencies and install them.
	unless (eval "use LWP; 1")
	{
	   warn "$@\n";
	   WriteMakefile(
	         PREREQ_FATAL => 1,
	         PREREQ_PM    => {
	            'LWP' => 0.1,
	         },
	   );
	   exit 1; # not reached
	}
	require 'tools/fetch_faq.pl';
	$pm_files{'build/FAQ.pod'} = '$(INST_LIBDIR)/Gtk2/FAQ.pod';
	$pod_files{'build/FAQ.pod'} = '$(INST_MAN3DIR)/Gtk2::devel.$(MAN3EXT)';
}

#
# autogeneration
#
# we have a whole lot of types which need cast macros, typemap entries,
# and package mapping registration; instead of writing this by hand, we
# use a set of map files which define how things are laid out, and then use
# some boilerplate code to convert those mappings into a header, typemap,
# and xsh file.  see the docs for Gtk2::CodeGen for more info.
#
# all possible maps must be available at xsubpp time, as xsubpp processes
# all code, even inside #ifdefs.
#
# For backwards compatibility, the pango maps must be included so that the
# Gtk2::Pango::* names are registered with Glib.  These maps have special types
# (GObjectAlias, for example) that are handled by our own Gtk2::CodeGen.
#
Gtk2::CodeGen->parse_maps ('gtk2perl', input => [<maps-[0-9]\.[0-9]*>,
                                                 <maps_pango-[0-9]\.[0-9]*>]);
# but for enums.pod, we only want to document the stuff we can actually
# query from this target library.
our @used_maps = Glib::MakeHelper->select_files_by_version ("maps", @gtk_version);

# one more command generates code to boot all the various extra XS modules.
# we need this because we have lots of XS files without corresponding PMs to
# bootstrap them.
Gtk2::CodeGen->write_boot (xs_files => \@xs_files);

# this one turns the long list of #defines in gdkkeysyms.h into a large
# hash of key names and values, %Gtk2::Gdk::Keysyms.
system "$^X tools/genkeysyms.pl >\"build/Keysyms.pm\""; # the "" are essential for command.com

#
# now we're ready to start creating the makefile... finally.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.
#

my @deps = qw/Glib Pango/;
if ($have_cairo) {
  push @deps, qw/Cairo/;
}
our $gtk2 = ExtUtils::Depends->new ('Gtk2', @deps);

# Glib added -I. for us, but we'll need to add -I./build so we can get to
# the autogenerated files.  we do this kindof as a public service to client
# modules, as these will carry through via the depends mechanism.
$gtk2->set_inc ($pkgcfg_gtk{cflags} . ' -I./build ');
$gtk2->set_libs ($pkgcfg_gtk{libs});
$gtk2->add_pm (%pm_files);
$gtk2->add_xs (@xs_files);
my $cwd = cwd();
$gtk2->add_typemaps (map {File::Spec->catfile($cwd,$_)}
		     'build/gtk2perl.typemap',
                     'gdk.typemap', 'gtk.typemap');

$gtk2->install (qw(gtk2perl.h
                   build/gtk2perl-autogen.h
		   build/gtk2perl-versions.h
		   doctypes));
$gtk2->save_config ('build/IFiles.pm');

# exports list needed for win32, unused on others
our @exports;
require './Gtk2.exports';

my %meta_merge = (
        q(meta-spec)          => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        author              =>
            ['gtk2-perl Team <gtk-perl-list at gnome dot org>'],
        release_status      => 'stable',
        # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
        license             => 'lgpl_2_1',
        resources => {
            license     => 'http://www.gnu.org/licenses/lgpl-2.1.html',
            homepage    => 'http://gtk2-perl.sourceforge.net',
            x_MailingList =>
                'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
            bugtracker  => {
                    web     =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Gtk2',
                    mailto  => 'bug-Gtk2 [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'git://git.gnome.org/perl-Gtk2',
                    type    => 'git',
                    web     => 'http://git.gnome.org/browse/perl-Gtk2',
            },
        },
        prereqs => {
            configure => {
                requires => {%PREREQ_PM}, # no direct ref for 5.14 compatibility
            },
        },
        no_index           => {
            directory => [qw/tools xs/],
            file      => [qw|Makefile.PL gtk-demo/main.pl|],
        },
);


WriteMakefile(
    NAME          => 'Gtk2',
    VERSION_FROM  => 'lib/Gtk2.pm', # finds $VERSION
    ABSTRACT_FROM => 'lib/Gtk2.pm', # retrieve abstract from module
    PREREQ_PM     => \%PREREQ_PM,
    XSPROTOARG    => '-noprototypes',
    MAN3PODS      => \%pod_files,
    FUNCLIST      => \@exports,
    DL_FUNCS      => { Gtk2 => [] },
    META_MERGE    => \%meta_merge,
    $gtk2->get_makefile_vars,
);

=unstable

print <<__EOW__;
WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

   This is an unstable development release of Gtk2.  The API is not
   frozen and things are subject to change at any time.  Report any
   bugs to gtk-perl-list AT gnome DOT org as soon as possible.
   Please use the 1.22x series for important work.

WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
__EOW__

=cut

=frozen

print <<__EOW__;
WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

   This is an unstable development release of Gtk2.  The API is frozen in
   accordance with the GNOME 2.16 schedule.  Report any bugs to gtk-perl-list
   AT gnome DOT org as soon as possible.  Please use the 1.12x series for
   important work.

WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
__EOW__

=cut

#
# extra makefile override stuff... watch for falling wizardry.
#

sub MY::postamble
{
	my $text = "POD_DEPENDS=build/stock_items.podi\n\n"
	         . Glib::MakeHelper->postamble_precompiled_headers (qw/gtk2perl.h/)
		 . Glib::MakeHelper->postamble_clean ()
	         . Glib::MakeHelper->postamble_docs_full (
			DEPENDS => $gtk2,
			DOCTYPES => 'doctypes',
			COPYRIGHT_FROM => 'copyright.pod',
	           )
	         . Glib::MakeHelper->postamble_rpms (
			'GTK' => $build_reqs{'Gtk+'},
			'PERL_EXTUTILS_DEPENDS' => 
				$build_reqs{'perl-ExtUtils-Depends'},
			'PERL_EXTUTILS_PKGCONFIG' => 
				$build_reqs{'perl-ExtUtils-PkgConfig'},
			'PERL_GLIB' => $build_reqs{'perl-Glib'},
			'PERL_PANGO' => $build_reqs{'perl-Pango'},
	           )
	         . " 
# rebuild the makefile if the file lists change
Makefile : ".join(" ", @xs_lists)."

\$(INST_LIB)/\$(FULLEXT)/enums.pod : \$(BLIB_DONE) @used_maps tools/podifyenums.pl
	\$(NOECHO) \$(ECHO) Creating enum POD...
	\$(NOECHO) \$(PERLRUNINST) -M\$(NAME) tools/podifyenums.pl \$(NAME) @used_maps > \$@

build/stock_items.podi: \$(BLIB_DONE) tools/podifystockitems.pl
	\$(NOECHO) \$(ECHO) Creating stock items POD...
	\$(NOECHO) \$(PERLRUNINST) -M\$(NAME) tools/podifystockitems.pl > \$@

build/FAQ.pod: tools/fetch_faq.pl
	$^X \$<
";

	# this installation stuff doesn't make sense on windows, where
	# we don't really have a /usr.  also, nmake barfs on $+.
	unless ($^O eq 'MSWin32') {
		$text .= "
# the tmp-xxx stuff is just so that only the pl files get installed
install-\%: %
	\@\$(MKPATH) tmp-\$+/
	\@\$(CP) \$+/*.* tmp-\$+/
	\@\$(MOD_INSTALL) ./tmp-\$+/ \\
		\$(PREFIX)/share/doc/perl-\$(DISTNAME)/\$+
	\@\$(RM_RF) tmp-\$+/
";
	}

	return $text;
}

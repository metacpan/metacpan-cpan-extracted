#
# $Id$
#

use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.1',
	'perl-ExtUtils-PkgConfig' => '0.1',
	'perl-Glib'               => '1.24',
	'perl-Gtk2'               => '1.00',
	'GtkSpell'                => '2.0.0',
);

our %pre_reqs = (
   'Glib'                => $build_reqs{'perl-Glib'},
   'Gtk2'                => $build_reqs{'perl-Gtk2'},
   'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
   'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);
# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
	   . "use Glib::MakeHelper;"
	   . "use Gtk2::CodeGen;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%pre_reqs,
   );
   exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find('gtkspell-2.0 >= '
				       .$build_reqs{GtkSpell});

mkdir 'build', 0777;

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

$gtk2spell = ExtUtils::Depends->new ('GtkSpell', 'Gtk2', 'Glib');
$gtk2spell->set_inc ($pkgcfg{cflags});
$gtk2spell->set_libs ($pkgcfg{libs});
$gtk2spell->add_pm ('lib/Gtk2/Spell.pm' => '$(INST_LIBDIR)/Spell.pm');
$gtk2spell->add_xs ('GtkSpell.xs');
my $cwd = cwd();
$gtk2spell->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'gtkspell.typemap' );

$gtk2spell->install ('gtk2spellperl.h');
$gtk2spell->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::Spell',
    VERSION_FROM  => 'lib/Gtk2/Spell.pm',
    PREREQ_PM     => \%pre_reqs,
    ABSTRACT_FROM => 'lib/Gtk2/Spell.pm',
    META_MERGE    => {
        configure_requires => \%pre_reqs,
        x_deprecated       => 1,
    },
    XSPROTOARG    => '-noprototypes',
    $gtk2spell->get_makefile_vars,
);

use Cwd;


print <<__EON__;
NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-spell
* Upstream URL: http://gtkspell.sourceforge.net/
* Last upstream version: 2.0.16
* Last upstream release date: 2009-10-22
* Migration path for this module: G:O:I
* Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs (@main::xs_files)
	     . Glib::MakeHelper->postamble_rpms (
		'GTKSPELL' => $build_reqs{'GtkSpell'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}

__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, see <https://www.gnu.org/licenses/>.

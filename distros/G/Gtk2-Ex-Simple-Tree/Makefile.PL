#
# $Header: /cvsroot/gtk2-perl-ex/Gtk2-Ex/Simple/Tree/Makefile.PL,v 1.1.1.1 2004/10/21 00:00:58 rwmcfa1 Exp $
#

use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'perl-Gtk2'                => '1.060',
	'perl-Gtk2-Ex-Simple-List' => '0.01',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use Glib::MakeHelper; use Gtk2; 1")
{
	warn "$@\n";
	WriteMakefile(
		PREREQ_FATAL => 1,
		PREREQ_PM    =>
		{
			'Glib' => '1.00',
			'Gtk2' => '1.00',
			'Gtk2::Ex::Simple::List' => '0.01',
		},
	);
	exit 1; # not reached
}

WriteMakefile(
	NAME            => 'Gtk2::Ex::Simple::Tree',
	VERSION_FROM    => 'lib/Gtk2/Ex/Simple/Tree.pm',
	ABSTRACT_FROM   => 'lib/Gtk2/Ex/Simple/Tree.pm',
);

package MY;

# rule to build the documentation
sub postamble 
{
	my $text = Glib::MakeHelper->postamble_clean ()
		 . Glib::MakeHelper->postamble_rpms (
			'PERL_GTK' => $build_reqs{'perl-Gtk2'},
			'PERL_GTK_EX_SIMPLE_LIST' => 
				$build_reqs{'perl-Gtk2-Ex-Simple-List'},
		   );
	
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

1;
__END__

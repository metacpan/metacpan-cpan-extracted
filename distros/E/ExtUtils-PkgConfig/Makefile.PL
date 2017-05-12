BEGIN { require 5.006; }

use ExtUtils::MakeMaker;

# don't go any further if pkg-config cannot be found.
my $have_pkg_config = `pkg-config --version`;

if ($have_pkg_config eq "") {
	# Warn and exit with status 0 to indicate (to the user and the CPAN
	# testers infrastructure) that this module won't work on this machine.
	warn <<"__EOW__";
***
*** ExtUtils::PkgConfig requires the pkg-config utility, but it doesn't
*** seem to be in your PATH.  Is it correctly installed?
***  PATH=$ENV{PATH}
***
__EOW__
	exit 0;
}

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
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=ExtUtils-PkgConfig',
                    mailto  => 'bug-ExtUtils-PkgConfig [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'git://git.gnome.org/perl-ExtUtils-PkgConfig',
                    type    => 'git',
                    web     => 'http://git.gnome.org/browse/perl-ExtUtils-PkgConfig',
            },
        },
);

WriteMakefile(
    'NAME' => 'ExtUtils::PkgConfig',
    'VERSION_FROM' => 'lib/ExtUtils/PkgConfig.pm',
    # FIXME this doesn't work very well with native win32 perl
    'dist' => {
           PREOP    => 'pod2text lib/ExtUtils/PkgConfig.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
           COMPRESS => 'gzip -9v',
           SUFFIX   => '.gz',
    },
    'META_MERGE'    => \%meta_merge,
);

use Cwd;

sub MY::postamble
{
	# none of this rpm stuff is useful on win32, and actually it can cause
	# nmake to barf.
	return "" if $^O eq 'MSWin32';

	my @dirs = qw{$(RPMS_DIR) $(RPMS_DIR)/BUILD $(RPMS_DIR)/RPMS
		      $(RPMS_DIR)/SOURCES $(RPMS_DIR)/SPECS $(RPMS_DIR)/SRPMS};
	my $cwd = getcwd();

	chomp (my $date = `date +"%a %b %d %Y"`);

	my %subs = (
		'VERSION' => '$(VERSION)',
		'SOURCE' => '$(DISTNAME)-$(VERSION).tar.gz',
		'DATE'    => $date,
	);

	my $substitute = '$(PERL) -npe \''.join('; ', map {
			"s/\\\@$_\\\@/$subs{$_}/g";
		} keys %subs).'\'';

"
realclean ::
	-\$(RM_F) perl-\$(DISTNAME).spec

RPMS_DIR=\$(HOME)/rpms

\$(RPMS_DIR)/:
	-mkdir @dirs

SUBSTITUTE=$substitute

perl-\$(DISTNAME).spec :: perl-\$(DISTNAME).spec.in \$(VERSION_FROM) Makefile
	\$(SUBSTITUTE) \$< > \$@

dist-rpms :: Makefile dist perl-\$(DISTNAME).spec \$(RPMS_DIR)/
	cp \$(DISTNAME)-\$(VERSION).tar.gz \$(RPMS_DIR)/SOURCES/
	rpmbuild -ba --define \"_topdir \$(RPMS_DIR)\" perl-\$(DISTNAME).spec

dist-srpms :: Makefile dist perl-\$(DISTNAME).spec \$(RPMS_DIR)/
	cp \$(DISTNAME)-\$(VERSION).tar.gz \$(RPMS_DIR)/SOURCES/
	rpmbuild -bs --nodeps --define \"_topdir \$(RPMS_DIR)\" perl-\$(DISTNAME).spec
"
}

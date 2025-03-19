#!/usr/bin/perl

# We require 5.6 for sanity in general, and for 'our' in particular.
use 5.006;

use ExtUtils::MakeMaker;
my %prereqs = (
	'File::Spec' => 0,
	'Data::Dumper' => 0,
	'IO::File' => 0,
	'ExtUtils::MakeMaker' => '7.44', # no need for Win32 static_lib hack
);

my %meta_merge = (
    q(meta-spec)          => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    author              =>
        ['Gtk2-Perl Team <gtk-perl-list at gnome dot org>'],
    release_status      => 'stable',
    # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
    license             => 'perl_5',
    resources => {
        license     => 'http://dev.perl.org/licenses/',
        homepage    => 'http://gtk2-perl.sourceforge.net',
        x_MailingList =>
            'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
        bugtracker  => {
            web     =>
                'http://rt.cpan.org/Public/Dist/Display.html?Name=ExtUtils-Depends',
            mailto  => 'bug-ExtUtils-Depends [at] rt.cpan.org',
        },
        repository  => {
            url     => 'git://git.gnome.org/perl-ExtUtils-Depends',
            type    => 'git',
            web     => 'http://git.gnome.org/browse/perl-ExtUtils-Depends',
        },
    },
    prereqs => {
        configure => {
            requires => {%prereqs}, # no direct ref for 5.14 compatibility
        },
        test => {
            requires => {
                'Test::More' => '0.88', # done_testing
            },
            recommends => {
                'Test::Number::Delta' => 1.0,
            },
        },
    },
    keywords => ['XS', 'XS extensions', 'dependency'],
);

WriteMakefile(
	dist => {
		$^O eq 'MSWin32'
			? ()
			: (PREOP => 'pod2text lib/ExtUtils/Depends.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;'),
		COMPRESS => 'gzip -9v',
		SUFFIX => '.gz',
	},
	NAME => 'ExtUtils::Depends',
	VERSION_FROM => 'lib/ExtUtils/Depends.pm',
	PREREQ_PM => \%prereqs,
	MIN_PERL_VERSION => 5.006, #for META.yml
	META_MERGE => \%meta_merge,
	LICENSE => 'perl',
);

use Cwd;

sub MY::postamble
{
	# none of this rpm stuff is useful on win32, and actually it can cause
	# nmake to barf.
	return @_ if $^O eq 'MSWin32';

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
	rpmbuild -bs --define \"_topdir \$(RPMS_DIR)\" perl-\$(DISTNAME).spec
"
}

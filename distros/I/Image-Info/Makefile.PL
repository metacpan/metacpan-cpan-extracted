#!/usr/bin/env perl
# -*- cperl -*-
#############################################################################

require 5.006;
use strict;
use ExtUtils::MakeMaker;

my $is_author_env = defined $ENV{USER} && $ENV{USER} =~ m{^(eserte|slavenr)}; # fill in the developer's user names here
if ($is_author_env) {
    require File::Compare;
    require File::Temp;
    my($tmpfh,$tmpfile) = File::Temp::tempfile(SUFFIX => '.pm', UNLINK => 1);
    system("./dev/build.pl", "-o", $tmpfile);
    if (File::Compare::compare($tmpfile, 'lib/Image/Info.pm') != 0) {
        warn <<EOF;
**********************************************************************
*** WARNING
***
*** Changes in dev/Info.pm.tmpl detected, please run dev/build.pl!
***
**********************************************************************

EOF
    }

    *MY::postamble = sub {
	<<EOF;
predist:
	./dev/build.pl
	rm -rf inc
	\$(PERL) Makefile.PL
	\$(MAKE) distcheck
	\$(MAKE) disttest
	\$(MAKE) distclean
	\$(PERL) Makefile.PL
	git status
	\$(NOECHO) \$(ECHO) "*** Consider also calling cpan_check_versions and"
	\$(NOECHO) \$(ECHO) "*** cpan_check_unauthorized (on an older version)"

postdist:
	\$(NOECHO) \$(ECHO) "*** Run the following commands:"
	\$(NOECHO) \$(ECHO) cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	\$(NOECHO) \$(ECHO) "git tag -a -m '* \$(VERSION)' \$(VERSION)"
	\$(NOECHO) \$(ECHO) git push
	\$(NOECHO) \$(ECHO) git push --tags

EOF
    };
}

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;
if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
	      AUTHOR => 'Slaven Rezic <srezic@cpan.org>',
	      # previous authors:
	      # - Gisle Aas <gisle@ActiveState.com
	      # - Tels
	      NAME          => 'Image::Info',
	      VERSION_FROM  => 'lib/Image/Info.pm',
	      ABSTRACT_FROM => 'lib/Image/Info.pm',
	      PREREQ_PM     => {
				# PerlIO::scalar 0.21 appears first in perl 5.21.7
				(!eval { require PerlIO::scalar; PerlIO::scalar->VERSION(0.21) } ? ('IO::Scalar' => 0) : ()),
			       },
	      LICENSE       => 'perl',
	      MIN_PERL_VERSION => 5.006,
	      SIGN          => 1,

	      ($eumm_recent_enough
	       ? (META_MERGE => { resources  => { repository => 'git://github.com/eserte/image-info.git' },
				  no_index   => { directory => [qw(dev img xt)] },
				  recommends => {
						 'Bundle::Image::Info::PNG' => 0,
						 'Bundle::Image::Info::XPM' => 0,
						 'Bundle::Image::Info::XBM' => 0,
						 'Bundle::Image::Info::SVG' => 0,
						},
				  author     => ['Gisle Aas <gisle@ActiveState.com', 'Tels'],
				},
		  META_ADD   => {
				},
		 )
	       : ()
	      ),
);

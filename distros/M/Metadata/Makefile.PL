# Hey emacs, this is -*- perl -*- !
# $Id: Makefile.PL,v 1.12 2001/01/09 12:05:07 cmdjb Exp $

require 5.004;

use ExtUtils::MakeMaker;

$::VERSION='0.24';


# Do not change
$::VERSION_SYM=$::VERSION;
$::VERSION_SYM=~ s/\./_/g;

#--- Installation check

sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 $| = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 warn $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

#--- Check for TimeDate

chk_version(Date::Format => 2.07) or
    warn  "\n"
	. "Metadata::IAFA routine set_date_as_seconds uses Date::Format version 2.07 \n"
        . "or later which is part of the TimeDate module 1.07 or later\n"
	. "Look on CPAN for CPAN/modules/by-author/id/GBARR/TimeDate-x.xx.tar.gz\n\n";

chk_version(Date::Parse => 2.06) or
    warn  "\n"
	. "Metadata::IAFA routine get_date_as_seconds uses Date::Parse version 2.06 \n"
	. "or later which is part of the TimeDate module 1.07 or later\n"
	. "Look on CPAN for CPAN/modules/by-author/id/GBARR/TimeDate-x.xx.tar.gz\n\n";

#--- Write the Makefile

WriteMakefile(
  NAME         => 'Metadata',
  VERSION      => $::VERSION,

  dist         => { COMPRESS => 'gzip',
                    SUFFIX   => '.gz', 
                  },
);

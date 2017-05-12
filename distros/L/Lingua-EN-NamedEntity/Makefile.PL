#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib );
use ExtUtils::MakeMaker;
$|++;

WriteMakefile(
	      NAME              => 'Lingua::EN::NamedEntity',
	      VERSION_FROM      => 'NamedEntity.pm', # finds $VERSION
	      PREREQ_PM         => { DB_File => 0,
				     'Lingua::Stem::En' => 0,
				     'IO::Zlib' => 0,
				   },
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => 'NamedEntity.pm',
		AUTHOR         => 'Alberto Simoes') : ()),
	     );



package MY;

sub postamble {
      return <<"EOF";
database: pm_to_blib
\t\$(PERL) ./data/mkdb.pl
\t\$(NOECHO) \$(TOUCH) \$@

clean_database:
\t\$(NOECHO) \$(RM_F) database

EOF
}

sub top_targets {
    my $class = shift;
    my $makefragment = $class->SUPER::top_targets(@_);
    $makefragment =~ s/^(pure_all ::)/$1 database/m;
    return $makefragment;
}
 
sub clean {
    my $class = shift;
    my $makefragment = $class->SUPER::clean(@_);
    $makefragment =~ s/^(clean ::)/$1 clean_database/m;
    return $makefragment;
}

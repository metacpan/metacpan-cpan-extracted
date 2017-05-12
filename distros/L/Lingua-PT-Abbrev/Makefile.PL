require 5.006001; 
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::PT::Abbrev',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/PT/Abbrev.pm',
    ABSTRACT_FROM       => 'lib/Lingua/PT/Abbrev.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-PT-Abbrev-*' },
);



package MY;

sub postamble {
      return <<"EOF";
database: pm_to_blib data/abbrev.dat
\tperl ./data/cpdata.pl
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


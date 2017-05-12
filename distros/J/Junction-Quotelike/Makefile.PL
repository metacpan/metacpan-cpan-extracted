use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Junction::Quotelike',
    AUTHOR              => q{blackhat.blade <blade@dropfknuck.net>},
    VERSION_FROM        => 'lib/Junction/Quotelike.pm',
    ABSTRACT_FROM       => 'lib/Junction/Quotelike.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'artistic')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'PerlX::QuoteOperator' => 0.01,
        'Perl6::Junction'      => 1.40000,
        
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Junction-Quotelike-*' },
);

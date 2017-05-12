
use ExtUtils::MakeMaker;
use 5.000;
use strict;
use warnings;
my %requires = (
                 'Sort::DataTypes'          => '3.00',
                 'Storable'                 => '0',
                 'Text::Balanced'           => '0',
                 'Test::Inter'              => '0',
               );


WriteMakefile(
        NAME             => 'List::Parseable',
        VERSION          => '1.06',
        ($] >= 5.000
        ? (ABSTRACT=>'routines to work with lists containing a simple language',
           AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
        : ()),
        'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
        PREREQ_PM => \%requires,
);

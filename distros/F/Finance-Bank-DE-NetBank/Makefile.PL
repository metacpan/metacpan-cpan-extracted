require 5.6.1;
use ExtUtils::MakeMaker qw( WriteMakefile );
use File::Spec;
use strict;

my $enable_livetest = grep /--livetest/i, @ARGV;

my @tests = glob File::Spec->catfile( 't', '*.t' );
push( @tests, glob File::Spec->catfile( 't', 'methods', '*.t' ) );
push( @tests, glob File::Spec->catfile( 't', 'methods', 'live', '*.t' ) ) if $enable_livetest;

my $params = {
    NAME          => 'Finance::Bank::DE::NetBank',
    ABSTRACT_FROM => 'lib/Finance/Bank/DE/NetBank.pm', # retrieve abstract from module
    VERSION_FROM  => 'lib/Finance/Bank/DE/NetBank.pm', # finds $VERSION
    AUTHOR        => 'Roland Moriz (rmoriz@cpan.org)',
    PREREQ_PM    => {	
        "WWW::Mechanize"    => "1.16",
        "Class::Accessor"   => "0.22",
        "Text::CSV_XS"      => "0.23",
        "Net::SSLeay"       => "1.25",	

    },	      
    test            => { TESTS => join( " ", @tests ) },
};

# modules only for testing
if ($enable_livetest) {
    $params->{'PREREQ_PM'}{'Test::Differences'} = "";
    $params->{'PREREQ_PM'}{'DateTime'}          = "0.31";
}    


if (MM->can('signature_target')) {
    $params->{'SIGN'} = 1;
}

WriteMakefile( %$params );

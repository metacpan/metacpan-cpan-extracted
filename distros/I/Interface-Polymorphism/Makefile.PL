use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'interface',    
    'DISTNAME'     => 'Interface-Polymorphism',
    'VERSION_FROM' => 'lib/ex/interface.pm',
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts { AUTHOR }   = 'Piers Cawley <pdcawley@bofh.org.uk>';
    $opts { ABSTRACT } =
        'Perl 6 RFC 265ish interface polymorphism now';
}

WriteMakefile ( %opts )

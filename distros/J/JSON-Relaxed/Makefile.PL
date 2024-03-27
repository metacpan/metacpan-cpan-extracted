#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.24;
my ($make_args);

# WriteMakefile params
$make_args = {
		MIN_PERL_VERSION => '5.026000',
               'PL_FILES' => {},
               'NAME' => 'JSON::Relaxed',
               'PREREQ_PM' => {
                                'Test::More' => '0'
                              },
               'ABSTRACT' => 'JSON::Relaxed -- An extension of JSON that allows for better human-readability.',
               'AUTHOR' => 'Johan Vromans <jv@span.org>',
               'VERSION_FROM' => 'lib/JSON/Relaxed.pm',
               'EXE_FILES' => [],
               'LICENSE' => 'perl'
             };


WriteMakefile(%$make_args);

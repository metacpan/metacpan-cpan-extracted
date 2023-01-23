use 5.008;
# Based on earlier h2xs output and
# output from Module::Build::Compat version 0.03
use strict;
use warnings;
use File::Spec;
use ExtUtils::MakeMaker 7.36;
my $EUMM_REQUIRES = { 'ExtUtils::MakeMaker' => 7.36 };
# ExtUtils::MakeMaker
# if an output file depends on extra input files beside the 
# script itself, a hash ref can be used in version 7.36 and above

my $has_os = eval { require Perl::OSType; };
warn "No Perl::OSType\n" unless ($has_os or $] < 5.014);
my $is_win = ( $has_os ? Perl::OSType::is_os_type('Windows') 
                        : $INC{'ExtUtils/MM_Win32.pm'} );
my $script = File::Spec->catfile( 'script',
                $is_win ? 'file-rename' : 'rename' );
my $unsafe = File::Spec->catfile( 'script',
                                    'unsafe-rename');
my $source = File::Spec->catfile( 'source', 'rename');
                               
WriteMakefile(
          NAME          => 'File::Rename',
          VERSION_FROM  => 'lib/File/Rename.pm',
          INSTALLDIRS   => 'site',
          PREREQ_PM     => {
            'Getopt::Long'  => 2.24,    # for posix_default
          },
          BUILD_REQUIRES        => $EUMM_REQUIRES,
          CONFIGURE_REQUIRES    => $EUMM_REQUIRES,
          TEST_REQUIRES => {
            'File::Temp'    => 0,   # for testing
            'Test::More'    => 0,   # for testing(!)
          },
          EXE_FILES     => [ $script, $unsafe ],
          PL_FILES      => { 'rename.PL' => {$script => $source},
                             'unsafe.PL' => {$unsafe => $source},
                        },
          ABSTRACT_FROM => 'lib/File/Rename.pm',
                            # retrieve abstract from module
          AUTHOR        => 'Robin Barker <RMBarker@cpan.org>',
          LICENSE       => 'perl',
    
          NORECURS      => 1,
          test          => { RECURSIVE_TEST_FILES => 1 },
          MIN_PERL_VERSION  => 5.008,
);

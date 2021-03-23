# Based on earlier h2xs output and
# output from Module::Build::Compat version 0.03
use strict;
use File::Spec;
use ExtUtils::MakeMaker;

my $has_os = eval { require Perl::OSType; };
warn "No Perl::OSType\n" unless ($has_os or $] < 5.014);
my $is_win = ( $has_os ? Perl::OSType::is_os_type('Windows') 
		 	: $INC{'ExtUtils/MM_Win32.pm'} );
my $script = File::Spec->catfile( 'script',
			$is_win ? 'file-rename' : 'rename' );

WriteMakefile(
          NAME		=> 'File::Rename',
          VERSION_FROM	=> 'lib/File/Rename.pm',
          INSTALLDIRS	=> 'site',
          PREREQ_PM	=> {
		'Getopt::Long'	=> 0,	# recommend 2.24 for posix_default
		'File::Temp'	=> 0,	# for testing
		'Test::More'	=> 0,	# for testing(!)
	  },
          EXE_FILES	=> [ $script ],
	  PL_FILES	=> { 'rename.PL' => $script },
	  ABSTRACT_FROM	=> 'lib/File/Rename.pm',
					# retrieve abstract from module
	  AUTHOR     	=> 'Robin Barker <RMBarker@cpan.org>',

	  NORECURS	=> 1,
);

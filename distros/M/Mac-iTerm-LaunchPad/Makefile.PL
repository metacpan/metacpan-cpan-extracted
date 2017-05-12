# $Id: Makefile.PL 2499 2008-01-18 09:58:03Z comdog $
use ExtUtils::MakeMaker;

unless( $^O =~ /darwin/ )
	{
	warn "OS unsupported! You need a Mac for this module!\n";
	exit 0;
	}

require 5.006;

eval "use Test::Manifest 1.14";

sub MY::postamble 
	{
	<<'MAKE';
install :: new-iterm-install
	
new-iterm-install:
	$(ECHO) "Installing new-iterm symlink to module"
	/bin/ln -sfv $(INSTALLSITELIB)/Mac/iTerm/LaunchPad.pm $(INSTALLBIN)/new-iterm 
	$(CHMOD) 755 $(INSTALLSITELIB)/Mac/iTerm/LaunchPad.pm
MAKE
	}
	
WriteMakefile(
	'NAME'	       => 'Mac::iTerm::LaunchPad',
	'ABSTRACT'     => 'Launch new iTerm windows and tabs',
	'VERSION_FROM' => 'lib/LaunchPad.pm',
	'LICENSE'	   => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'     => '0',
		'Mac::Files'     => '0',
		'Mac::Glue'      => '1.28',
		'Mac::Processes' => '0',
		},

	'PM'           => {
		'lib/LaunchPad.pm'         => '$(INST_LIBDIR)/LaunchPad.pm',
		},

	'MAN3PODS'     => {
		'lib/LaunchPad.pm' => '$(INST_MAN3DIR)/Mac::iTerm::LaunchPad.3',
		},

	clean  => { FILES    => q|Mac-iTerm-LaunchPad-*| },

	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# An auto installer should already have installed Mac::Glue
{
require Mac::Glue;

my $iterm = eval { Mac::Glue->new( 'iTerm' ) };

if( $@ ) 
	{
	require Mac::Processes; Mac::Processes->import;
	
	my $iterm_path = LSFindApplicationForInfo( undef, undef, 'iTerm.app' );

	if( $iterm_path ) 
		{
		print <<"HERE";
To create the Mac::Glue bindings for iTerm you need to run:

	sudo gluemac $iterm_path

HERE

		print "Would you like to run this now? (y/N) ";

		chomp( my $confirm = <> );

		if( lc( $confirm ) eq 'y' ) 
			{
			system 'sudo', 'gluemac', $iterm_path;
			$iterm = eval { Mac::Glue->new( 'iTerm' ) };
			}
		}
	else
		{
		die "Could not find iTerm. Ensure you have it and try again\n";
		}
	}

unless( defined $iterm )
	{
	die "Cannot continue: Ensure that the iTerm glue for Mac::Glue is installed\n";
	}

}

1;
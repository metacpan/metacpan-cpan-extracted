package Mac::iTerm::LaunchPad;
use strict;
use warnings;

=encoding utf8

=head1 The build file for Mac::iTerm::LaunchPad

This build file is a modulino; it works as both a build script and
a module.

To build the distribution, run this file normally:

	% perl Makefile.PL

But, it's more interesting than that. You can load it with C<require>
and call C<arguments> to get the data structure it passes to
C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module. Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

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

use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/CPAN-Adoptable-Modules/mac-term-launchpad';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.008',

	'NAME'	        => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'	    => 'artistic_2',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More' => '0.94',
		},

	'PREREQ_PM'     => {
		'Mac::Files'     => '0',
		'Mac::Glue'      => '1.28',
		'Mac::Processes' => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		},

	clean => { FILES => "$dist-*" },
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# An auto installer should already have installed Mac::Glue
sub mac_glue {
	# XXX: you have to figure this out on your own:
	warn "You need to fix the Makefile.PL to make this work";
	return 1;

	unless( $^O =~ /darwin/ ) {
		warn "OS unsupported! You need a Mac for this module!\n";
		exit 0;
		}

	require Mac::Glue;

	my $iterm = eval { Mac::Glue->new( 'iTerm' ) };

	if( $@ ) {
		require Mac::Processes; Mac::Processes->import;

		my $iterm_path = LSFindApplicationForInfo( undef, undef, 'iTerm.app' );

		if( $iterm_path ) {
			print <<"HERE";
	To create the Mac::Glue bindings for iTerm you need to run:

		sudo gluemac $iterm_path

HERE

			print "Would you like to run this now? (y/N) ";

			chomp( my $confirm = <> );

			if( lc( $confirm ) eq 'y' ) {
				system 'sudo', 'gluemac', $iterm_path;
				$iterm = eval { Mac::Glue->new( 'iTerm' ) };
				}
			}
		else
			{
			die "Could not find iTerm. Ensure you have it and try again\n";
			}
		}

	unless( defined $iterm ) {
		die "Cannot continue: Ensure that the iTerm glue for Mac::Glue is installed\n";
		}

	}

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	mac_glue();

	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	WriteMakefile( %$arguments );
	}


no warnings;
__PACKAGE__;

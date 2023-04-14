#!perl
use v5.26;

use Test::More 1;

eval 'use Module::Extract::DeclaredMinimumPerl';
plan skip_all => 'Module::Extract::DeclaredMinimumPerl required for this test' if $@;

use Mojo::Util qw(dumper);
use Perl::Version;

diag( <<"HERE" );
	Module:   @{[ module_minimum()   ]}
	Makefile: @{[ makefile_minimum() ]}
HERE

ok( makefile_minimum() == module_minimum(), "Makefile version matches module version" )
	or diag( "Makefile: @{[makefile_minimum()]} Module: @{[module_minimum()]}" );

done_testing();

# Get the declared versions from the modules
sub module_minimum {
	state $ff = require File::Find;
	state $min_version = undef;

	return $min_version if defined $min_version;

	my @pm_files = ();
	my $wanted = sub {
		push @pm_files, $File::Find::name if $File::Find::name =~ /\.pm\z/;
		};
	File::Find::find( $wanted, 'lib' );

	my $extor = Module::Extract::DeclaredMinimumPerl->new;

	( $min_version ) =
		map { $_->[1] }
		sort { $a->[1] <=> $b->[1] }
		map { [ $_, $extor->get_minimum_declared_perl( $_ )->numify ] }
		@pm_files;

	return $min_version // '5.008';
	}

# Get the declared version from the Makefile.PL
sub makefile_minimum {
	state $min_version = undef;

	return $min_version if defined $min_version;

	delete $INC{'./Makefile.PL'};
	my $package = require './Makefile.PL';
	my $makefile_args = $package->arguments;
	my $declared = $makefile_args->{MIN_PERL_VERSION};
	$min_version = Perl::Version->new( $declared // '5.008' );

	return $min_version;
	}

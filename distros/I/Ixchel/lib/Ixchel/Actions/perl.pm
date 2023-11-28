package Ixchel::Actions::perl;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::perl_module_via_pkg;
use Ixchel::functions::install_cpanm;

=head1 NAME

Ixchel::Actions::perl :: Handles making sure desired Perl modules are installed as specified by the config.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'perl', opts=>{}'});

The modules to be installed are determined by the config.

    - .perl.cpanm :: Always install cpanm even if all modules could
            be installed via packages.
        - Default :: 0

    - .perl.modules :: Array of modules to install.
        - Default :: []

    - .perl.pkgs_always_try :: If .perl.modules should first try to be installed
          via packages.
        - Default :: 1

    - .perl.pkgs_optional :: An array of modules that can optionally be installed via
          via packages. This is only meaningful if .perl.pkgs_always_try is set to 0,
          meaning .perl.modules is only being handled via cpanm.
        - Default :: []

    - .perl.pkgs_require :: An array of modules that must be install via packages and
          will not later be tried via cpanm.
        - Default :: []

=head1 FLAGS

==head2 --notest

When calling cpanm, add --notest to it.

==head2 --reinstall

When calling cpanm, add --reinstall to it.

==head2 --force

When calling cpanm, add --force to it.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
	};
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	if ( defined( $opts{t} ) ) {
		$self->{t} = $opts{t};
	} else {
		die('$opts{t} is undef');
	}

	if ( defined( $opts{share_dir} ) ) {
		$self->{share_dir} = $opts{share_dir};
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	if ( defined( $opts{argv} ) ) {
		$self->{argv} = $opts{argv};
	}

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	# if we've already installed cpanm or not
	my $installed_cpanm = 0;
	if ( $self->{config}{perl}{cpanm} ) {
		eval {
			install_cpanm;
			$installed_cpanm = 1;
		};
		if ($@) {
			$self->status_add( status => 'Failed to install cpanm via packages ... ' . $@, error => 1 );
		} else {
			$self->status_add( status => 'cpanm installed' );
		}
	} ## end if ( $self->{config}{perl}{cpanm} )

	# a list of modules installed
	my %installed;
	my %tried_via_packages;

	$self->status_add( status => 'pkgs_require: ' . join( ',', @{ $self->{config}{perl}{pkgs_require} } ), );

	# handle ones that must be installed via pkgs
	if ( ref( $self->{config}{perl}{pkgs_require} ) eq 'ARRAY' ) {
		$self->status_add( status => 'pkgs_require: ' . join( ',', @{ $self->{config}{perl}{pkgs_require} } ), );
		foreach my $module ( @{ $self->{config}{perl}{pkgs_require} } ) {
			my $status;
			eval { $status = perl_module_via_pkg( module => $module ); };
			if ($@) {
				$self->status_add(
					status => 'Failed to install ' . $module . ' via packages',
					error  => 1
				);
				$tried_via_packages{$module} = 1;
			} else {
				$self->{results}{status_text} = $self->{results}{status_text} . $status;
				$self->status_add( status => $module . ' installed' );
				$installed{$module} = 1;
			}
		} ## end foreach my $module ( @{ $self->{config}{perl}{pkgs_require...}})
	} ## end if ( ref( $self->{config}{perl}{pkgs_require...}))

	# a list of modules to install
	my @modules;

	# handle ones that must be installed via pkgs
	if ( ref( $self->{config}{perl}{pkgs_optional} ) eq 'ARRAY' ) {
		$self->status_add( status => 'pkgs_optional: ' . join( ',', @{ $self->{config}{perl}{pkgs_require} } ), );
		foreach my $module ( @{ $self->{config}{perl}{pkgs_optional} } ) {
			my $status;
			eval { $status = perl_module_via_pkg( module => $module ); };
			if ($@) {
				# not an error here as it using packages is optional and will be used later.
				push( @modules, $module );
				$self->status_add(
					status => 'Failed to install ' . $module . ' via packages',
					error  => 0
				);
				$tried_via_packages{$module} = 1;
			} else {
				$self->{results}{status_text} = $self->{results}{status_text} . $status;
				$self->status_add( status => $module . ' installed' );
				$installed{$module} = 1;
			}
		} ## end foreach my $module ( @{ $self->{config}{perl}{pkgs_optional...}})
	} ## end if ( ref( $self->{config}{perl}{pkgs_optional...}))

	if ( ref( $self->{config}{perl}{modules} ) eq 'ARRAY' ) {
		push( @modules, @{ $self->{config}{perl}{modules} } );
	}

	$self->status_add( status => 'modules: ' . join( ',', @modules ) );

	foreach my $module (@modules) {
		if (   $self->{config}{perl}{pkgs_always_try}
			&& !defined( $installed{$module} )
			&& !defined( $tried_via_packages{$module} ) )
		{
			my $status;
			eval { $status = perl_module_via_pkg( module => $module ); };
			if ($@) {
				# not an error here as it using packages is optional and will be used later.
				push( @modules, $module );
				$self->status_add(
					status => 'Failed to install ' . $module . ' via packages',
					error  => 0
				);
			} else {
				$self->{results}{status_text} = $self->{results}{status_text} . $status;
				$self->status_add( status => $module . ' installed' );
				$installed{$module} = 1;
			}
		} ## end if ( $self->{config}{perl}{pkgs_always_try...})

		# if not already installed, try it via cpanm
		if ( !defined( $installed{$module} ) ) {
			if ( !$installed_cpanm ) {
				eval {
					install_cpanm;
					$installed_cpanm = 1;
				};
				if ($@) {
					$self->status_add( status => 'Failed to install cpanm via packages ... ' . $@, error => 1 );
					# can't proceced beyond here as cpanm is required
					return $self->{results};
				} else {
					$self->status_add( status => 'cpanm installed' );
				}
			} ## end if ( !$installed_cpanm )

			#
			my @cpanm_args = ('cpanm');
			if ( $self->{opts}{notest} ) {
				push( @cpanm_args, '--notest' );
			}
			if ( $self->{opts}{reinstall} ) {
				push( @cpanm_args, '--reinstall' );
			}
			if ( $self->{opts}{force} ) {
				push( @cpanm_args, '--force' );
			}
			push( @cpanm_args, $module );
			$self->status_add( status => 'running... ' . join( ' ', @cpanm_args ), );
			system(@cpanm_args);
			if ( $? != 0 ) {
				$self->status_add(
					status => 'cpanm failed: ' . join( ' ', @cpanm_args ),
					error  => 1,
				);
			} else {
				$installed{$module} = 1;
			}

		} ## end if ( !defined( $installed{$module} ) )
	} ## end foreach my $module (@modules)

	return $self->{results};
} ## end sub action

sub help {
	return 'Install Perl modules specified by the config.


--notest      When calling cpanm, add --notest to it.

--reinstall   When calling cpanm, add --reinstall to it.

--force       When calling cpanm, add --force to it.
';
} ## end sub help

sub short {
	return 'Install Perl modules specified by the config.';
}

sub opts_data {
	return '
notest
force
reinstall
';
}

sub status_add {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = 'perl';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	print $status. "\n";

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

1;

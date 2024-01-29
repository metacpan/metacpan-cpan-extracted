package Ixchel::Actions::pkgs;

use 5.006;
use strict;
use warnings;
use Rex::Commands::Pkg;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::pkgs - Handles making sure desired packages are installed as specified by the config.

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 CLI SYNOPSIS

ixchel -a pkgs

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'pkgs', opts=>{}'});

    if ($results->{ok}) {
        print $results->{filled_in};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

The modules to be installed are determined by the config.

    - .pkgs.latest :: Packages to ensure that are installed and up to date, updating if needed.
       - Default :: []

    - .pkgs.present :: Packages to ensure that are installed, installing if not needed. Will not update
            the package if it is installed an update is available.
        - Default :: []

    - .pkgs.absent :: Packages to ensure that are not installed, uninstalling if present.
        - Default :: []

=head1 FLAGS

None.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $latest = '';
	my @latest_failed;
	my @latest_handled;
	my $present = '';
	my @present_failed;
	my @present_handled;
	my $absent = '';
	my @absent_failed;
	my @absent_handled;

	if ( ref( $self->{config}{pkgs}{latest} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{latest}[0] ) ) {
		$latest = join( ', ', @{ $self->{config}{pkgs}{latest} } );
		$self->status_add( status => 'Starting Latest: ' . $latest );
		foreach my $pkg ( @{ $self->{config}{pkgs}{latest} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is latest..' );
			eval { pkg( $pkg, ensure => 'latest' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @latest_failed, $pkg );
			} else {
				push( @latest_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{latest...}})
	} ## end if ( ref( $self->{config}{pkgs}{latest} ) ...)

	if ( ref( $self->{config}{pkgs}{present} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{present}[0] ) ) {
		$present = join( ', ', @{ $self->{config}{pkgs}{present} } );
		$self->status_add( status => 'Starting Present: ' . $present );
		foreach my $pkg ( @{ $self->{config}{pkgs}{present} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is present...' );
			eval { pkg( $pkg, ensure => 'present' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @present_failed, $pkg );
			} else {
				push( @present_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{present...}})
	} ## end if ( ref( $self->{config}{pkgs}{present} )...)

	if ( ref( $self->{config}{pkgs}{absent} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{absent}[0] ) ) {
		$absent = join( ', ', @{ $self->{config}{pkgs}{absent} } );
		$self->status_add( status => 'Starting Absent: ' . $absent );
		foreach my $pkg ( @{ $self->{config}{pkgs}{absent} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is absent...' );
			eval { pkg( $pkg, ensure => 'absent' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @absent_failed, $pkg );
			} else {
				push( @absent_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{absent...}})
	} ## end if ( ref( $self->{config}{pkgs}{absent} ) ...)

	$self->status_add( status => 'Latest: ' . $latest );
	$self->status_add( status => 'Latest Handled: ' . join( ', ', @latest_handled ) );
	$self->status_add( status => 'Latest Failed: ' . join( ', ', @latest_failed ) );
	$self->status_add( status => 'Present: ' . join( ', ', @{ $self->{config}{pkgs}{present} } ) );
	$self->status_add( status => 'Present Handled: ' . $present );
	$self->status_add( status => 'Present Failed: ' . join( ', ', @present_failed ) );
	$self->status_add( status => 'Absent: ' . $absent );
	$self->status_add( status => 'Absent Handled: ' . join( ', ', @absent_handled ) );
	$self->status_add( status => 'Absent Failed: ' . join( ', ', @absent_failed ) );

	return undef;
} ## end sub action_extra

sub short {
	return 'Install packages specified by the config.';
}

sub opts_data {
	return '
';
}

1;

package Ixchel::Actions::snmp_extends;

use 5.006;
use strict;
use warnings;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::snmp_extends - List or install/update SNMP extends

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a snmp_extends B<-l>

ixchel -a snmp_extends B<-u>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'', opts=>{u=>1});

=head1 FLAGS

=head2 -l

List the extends enabled.

=head2 -u

Update or install extends.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( !$self->{opts}{l} && !$self->{opts}{u} ) {
		$self->status_add( error => 1, status => 'Neither -l or -u specified' );
		return undef;
	} elsif ( $self->{opts}{l} && $self->{opts}{u} ) {
		$self->status_add( error => 1, status => 'Both -l and -u specified' );
		return undef;
	}

	if ( $self->{opts}{l} ) {
		my @extends = keys( %{ $self->{config}{snmp}{extends} } );
		my @enabled;
		my @disabled;
		foreach my $item (@extends) {
			if ( $self->{config}{snmp}{extends}{$item}{enable} ) {
				push( @enabled, $item );
			} else {
				push( @disabled, $item );
			}
		}
		$self->status_add( status => 'Currently Enabled: ' . join( ',', @enabled ) );
		$self->status_add( status => 'Currently Disabled: ' . join( ',', @disabled ) );
	} ## end if ( $self->{opts}{l} )

	if ( $self->{opts}{u} ) {
		my @extends = keys( %{ $self->{config}{snmp}{extends} } );
		my @disabled;
		my @errored;
		my @installed;
		push( @extends, 'distro' );
		foreach my $item (@extends) {
			if ( $self->{config}{snmp}{extends}{$item}{enable} ) {
				my $results;
				my $error = 0;
				$self->status_add( status => 'Calling xeno for librenms/extends/' . $item );
				eval {
					$results
						= $self->{ixchel}->action( action => 'xeno', opts => { r => 'librenms/extends/' . $item } );
				};
				if ( $@ || !defined($results) || defined( $results->{errors}[0] ) ) {
					$error = 1;
					use Data::Dumper;
					print Dumper($results);
					$self->status_add(
						np     => 1,
						error  => $error,
						status => 'Errored installing/updating librenms/extends/' . $item
					);
					push( @errored, $item );
				} else {
					push( @installed, $item );
				}
			} else {
				push( @disabled, $item );
			}
		} ## end foreach my $item (@extends)
		$self->status_add( status => 'Currently Disabled: ' . join( ',', @disabled ) );
		$self->status_add( status => 'Installed/Updated: ' . join( ',', @installed ) );
		$self->status_add( status => 'Errored: ' . join( ',', @errored ) );
	} ## end if ( $self->{opts}{u} )

	return undef;
} ## end sub action_extra

sub short {
	return 'List or install/update SNMP extends';
}

sub opts_data {
	return '
l
u
';
}

1;

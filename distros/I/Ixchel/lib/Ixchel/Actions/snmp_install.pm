package Ixchel::Actions::snmp_install;

use 5.006;
use strict;
use warnings;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;
use base 'Ixchel::Actions::base';

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::Actions::snmp_install - Installs snmpd and snmp utils.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'snmp_install', opts=>{});

    print Dumper($results);

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	$self->status_add( status => 'Installing snmp utils and snmpd' );

	my @depends = ();

	if ( is_freebsd || is_netbsd || is_freebsd ) {
		$self->status_add( status => 'OS Family FreeBSD, NetBSD, or OpenBSD detectected' );
		push( @depends, 'net-snmp' );
	} elsif (is_debian) {
		$self->status_add( status => 'OS Family Debian detectected' );
		push( @depends, 'snmp', 'snmpd' );
	} elsif ( is_redhat || is_arch || is_suse || is_alt || is_mageia ) {
		$self->status_add( status => 'OS Family Redhat, Arch, Suse, Alt, or Mageia detectected' );
		push( @depends, 'net-snmp' );
	}

	$self->status_add( status => 'Packages: ' . join( ', ' . @depends ) );

	my @failed;
	my @installed;

	foreach my $pkg (@depends) {
		eval { pkg( $pkg, ensure => 'present' ); };
		if ($@) {
			$self->status_add( status => 'Installing ' . $pkg . ' failed... ' . $@, error => 1 );
			push( @failed, $pkg );
		} else {
			$self->status_add( status => 'Installed ' . $pkg );
			push( @installed, $pkg );
		}
	} ## end foreach my $pkg (@depends)

	$self->status_add( status => 'Failed: ' . join( ', ', @failed ), error => 1 );
	$self->status_add( status => 'Installed: ' . join( ', ', @installed ) );

	return undef;
} ## end sub action_extra

sub short {
	return 'Installs snmpd and snmp utils.';
}

sub opts_data {
	return '
';
}

1;

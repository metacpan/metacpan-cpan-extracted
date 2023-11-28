package Ixchel::Actions::systemd_auto_list;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ixchel::Actions::systemd_auto_list :: List systemd auto generated services.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    my @systemd_auto_units=$ixchel->action(action=>'systemd_auto_list', opts=>{np=>1}, );

Returns configured automatically generated systemd units.

=head1 SWITCHES

=head2 --np

Do not print anything. For use if calling this directly instead of via the cli tool.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
		ixchel => $opts{ixchel},
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

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	my @services = keys( %{ $self->{config}{systemd}{auto} } );

	if ( !$self->{opts}{np} ) {
		print join( "\n", @services );
		if ( defined( $services[0] ) ) {
			print "\n";
		}
	}

	return @services;
} ## end sub action

sub help {
	return 'List systemd auto generated services.

--np    Do not print anything.
';
}

sub short {
	return 'List systemd auto generated services.';
}

sub opts_data {
	return 'np
';
}

1;

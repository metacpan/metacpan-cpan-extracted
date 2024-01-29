package Ixchel::Actions::systemd_auto_list;

use 5.006;
use strict;
use warnings;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::systemd_auto_list - List systemd auto generated services.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a <systemd_auto_list>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'systemd_auto_list', opts=>{np=>1}, );

    if ($results->{ok}) {
        print 'Service: '.joined(', ', @{ $results->{services} })."\n";
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

Returns configured automatically generated systemd units.

=head1 SWITCHES

=head2 --np

Do not print anything. For use if calling this directly instead of via the cli tool.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .services :: A array of services.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my @services = keys( %{ $self->{config}{systemd}{auto} } );

	if ( !$self->{opts}{np} ) {
		print join( "\n", @services );
		if ( defined( $services[0] ) ) {
			print "\n";
		}
	}

	$self->{results}{services} = \@services;

	return undef;
} ## end sub action_extra

sub short {
	return 'List systemd auto generated services.';
}

sub opts_data {
	return 'np
';
}

1;

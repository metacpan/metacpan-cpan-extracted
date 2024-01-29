package Ixchel::Actions::snmp_v2;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::snmp_v2 - Generates a config file SNMPD.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a snmp_v2

ixchel -a snmp_v2 B<-w> [B<-o> <file>] [B<--np>]

=head1 CODE SYNOPSIS

    my $filled_in=$ixchel->action(action=>'snmp_v2', opts=>{w=>1});

    print $filled_in;

=head1 DESCRIPTION

The template used is 'snmp_v2'.

The returned value is the filled in template..

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/snmpd.conf

Linux Default :: /etc/snmp/snmpd.conf

=head2 --np

Don't print the the filled in template.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .filled_in :: The filled in template.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{o} ) ) {
		$self->{opts}{o} = $self->{config}{snmp}{config_file};
	}

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{w} ) ) {
		$self->{opts}{w} = 0;
	}

	my $filled_in;
	eval {
		$filled_in = $self->{ixchel}->action(
			action => 'template',
			vars   => {},
			opts   => {
				np => 1,
				t  => 'snmp_v2',
			},
		);
	};
	if ($@) {
		$self->status_add(
			error  => 1,
			status => 'Filling in the template failed... ' . $@
		);
		return undef;
	}

	$self->{results}{filled_in} = $filled_in;

	if ( !$self->{opts}{np} ) {
		print $filled_in;
	}

	if ( $self->{opts}{w} ) {
		eval { write_file( $self->{opts}{o}, $filled_in ); };
		if ($@) {
			$self->status_add(
				error  => 1,
				status => 'Writing out config to "' . $self->{opts}{o} . '" failed ... ' . $@
			);
		}
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates a config file SNMPD.';
}

sub opts_data {
	return '
w
np
o=s
';
}

1;

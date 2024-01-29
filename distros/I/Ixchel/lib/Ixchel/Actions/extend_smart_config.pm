package Ixchel::Actions::extend_smart_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::extend_smart_config - Generates the config for the SMART SNMP extend.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a extend_smart_config [B<-w>] [B<-o> <file>]

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'extends_smart_config', opts=>{w=>1});

    if ($results->{ok}) {
        print $results->{filled_in};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

This invokes the extend with -g to generate a base config.

The returned value is the filed in template.

If snmp.extends.smart.additional_update_args is defined and
not blank, these tacked on to the command.

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/smart-extend.conf

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
		$self->{opts}{o} = '/usr/local/etc/smart-extend.conf';
	}

	# set the default output for -w if not defined
	if ( !defined( $self->{opts}{w} ) ) {
		$self->{opts}{w} = 0;
	}

	my $command = $self->{config}{snmp}{extend_base_dir} . '/smart -g';
	if ( $self->{config}{snmp}{extends}{smart}{additional_update_args} ) {
		$command = $command . ' ' . $self->{config}{snmp}{extends}{smart}{additional_update_args};
	}
	my $filled_in = `$command 2>&1`;
	if ( $? != 0 ) {
		$self->status_add( status => '"' . $command . '" exited non-zero... ' . $filled_in, error => 1 );
		$self->{results}{filled_in} = $filled_in;
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
				status => 'Failed to write out filled in template to "' . $self->{opts}{o} . '" ... ' . $@,
				error  => 1
			);
		}
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the config for the SMART SNMP extend.';
}

sub opts_data {
	return '
w
o=s
np
';
}

1;

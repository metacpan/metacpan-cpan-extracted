package Ixchel::Actions::extend_logsize_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::extend_logsize_config - Generates the config for the logsize SNMP extend.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 CLI SYNOPSIS

ixchel -a extend_logsize_config [B<-w>] [B<-o> <file>]

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'extends_logsize_config', opts=>{w=>1, np=>1});

    if ($results->{ok}) {
        print $results->{filled_in};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

The template used is 'extend_logsize'.

The returned value is the filed in template.

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/logsize.conf

=head2 --np

Don't print the the filled in template.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .filled_in :: The filled in template.

=cut

sub action_extra {
	my $self = $_[0];

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{o} ) ) {
		$self->{opts}{o} = '/usr/local/etc/logsize.conf';
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
				t  => 'extend_logsize',
			},
		);
	};
	if ($@) {
		$self->status_add( status => 'Failed to fill out template extend_logsize ... ' . $@, error => 1 );
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
				status => 'Failed to write out filled_in template to "' . $self->{opts}{o} . '" ... ' . $@,
				error  => 1
			);
		}
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the config for the logsize SNMP extend.';
}

sub opts_data {
	return '
w
o=s
np
';
}

1;

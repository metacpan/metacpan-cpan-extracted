package Ixchel::Actions::apt_proxy;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::apt_proxy - Generates the proxy config file for apt.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a apt_proxy [B<-w>] [B<-o> <file>]

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'apt_proxy', opts=>{w=>1});

    if ($results->{ok}) {
        print $results->{filled_in};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

The template used is 'apt_proxy'.

The returned value is the filed in template.

The template used is apt_proxy.

=head1 FLAGS

=head2 -w

Write out the file.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /etc/apt/apt.conf.d/00aptproxy

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
		$self->{opts}{o} = '/etc/apt/apt.conf.d/00aptproxy';
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
				t  => 'apt_proxy',
			},
		);
	};
	if ($@) {
		$self->status_add( status => 'Failed to fill out template apt_proxy ... ' . $@, error => 1 );
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
	return 'Generates the proxy config file for apt.';
}

sub opts_data {
	return '
w
o=s
np
';
}

1;

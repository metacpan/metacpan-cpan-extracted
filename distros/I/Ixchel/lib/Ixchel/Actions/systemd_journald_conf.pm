package Ixchel::Actions::systemd_journald_conf;

use 5.006;
use strict;
use warnings;
use Config::Tiny;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::systemd_journald_conf - Generate a systemd journald config include.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a systemd_journald_conf

ixchel -a systemd_journald_conf B<-w> [B<--np>] [B<--die>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'systemd_journald_conf', opts=>{np=>1, w=>1, });

=head1 DESCRIPTION

This takes .config.systemd.journald and generates a config that can be used with journald.

So if you would like to disable forward to wall, you can set .systemd.journald.ForwardToWall=no
and it will generate the following...

    [Journal]
    ForwardToWall=no

=head1 Switches

=head2 -w

Write it out to /etc/systemd/journald.conf.d/99-ixchel.conf

=head2 --np

Do not print out the results.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .filled_in :: The filled in template.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $string = '';
	eval {
		my $config = Config::Tiny->new(
			{
				Journal => $self->{config}{systemd}{journald}
			}
		);

		$string = $config->write_string;

		if ( !-d '/etc/systemd/journald.conf.d/' ) {
			mkdir('/etc/systemd/journald.conf.d/')
				or die( 'Could not create /etc/systemd/journald.conf.d/ ...' . $@ );
		}

		if ( $self->{opts}{w} ) {
			write_file( '/etc/systemd/journald.conf.d/99-ixchel.conf', $string );
		}
	};
	if ($@) {
		if ( !defined($string) ) {
			$string = '';
		}
		$self->status_add( status => $@ . "\n" . $string );
		return undef;
	}

	$self->{results}{filled_in} = $string;

	if ( !$self->{opts}{np} ) {
		print $string;
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Generate a systemd journald config include';
}

sub opts_data {
	return 'w
np
die';
}

1;

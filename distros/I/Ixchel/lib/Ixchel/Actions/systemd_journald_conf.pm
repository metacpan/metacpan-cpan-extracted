package Ixchel::Actions::systemd_journald_conf;

use 5.006;
use strict;
use warnings;
use Config::Tiny;

=head1 NAME

Ixchel::Actions::systemd_journald_conf :: Generate a systemd journald config include.
s
=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'systemd_journald_conf', opts=>{np=>1, w=>1, });

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

=head2 --die

Die on write failure.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
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

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	return $self;
} ## end sub new

sub action {
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
		if ( $self->{opts}{die} ) {
			die($@);
		}
		$string = '# ' . $@ . "\n" . $string;
		$self->{ixchel}{errors_count}++;
	}

	if ( !$self->{opts}{np} ) {
		print $string;
	}

	return $string;
} ## end sub action

sub help {
	return 'Generate a systemd journald config include

-w        Write it out to /etc/systemd/journald.conf.d/99-ixchel.conf

--np      Do not print out the results.

--die     Die on write failure.
';
} ## end sub help

sub short {
	return 'Generate a systemd journald config include';
}

sub opts_data {
	return 'w
np
die';
}

1;

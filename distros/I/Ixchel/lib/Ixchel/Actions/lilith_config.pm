package Ixchel::Actions::lilith_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use TOML::Tiny qw(to_toml);
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::lilith_config - Generates the config for Lilith.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 CLI SYNOPSIS

ixchel -a lilith_config [B<-w>] [B<-o> <outfile>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'lilith_config', opts=>{});

    if ($results->{ok}) {
        print $results->{config};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 FLAGS

=head2 -w

Write it out.

=head2 -o <outfile>

The file to write it out to.

Default :: /usr/local/etc/lilith.toml

=head1 CONFIG

.lilith.config is used for generating the config.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .config :: The generated config.

=cut

sub new_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}{o} ) ) {
		$self->{opts}{o} = '/usr/local/etc/lilith.toml';
	}
}

sub action_extra {
	my $self = $_[0];

	my $toml;
	eval { $toml = to_toml( $self->{config}{lilith}{config} ); };
	if ($@) {
		$self->status_add( error => 1, status => 'Errored generating TOML for config ... ' . $@ );
		return undef;
	}

	if ( !$self->{opts}{np} ) {
		print $toml;
	}

	if ( $self->{opts}{w} ) {
		eval { write_file( $self->{opts}{o}, $toml ) };
		if ($@) {
			$self->status_add(
				error  => 1,
				status => 'Errored writing TOML out to "' . $self->{opts}{o} . '" ... ' . $@
			);
			return undef;
		}
	} ## end if ( $self->{opts}{w} )

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the config for Lilith.';
}

sub opts_data {
	return '
np
w
o=s
';
}

1;

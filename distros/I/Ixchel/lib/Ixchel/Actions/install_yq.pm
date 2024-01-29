package Ixchel::Actions::install_yq;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::install_yq;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::install_yq - Install installs yq

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a install_yq

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'instal_yq', opts=>{});

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 DESCRIPTION

This installs mikefarah/yq. Will use packages if possible, otherwise will
grab the binary from github.

=head1 FLAGS

=head2 -p <path>

Where to install it to if not using packages.

Default: /usr/bin/yq

=head2 -n

Don't install via packages.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	$self->status_add( status => 'Installing yq' );

	eval { install_yq( path => $self->{opts}{p}, no_pkg => $self->{opts}{no_pkg} ); };
	if ($@) {
		$self->status_add( status => 'Failed to install yq ... ' . $@, error => 1 );
	} else {
		$self->status_add( status => 'yq installed' );
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Install yq.';
}

sub opts_data {
	return '
p=s
no_pkg
';
}

1;

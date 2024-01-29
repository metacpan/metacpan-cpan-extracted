package Ixchel::Actions::install_pip;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::install_pip;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::install_pip - Install pip via packages.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a install_pip

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'instal_pip', opts=>{});

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	$self->status_add( status => 'Installing pip via packges' );

	eval { install_pip; };
	if ($@) {
		$self->status_add( status => 'Failed to install pip via packages ... ' . $@, error => 1 );
	} else {
		$self->status_add( status => 'pip installed' );
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Install pip via packages.';
}

sub opts_data {
	return '
';
}

1;

package Ixchel::Actions::python_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::python_module_via_pkg;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::python_module_via_pkg - Install cpanm via packages.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a python_module_via_pkg B<--module> <module>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'python_module_via_pkg', opts=>{module=>'Dumper'});

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 FLAGS

=head2 --module <module>

The module to install.

This is required.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}{module} ) ) {
		$self->status_add( status => '--module is undef', error => 1 );
		return undef;
	}

	$self->status_add( status => 'Installing python3 module via packges' );

	my $status;
	eval { $status = python_module_via_pkg( module => $self->{opts}{module}, no_print => 1 ); };
	if ($@) {
		$self->status_add(
			status => 'Failed to install ' . $self->{opts}{module} . ' via packages ... ' . $@,
			error  => 1
		);
	} else {
		$self->status_add( status => $self->{opts}{module} . ' installed' );
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Install a Python module via packages';
}

sub opts_data {
	return '
module=s
';
}

1;

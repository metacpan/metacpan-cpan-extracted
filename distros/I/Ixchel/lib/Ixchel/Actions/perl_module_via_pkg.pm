package Ixchel::Actions::perl_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::perl_module_via_pkg;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::perl_module_via_pkg - Install Perl modules via the package manager.

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 CLI SYNOPSIS

ixchel -a perl_module_via_pkg B<--module> <module>

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'perl_module_via_pkg', opts=>{module=>'Monitoring::Sneck'});

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 FLAGS

=head2 --module <module>

The module to install.

This must be specified.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}{module} ) ) {
		$self->status_add(
			status => '--module is undef',
			error  => 1
		);
		return undef;
	}

	$self->status_add( status => 'Installing cpanm via packges' );

	my $status;
	eval { $status = perl_module_via_pkg( module => $self->{opts}{module} ); };
	if ($@) {
		$self->status_add(
			status => 'Failed to install ' . $self->{opts}{module} . ' via packages' . $@,
			error  => 1
		);
	} else {
		$self->status_add( status => $self->{opts}{module} . ' installed' );
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Install a Perl module via packages';
}

sub opts_data {
	return '
module=s
';
}

1;

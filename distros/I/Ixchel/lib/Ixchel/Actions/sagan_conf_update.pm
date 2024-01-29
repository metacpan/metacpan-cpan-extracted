package Ixchel::Actions::sagan_conf_update;

use 5.006;
use strict;
use warnings;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::sagan_conf_update - Update the all Sagan confs.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a sagan_conf_update [B<--np>] [B<-w>] [B<--no_base>] [B<-i> <instance>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_conf_update', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

This calls runs the following actions if
.sagan.merged_base_include is false.

    sagan_base
    sagan_include
    sagan_rules

This calls runs the following actions if
.sagan.merged_base_include is true.

    sagan_merged
    sagan_rules

=head1 FLAGS

=head2 -i instance

A instance to operate on.

=head2 --no_base

Do not rebuild the base files.

Only relevant is the config item .sagan.merged_base_include
is false.

=head2 --no_include

Do not rebuild the include files.

Only relevant is the config item .sagan.merged_base_include
is false.

=head2 --no_merged

Do not rebuild the the merged base/include files.

Only relevant is the config item .sagan.merged_base_include
is true.

=head2 --no_rules

Do not rebuild the rules files.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my %opts = %{ $self->{opts} };
	$opts{np} = 1;

	if ( $self->{config}{sagan}{merged_base_include} ) {
		if ( !$self->{opts}{no_merged} ) {
			$self->status_add( status => '-----[ sagan_merged ]-------------------------------------' );
			my $returned;
			eval { $returned = $self->{ixchel}->action( action => 'sagan_merged', opts => \%opts ); };
			if ($@) {
				$self->status_add( status => 'sagan_incude died ... ' . $@, error => 1 );
			} else {
				if ( defined( $returned->{errors}[0] ) ) {
					push( @{ $self->{results}{errors} }, @{ $returned->{errors} } );
					$self->status_add( status => 'sagan_merged errored', error => 1 );
				} else {
					$self->status_add( status => 'sagan_merged completed with out errors.', );
				}
			}
		} ## end if ( !$self->{opts}{no_merged} )
	} else {
		if ( !$self->{opts}{no_base} ) {
			$self->status_add( status => '-----[ sagan_base ]-------------------------------------', );
			my $returned;
			eval { $returned = $self->{ixchel}->action( action => 'sagan_base', opts => \%opts ); };
			if ($@) {
				$self->status_add( status => 'sagan_base died ' . $@, error => 1 );
			} else {
				if ( defined( $returned->{errors}[0] ) ) {
					push( @{ $self->{results}{errors} }, @{ $returned->{errors} } );
					$self->status_add( status => 'sagan_base errored', error => 1 );
				} else {
					$self->status_add( status => 'sagan_base completed with out errors', );
				}
			}
		} ## end if ( !$self->{opts}{no_base} )

		if ( !$self->{opts}{no_include} ) {
			my $status = '-----[ sagan_include ]-------------------------------------' . "\n";
			my $returned;
			eval { $returned = $self->{ixchel}->action( action => 'sagan_include', opts => \%opts ); };
			if ($@) {
				$self->status_add( status => 'sagan_incude died ... ' . $@, error => 1 );
			} else {
				if ( defined( $returned->{errors}[0] ) ) {
					push( @{ $self->{results}{errors} }, @{ $returned->{errors} } );
					$self->status_add( status => 'sagan_include errored', error => 1 );
				} else {
					$self->status_add( status => 'sagan_include completed with out errors', );
				}
			}
		} ## end if ( !$self->{opts}{no_include} )
	} ## end else [ if ( $self->{config}{sagan}{merged_base_include...})]

	if ( !$self->{opts}{no_rules} ) {
		my $status = '-----[ sagan_rules ]-------------------------------------' . "\n";
		my $returned;
		eval { $returned = $self->{ixchel}->action( action => 'sagan_rules', opts => \%opts ); };
		if ($@) {
			$self->status_add( status => 'sagan_rules died ... ' . $@, error => 1 );
		} else {
			if ( defined( $returned->{errors}[0] ) ) {
				push( @{ $self->{results}{errors} }, @{ $returned->{errors} } );
				$self->status_add( status => 'sagan_rules errored', error => 1 );
			} else {
				$self->status_add( status => 'sagan_rules completed with out errors', );
			}
		}
	} ## end if ( !$self->{opts}{no_rules} )

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the instance specific include for a sagan instance.';
}

sub opts_data {
	return 'i=s
w
no_base
no_include
no_rules
no_merged
';
}

1;

package Jaipo::Service;
use warnings;
use strict;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors (qw/core options trigger_name sp_id/);


=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my $class = shift;
	my %options = @_;

	my $self = {};
	bless $self , $class;

    $self->trigger_name( $options{trigger_name} );
    $self->sp_id( $options{sp_id} );
	$self->options( \%options );

	return $self;
}

=head2 init

=cut

sub init {
	my $self = shift;

}


=head2 new_request

called right before every request

=cut

sub new_request {
	my $self = shift;

}


sub dispatch_sub_command {
    my ($self, $sub_command, $rest ) = @_;

    # service 
    my $builtin_command = {
        m => 'read_user_timeline',
        p => 'read_public_timeline',
        g => 'read_global_timeline',
        '?' => 'help',
    };

    if( defined $builtin_command->{ $sub_command } ) {
        my $func =  $builtin_command->{ $sub_command };
		$self->$func( $rest );
    }

    # todo: otherwise we dispatch to service specific command
}




=head2 prereq_plugins

Returns an array of plugin module names that this plugin depends on.

=cut 

sub prereq_plugins {
	return ();
}


=head1 SERVICE METHODS

=head2 send_msg

=cut

sub send_msg {

}

=head2 set_location

=cut

sub set_location {

}

=head2 read_user_timeline

updates from user him self

=cut

sub read_user_timeline {

}

=head2 read_public_timeline

updates from users friends or follows

=cut

sub read_public_timeline {

}

=head2 read_global_timeline

global timeline ( out of space !! )

=cut

sub read_global_timeline {

}


=head1 FILTER_METHODS

=head2 create_filter

=cut

sub create_filter {

}

=head2 apply_filter

=cut

sub apply_filter {

}

=head2 remove_filter 

=cut 

sub remove_filter {

}




1;


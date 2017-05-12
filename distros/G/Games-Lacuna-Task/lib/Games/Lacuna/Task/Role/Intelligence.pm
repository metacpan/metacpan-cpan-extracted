package Games::Lacuna::Task::Role::Intelligence;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

sub assigned_to_type {
    my ($self,$assigned_to) = @_;
    
    return 'own'
        if $assigned_to->{body_id} ~~ [ $self->my_bodies ];
    
    my $body_data = $self->get_body_by_id($assigned_to->{body_id});
    
    return 'unknown'
        unless defined $body_data
        && defined $body_data->{empire};
    
    return $body_data->{empire}{alignment}; 
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task::Role::Intelligence - Helper methods for intelligence

=head1 SYNOPSIS

 package Games::Lacuna::Task::Action::MyTask;
 use Moose;
 extends qw(Games::Lacuna::Task::Action);
 with qw(Games::Lacuna::Task::Role::Intelligence);

=head1 DESCRIPTION

This role provides intelligence-related helper methods.

=head1 METHODS

=head2 assigned_to_type

=cut
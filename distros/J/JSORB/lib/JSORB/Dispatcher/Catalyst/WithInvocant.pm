package JSORB::Dispatcher::Catalyst::WithInvocant;
use Moose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'JSORB::Dispatcher::Path';
   with 'JSORB::Dispatcher::Traits::WithInvocantFactory';

has 'constructor_arg_generators' => (
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',   
    default => sub { {} },
);

sub prepare_handler_args {
    my ($self, $call, $c) = @_;
    
    my $procedure = $self->get_procedure_from_call($call);
    return unless defined $procedure;
    
    my $constructor_generator = $self->constructor_arg_generators->{ $procedure->class_name };
    return unless defined $constructor_generator;
    
    return $constructor_generator->($c);
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Catalyst::WithInvocant - A Catalyst dispatcher for invocants

=head1 DESCRIPTION

Very similar to L<JSORB::Dispatcher::Catalyst> but handles the 
creation of object invocants for each request. 

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

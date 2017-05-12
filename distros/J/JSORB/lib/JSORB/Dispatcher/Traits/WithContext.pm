package JSORB::Dispatcher::Traits::WithContext;
use Moose::Role;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

has 'context_class' => (
    is        => 'rw',
    isa       => 'Str',   
    predicate => 'has_context_class'
);

around 'assemble_params_list' => sub {
    my $next = shift;
    my ($self, $call, $context, @args) = @_;
    (blessed $context && $context->isa($self->context_class))
        || confess "Expected a context of type (" . $self->context_class . ") but got ($context)"
            if $self->has_context_class;    
    return ($context, $self->$next( $call, @args ));    
};

no Moose::Role; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Traits::WithContext - A dispatcher trait for context arguments

=head1 DESCRIPTION

This is a dispatcher trait that expects a context object (i.e. -
the Catalyst C<$c> object) as the first argument. 

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

package JSORB::Dispatcher::Traits::WithInvocant;
use Moose::Role;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

before 'call_procedure' => sub {
    my ($self, $procedure) = @_;
    ($procedure->isa('JSORB::Method'))
        || confess "Procedure must be a JSORB::Method, not a $procedure";    
};

around 'assemble_params_list' => sub {
    my $next = shift;
    my ($self, $call, $invocant, @args) = @_;
    return ($invocant, $self->$next( $call, @args ));    
};

no Moose::Role; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Traits::WithInvocant - A dispatcher trait for invocants

=head1 DESCRIPTION

This is a dispatcher trait that expects a object invocant as the 
first argument. It can only be used with L<JSORB::Method> and not 
L<JSORB::Procedure>.

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

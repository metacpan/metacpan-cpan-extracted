package JSORB::Dispatcher::Traits::WithInvocantFactory;
use Moose::Role;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

with 'JSORB::Dispatcher::Traits::WithInvocant';

sub call_procedure {
    my ($self, $procedure, $call, @args) = @_;
    
    my $class_name = $procedure->class_name;
    my $invocant   = $class_name->new( @args );
    
    $procedure->call( $self->assemble_params_list( $call, $invocant ) );
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Traits::WithInvocantFactory - A dispatch trait which creates invocants

=head1 DESCRIPTION

This is very similar to L<JSORB::Dispatcher::Traits::WithInvocant> 
except that it will create a new invocant for each procedure call.

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

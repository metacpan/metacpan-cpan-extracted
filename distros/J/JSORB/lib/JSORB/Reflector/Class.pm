package JSORB::Reflector::Class;
use Moose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'JSORB::Reflector::Package';

has '+introspector' => (isa => 'Class::MOP::Class');

has '+procedure_class_name' => (
    default => sub { 'JSORB::Method' },
);

sub build_procedure_list {
    my $self = shift;
    return [ 
        map { 
            $_->package_name eq 'Moose::Object'
                ? ()
                : +{ name => $_->name } 
        } $self->introspector->get_all_methods
    ]
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Reflector::Class - Automatic JSORB namespace/interface construction

=head1 DESCRIPTION

This uses Moose/Class::MOP introspection to build a JSORB namespace.
It fully respects inheritance and will reflect all applicable methods 
of the class.

=head2 NOTE ABOUT REFLECTION

The automated reflector will B<NOT> reflect methods in L<Moose::Object>. 
This is because this rarely makes sense for it to do so. If you have a 
particular use case in which this does make sense, then you are free to 
specifically request the method by building the procedure list yourself.

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

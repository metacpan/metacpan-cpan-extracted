package JSORB::Reflector::Package;
use Moose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

has 'introspector' => (
    is       => 'ro',
    isa      => 'Class::MOP::Package',   
    required => 1,
    handles  => {
        'package_name' => 'name'
    }
);

has 'procedure_list' => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',   
    lazy    => 1,
    builder => 'build_procedure_list',
);

has 'procedure_class_name' => (
    is      => 'ro',
    isa     => 'Str',   
    default => sub { 'JSORB::Procedure' },
);

has 'namespace' => (
    is      => 'ro',
    isa     => 'JSORB::Namespace',   
    lazy    => 1,
    builder => 'build_namespace',
);

sub build_namespace {
    my $self = shift;
    
    my @name = split /\:\:/ => $self->package_name;
    
    my $root_ns;
    
    my $interface = JSORB::Interface->new(name => pop @name);
    
    if (@name) {
        $root_ns   = JSORB::Namespace->new(name => shift @name);

        my $current_ns = $root_ns;    
        while (@name) {
            my $ns = JSORB::Namespace->new(name => shift @name);
            $current_ns->add_element($ns);
            $current_ns = $ns;
        }
    
        $current_ns->add_element($interface);
    }
    else {
        $root_ns = $interface;
    }
    
    foreach my $proc_spec (@{ $self->procedure_list }) {
        $interface->add_procedure(
            $self->procedure_class_name->new( $proc_spec )
        );
    }
    
    return $root_ns;
}

sub build_procedure_list {
    my $self = shift;
    return [ map { 
        +{ name => $_ } 
    } $self->introspector->list_all_package_symbols('CODE') ]
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Reflector::Package - Automatic JSORB namespace/interface construction 

=head1 DESCRIPTION

This uses Moose/Class::MOP introspection to build a JSORB namespace.
It is only for packages, so it will look in the immediate package 
B<only> and does not in any way acknowledge inheritance (see 
L<JSORB::Reflector::Class> for that).

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

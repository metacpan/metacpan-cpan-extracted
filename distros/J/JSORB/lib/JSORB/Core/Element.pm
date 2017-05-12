package JSORB::Core::Element;
use Moose;
use MooseX::AttributeHelpers;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'parent' => (
    is        => 'ro',
    writer    => '_set_parent',
    isa       => 'JSORB::Core::Element',
    weak_ref  => 1,
    predicate => 'has_parent',
);

has 'fully_qualified_name' => (
    metaclass => 'Collection::List',
    init_arg  => undef,
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    lazy      => 1,
    default   => sub {
        my $current = shift;
        my @full_name = ($current->name);
        while ($current->has_parent) {
            $current = $current->parent;
            unshift @full_name => $current->name;
        }
        \@full_name;
    }
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Core::Element - A core JSORB element

=head1 DESCRIPTION

Basically this is a named element that is assumed to have a parent
object. Not much else here to see.

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

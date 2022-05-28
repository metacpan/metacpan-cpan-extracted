use strict;
use warnings;
package Devel::REPL::Plugin::ShowClass;
# ABSTRACT: Dump classes initialized with Class::MOP

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;

has 'metaclass_cache' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {{}}
);

before 'eval' => sub {
    my $self = shift;
    $self->update_metaclass_cache;
};

after 'eval' => sub {
    my $self = shift;

    my @metas_to_show;

    foreach my $class (Class::MOP::get_all_metaclass_names()) {
        unless (exists $self->metaclass_cache->{$class}) {
            push @metas_to_show => Class::MOP::get_metaclass_by_name($class)
        }
    }

    $self->display_class($_) foreach @metas_to_show;

    $self->update_metaclass_cache;
};

sub update_metaclass_cache {
    my $self = shift;
    foreach my $class (Class::MOP::get_all_metaclass_names()) {
        $self->metaclass_cache->{$class} = (
            ("" . Class::MOP::get_metaclass_by_name($class))
        );
    }
}

sub display_class {
    my ($self, $meta) = @_;
    $self->print('package ' . $meta->name . ";\n\n");
    $self->print('extends (' . (join ", " => $meta->superclasses) . ");\n\n") if $meta->superclasses;
    $self->print('with (' . (join ", " => map { $_->name } @{$meta->roles}) . ");\n\n") if $meta->can('roles');
    foreach my $attr (map { $meta->get_attribute($_) } $meta->get_attribute_list) {
        $self->print('has ' . $attr->name . " => (\n");
        $self->print('    is => ' . $attr->_is_metadata . ",\n")  if $attr->_is_metadata;
        $self->print('    isa => ' . $attr->_isa_metadata . ",\n") if $attr->_isa_metadata;
        $self->print('    required => ' . $attr->is_required . ",\n") if $attr->is_required;
        $self->print('    lazy => ' . $attr->is_lazy . ",\n") if $attr->is_lazy;
        $self->print('    coerce => ' . $attr->should_coerce . ",\n") if $attr->should_coerce;
        $self->print('    is_weak_ref => ' . $attr->is_weak_ref . ",\n") if $attr->is_weak_ref;
        $self->print('    auto_deref => ' . $attr->should_auto_deref . ",\n") if $attr->should_auto_deref;
        $self->print(");\n");
        $self->print("\n");
    }
    foreach my $method_name ($meta->get_method_list) {
        next if $method_name eq 'meta'
             || $meta->get_method($method_name)->isa('Class::MOP::Method::Accessor');
        $self->print("sub $method_name { ... }\n");
        $self->print("\n");
    }
    $self->print("1;\n");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::ShowClass - Dump classes initialized with Class::MOP

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

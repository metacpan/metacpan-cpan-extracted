=head1 NAME

Declare::Constraints::Simple::Library::Exportable - Export Facilities

=cut

package Declare::Constraints::Simple::Library::Exportable;
use warnings;
use strict;

use Carp::Clan qw(^Declare::Constraints::Simple);
use Class::Inspector;

use aliased 'Declare::Constraints::Simple::Library::Base' => 'LibraryBase';
sub Library () { 'Declare::Constraints::Simple::Library' }

=head1 DESCRIPTION

This contains the constraint export logic of the module.

=head1 METHODS

=head2 import($flag, @args)

  use ExportableModule->All;

  # or
  use ExportableModule-Only => qw(Constraint1 ...);

  # or
  use ExportableModule-Library;

Exports the constraints to the calling namespace. This includes all
libraries in L<Declare::Constraints::Simple::Library>, that package itself
(providing all default constraints) or L<Declare::Constraints::Simple>
itself as a shortcut.

Possible flags are

=over

=item All

Imports all constraints registered in the class and its base classes.

=item Only

  use Declare::Constraints::Simple::Library::Scalar-Only => 'HasLength';

The above line would only import the C<HasLength> constraints from the
C<Scalar> default library. Note however, that you could also just have
said

  use Declare::Constraints::Simple-Only => 'HasLength';

as both C<::Simple> and C<::Simple::Library> work on all default
libraries.

=item Library

You can use this to define your own constraint library. For more
information, see L<Declare::Constraints::Simple::Library::Base>.

=back

=cut

sub import {
    my ($class, $flag, @args) = @_;
    return unless $flag;

    my $handle_map = $class->_build_handle_map;
    my $target = scalar(caller);
    
    if ($flag =~ /^-?all$/i) {
        $class->_export_all($target, $handle_map);
    }
    elsif ($flag =~ /^-?only$/i) {
        $class->_export_these($target, $handle_map, @args);
    }
    elsif ($flag =~ /^-?library$/i) {
        LibraryBase->install_into($target);
    }

    1;
}

=head2 _build_handle_map()

Internal method to build constraint-to-class mappings.

=cut

sub _build_handle_map {
    my ($class) = @_;

    if ($class eq 'Declare::Constraints::Simple') {
        $class = Library;
    }

    if ($class eq Library) {
        unless (Class::Inspector->loaded(Library)) {
            require Class::Inspector->filename(Library);
        }
    }

    my (%seen, %handle_map, @walk, %walked);
    @walk = do {
        no strict 'refs'; 
        ($class, @{$class . '::ISA'});
    };

    while (my $w = shift @walk) {

        next if $walked{$w};
        $walked{$w} = 1;

        if ($w->can('fetch_constraint_declarations')) {
            my @decl = $w->fetch_constraint_declarations;
            for my $d (@decl) {
                next if exists $seen{$d};
                $seen{$d} = 1;
                $handle_map{$d} = $w;
            }
        }

        push @walk,
            grep { not exists $walked{$_} }
              do { no strict 'refs' ; @{$w . '::ISA'} };
    }

    return \%handle_map;
}

=head2 _export_all($target, $handle_map)

Internal method. Exports all handles in C<$handle_map> into the C<$target> 
namespace.

=cut

sub _export_all {
    my ($class, $target, $handle_map) = @_;
    return $class->_export_these($target, $handle_map, keys %$handle_map);
}

=head2 _export_these($target, $handle_map, @constraints)

Internal method. Exports all C<@constraints> from C<$handle_map> into the
C<$target> namespace.

=cut

sub _export_these {
    my ($class, $target, $handle_map, @decl) = @_;

    for my $d (@decl) {
        my $handle = $handle_map->{$d}
            or croak "Constraint '$d' cannot be found in $class";
        my $gen = $handle_map->{$d}->fetch_constraint_generator($d);

        croak sprintf 
            'Constraint Generator for $s in %s did not return a closure',
            $d, $handle_map->{$d}
            unless ref($gen) eq 'CODE';

        {   no strict 'refs';
            *{$target . '::' . $d} = $gen;
        }
    }
}

=head1 SEE ALSO

L<Declare::Constraints::Simple>, L<Declare::Constraints::Simple::Library>,
L<Declare::Constraints::Simple::Library::Base>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This module is free software, you can redistribute it and/or modify it 
under the same terms as perl itself.

=cut

1;

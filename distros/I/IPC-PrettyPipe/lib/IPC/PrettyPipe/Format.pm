package IPC::PrettyPipe::Format;

# ABSTRACT: Format role

## no critic (ProhibitAccessOfPrivateData)

use Try::Tiny;
use Module::Load;


use Moo::Role;
our $VERSION = '0.12';

with 'MooX::Attributes::Shadow::Role';

requires 'copy_into';

use namespace::clean;

# IS THIS REALLY NEEDED?????  this will convert an attribute with a
# an undef value into a switch.
#
# undefined values are the same as not specifying a value at all
if ( 0 ) {
    around BUILDARGS => sub {

        my ( $orig, $class ) = ( shift, shift );

        my $attrs = $class->$orig( @_ );

        delete @{$attrs}{ grep { !defined $attrs->{$_} } keys %$attrs };

        return $attrs;
    };
}

sub _copy_attrs {

    my ( $from, $to ) = ( shift, shift );

    for my $attr ( @_ ) {


        next unless $from->${ \"has_$attr" };

        try {
            if ( defined( my $value = $from->$attr ) ) {

                $to->$attr( $value );

            }

            else {

                $to->${ \"clear_$attr" };

            }
        }
        catch {

            croak(
                "unable to copy into or clear attribute $attr in object of type ",
                ref $to,
                ": $_\n"
            );
        };

    }

    return;
}











sub copy_from {

    $_[1]->copy_into( $_[0] );

    return;
}









sub clone {

    my $class = ref( $_[0] );
    load $class;

    my $clone = $class->new;

    $_[0]->copy_into( $clone );

    return $clone;
}










sub new_from_attrs {

    my $class = shift;
    load $class;

    return $class->new( $class->xtract_attrs( @_ ) );
}













sub new_from_hash {

    my $contained = shift;
    my $hash      = pop;

    my $container = shift || caller();

    load $contained;

    my $shadowed = $contained->shadowed_attrs( $container );

    my %attr;
    while ( my ( $alias, $orig ) = each %{$shadowed} ) {

        $attr{$orig} = $hash->{$alias} if exists $hash->{$alias};

    }

    return $contained->new( \%attr );
}

1;

#
# This file is part of IPC-PrettyPipe
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

IPC::PrettyPipe::Format - Format role

=head1 VERSION

version 0.12

=head1 METHODS

=head2 copy_from

  $self->copy_from( $src );

Copy attributes from the C<$src> object into the object.

=head2 clone

  $object = $self->clone;

Clone the object;

=head2 new_from_attrs

   my $obj = IPC::PrettyPipe::Format->new_from_attrs( $container_obj, \%options );

Create a new object using attributes from the C<$container_obj>.

=head2 new_from_hash

   my $obj = IPC::PrettyPipe::Format->new_from_hash( ?$container, \%attr );

Create a new object using attributes from C<%attr> which are indicated as
being shadowed from C<$container>.  If C<$container> is not specified
it is taken from the Caller's class.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe> or by
email to
L<bug-IPC-PrettyPipe@rt.cpan.org|mailto:bug-IPC-PrettyPipe@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/ipc-prettypipe>
and may be cloned from L<git://github.com/djerius/ipc-prettypipe.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::PrettyPipe|IPC::PrettyPipe>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

package File::Gettext::Schema;

use namespace::autoclean;

use File::DataClass::Constants qw( FALSE LANG TRUE );
use File::DataClass::Functions qw( is_hashref merge_attributes );
use File::DataClass::Types     qw( Directory Str );
use File::Gettext::Constants   qw( LOCALE_DIRS );
use File::Gettext::ResultSource;
use File::Gettext::Storage;
use Scalar::Util               qw( blessed );
use Moo;

extends q(File::DataClass::Schema);

has 'gettext_catagory' => is => 'ro', isa => Str, default => 'LC_MESSAGES';

has 'language'         => is => 'rw', isa => Str, default => LANG;

has 'localedir'        => is => 'ro', isa => Directory, coerce => TRUE,
   default             => sub { LOCALE_DIRS->[ 0 ] };

has '+result_source_class' => default => 'File::Gettext::ResultSource';

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   # TODO: Deprecated
   my $lang    = delete $attr->{lang}; $attr->{language} //= $lang;
   my $builder = $attr->{builder} or return $attr;
   my $config  = $builder->can( 'config' ) ? $builder->config : {};
   my $keys    = [ qw( gettext_catagory language localedir ) ];

   merge_attributes $attr, $config, $keys;

   return $attr;
};

sub BUILD {
   my $self    = shift;
   my $storage = $self->storage;
   my $class   = 'File::Gettext::Storage';
   my $attr    = { schema => $self, storage => $storage };

   blessed $storage ne $class and $self->storage( $class->new( $attr ) );

   return;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::Schema - Adds language support to the default schema

=head1 Synopsis

=head1 Description

Extends L<File::DataClass::Schema>

=head1 Configuration and Environment

Defines these attributes

=over 3

=item C<gettext_catagory>

Subdirectory of C<localdir> that contains the F<mo> / F<po> files. Defaults
to C<LC_MESSAGES>

=item C<language>

The two character language code, e.g. C<de>.

=item C<localedir>

Path to the subtree containing the MO/PO files

=item C<result_source_class>

Overrides the default

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Sets the result source class to L<File::Gettext::ResultSource>

=head2 BUILD

If the schema is language dependent then an instance of
L<File::Gettext::Storage> is created as a proxy for the storage class

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<Moo>

=item L<Type::Tiny>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

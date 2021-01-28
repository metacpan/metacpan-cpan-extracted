use strict;
use warnings;
package MooseX::Types::Path::Class; # git description: v0.08-5-gc1e201f
# ABSTRACT: A Path::Class type library for Moose

our $VERSION = '0.09';

use Path::Class 0.16 ();

use MooseX::Types
    -declare => [qw( Dir File )];

use MooseX::Types::Moose qw(Str ArrayRef);
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

class_type('Path::Class::Dir');
class_type('Path::Class::File');

subtype Dir, as 'Path::Class::Dir';
subtype File, as 'Path::Class::File';

for my $type ( 'Path::Class::Dir', Dir ) {
    coerce $type,
        from Str,      via { Path::Class::Dir->new($_) },
        from ArrayRef, via { Path::Class::Dir->new(@$_) };
}

for my $type ( 'Path::Class::File', File ) {
    coerce $type,
        from Str,      via { Path::Class::File->new($_) },
        from ArrayRef, via { Path::Class::File->new(@$_) };
}

# optionally add Getopt option type
eval { require MooseX::Getopt; };
if ( !$@ ) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
        for ( 'Path::Class::Dir', 'Path::Class::File', Dir, File, );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Path::Class - A Path::Class type library for Moose

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::Types::Path::Class;
  with 'MooseX::Getopt';  # optional

  has 'dir' => (
      is       => 'ro',
      isa      => 'Path::Class::Dir',
      required => 1,
      coerce   => 1,
  );

  has 'file' => (
      is       => 'ro',
      isa      => 'Path::Class::File',
      required => 1,
      coerce   => 1,
  );

  # these attributes are coerced to the
  # appropriate Path::Class objects
  MyClass->new( dir => '/some/directory/', file => '/some/file' );

=head1 DESCRIPTION

MooseX::Types::Path::Class creates common L<Moose> types,
coercions and option specifications useful for dealing
with L<Path::Class> objects as L<Moose> attributes.

Coercions (see L<Moose::Util::TypeConstraints>) are made
from both C<Str> and C<ArrayRef> to both L<Path::Class::Dir> and
L<Path::Class::File> objects.  If you have L<MooseX::Getopt> installed,
the C<Getopt> option type ("=s") will be added for both
L<Path::Class::Dir> and L<Path::Class::File>.

=head1 EXPORTS

None of these are exported by default.  They are provided via
L<MooseX::Types>.

=over

=item Dir, File

These exports can be used instead of the full class names.  Example:

  package MyClass;
  use Moose;
  use MooseX::Types::Path::Class qw(Dir File);

  has 'dir' => (
      is       => 'ro',
      isa      => Dir,
      required => 1,
      coerce   => 1,
  );

  has 'file' => (
      is       => 'ro',
      isa      => File,
      required => 1,
      coerce   => 1,
  );

Note that there are no quotes around C<Dir> or C<File>.

=item is_Dir($value), is_File($value)

Returns true or false based on whether $value is a valid C<Dir> or C<File>.

=item to_Dir($value), to_File($value)

Attempts to coerce $value to a C<Dir> or C<File>.  Returns the coerced value
or false if the coercion failed.

=back

=head1 SEE ALSO

L<MooseX::Types::Path::Class::MoreCoercions>, L<MooseX::FileAttribute>, L<MooseX::Types::URI>

=head1 DEPENDENCIES

L<Moose>, L<MooseX::Types>, L<Path::Class>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Path-Class>
(or L<bug-MooseX-Types-Path-Class@rt.cpan.org|mailto:bug-MooseX-Types-Path-Class@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Todd Hepler <thepler@employees.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Jonathan Rockway Yuval Kogman

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jonathan Rockway <jon@jrock.us>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Todd Hepler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

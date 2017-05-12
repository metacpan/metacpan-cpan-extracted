use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections::Section;

# ABSTRACT:  An Objective reference to a section in an ELF file.

our $VERSION = '1.001000';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose;

use Carp qw( croak );
use MooseX::Has::Sugar 0.0300;
use MooseX::Types::Moose                ( ':all', );
use ELF::Extract::Sections::Meta::Types ( ':all', );
use MooseX::Types::Path::Tiny           ( 'File', );
use MooseX::Params::Validate            (qw( validated_list ));

use overload '""' => \&to_string;







has source => ( isa => File, ro, required, coerce, );







has name => ( isa => Str, ro, required );







has offset => ( isa => Int, ro, required );







has size => ( isa => Int, ro, required );

__PACKAGE__->meta->make_immutable;
no Moose;



















sub to_string {
    my ( $self, ) = @_;
    return sprintf
      q{[ Section %s of size %s in %s @ %x to %x ]},
      $self->name, $self->size, $self->source, $self->offset,
      $self->offset + $self->size,
      ;
}























sub compare {
    my ( $self, $other, $field ) = validated_list(
        \@_,
        other => { isa => class_type('ELF::Extract::Sections::Section') },
        field => { isa => FilterField, },
    );
    if ( 'name' eq $field ) {
        return ( $self->name cmp $other->name );
    }
    if ( 'offset' eq $field ) {
        return ( $self->offset <=> $other->offset );
    }
    if ( 'size' eq $field ) {
        return ( $self->size <=> $other->size );
    }
    return;
}

















sub write_to {
    my ( $self, $file ) = validated_list(
        \@_,    #
        file => { isa => File, optional => 0, coerce => 1 },
    );
    my $fh = $self->source->openr;
    seek $fh, $self->offset, 0;
    my $output     = $file->openw;
    my $chunksize  = 1024;
    my $bytes_left = $self->size;
    my $chunk      = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
    while ( read $fh, my $buffer, $chunk ) {
        print {$output} $buffer or Carp::croak("Write to $file failed");
        $bytes_left -= $chunksize;
        $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
    }
    return 1;
}









sub contents {
    my ($self) = @_;
    my $fh = $self->source->openr;
    seek $fh, $self->offset, 0;
    my $b;
    read $fh, $b, $self->size;
    return $b;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Extract::Sections::Section - An Objective reference to a section in an ELF file.

=head1 VERSION

version 1.001000

=head1 SYNOPSIS

  use ELF::Extract::Sections::Section;

  my $s = ELF::Extract::Sections::Section->new(
      source => '/foo/bar.pl',
      name   => '.comment',
      offset => 45670,
      size   => 1244,
  );

  # prints a human friendly description
  print $s->to_string;

  # does likewise.
  print "$s";

  # Compare with another section ( preferably in the same file, meaningless otherwise )
  if( $s->compare( $y , 'name' ) ){

  }

  # Unimplemented
  $s->write_to ( file => '/tmp/out.txt' );

  # Retuns the sections contents as a string
  print $s->contents;

=head1 DESCRIPTION

Generally Intended for use by L<ELF::Extract::Sections> as a meta-structure for tracking data,
but generated objects are returned to you for you to  deal with

=head1 METHODS

=head2 C<new>

  my $section = ELF::Extract::Sections::Section->new( %ATTRIBUTES );

4 Parameters, all required.

Returns an C<ELF::Extract::Sections::Section> object.

=head2 C<to_string>

  my $string = $section->to_string;

returns C<Str> description of the object

    [ Section {name} of size {size} in {file} @ {start} to {stop} ]

=head2 C<compare>

  my $cmp_result = $section->compare( other => $other, field => $field );

2 Parameters, both required

=over 4

=item other

C<ELF::Extract::Sections::Section>: Item to compare with

=item field

C<Str['name','offset','size']>: Field to compare with.

=back

returns C<Int> of comparison result, between -1 and 1

=head2 C<write_to>

  my $boolean = $section->write_to( file => $file );

B<UNIMPLEMENTED AS OF YET>

=over 4

=item file

C<Str>|C<Path::Tiny>: File target to write section contents to.

=back

=head2 C<contents>

  my $string = $section->contents;

returns C<Str> of binary data read out of file.

=head1 ATTRIBUTES

=head2 C<source>

C<Str>|C<Path::Tiny>: Either a String or a Path::Tiny instance pointing to the file in mention.

=head2 C<name>

C<Str>: The ELF Section Name

=head2 C<offset>

C<Int>: Position in bytes relative to the start of the file.

=head2 C<size>

C<Int>: The ELF Section Size

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

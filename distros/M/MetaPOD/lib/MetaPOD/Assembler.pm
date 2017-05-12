use 5.006;    # our
use strict;
use warnings;

package MetaPOD::Assembler;

our $VERSION = 'v0.4.0';

# ABSTRACT: Glue layer that dispatches segments to a constructed Result

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

































use Moo qw( has );
use Carp qw( croak );
use Module::Runtime qw( use_module );





has 'result' => (
  is       => ro =>,
  required => 0,
  lazy     => 1,
  builder  => sub {
    require MetaPOD::Result;
    return MetaPOD::Result->new();
  },
  clearer => 'clear_result',
);





has extractor => (
  is       => ro =>,
  required => 1,
  lazy     => 1,
  builder  => sub {
    my $self = shift;
    require MetaPOD::Extractor;
    return MetaPOD::Extractor->new(
      end_segment_callback => sub {
        my $segment = shift;
        $self->handle_segment($segment);
      },
    );
  },
);





has format_map => (
  is       => ro =>,
  required => 1,
  lazy     => 1,
  builder  => sub {
    return { 'JSON' => 'MetaPOD::Format::JSON', };
  },
);







sub assemble_handle {
  my ( $self, $handle ) = @_;
  $self->clear_result;
  $self->extractor->read_handle($handle);
  return $self->result;
}







sub assemble_file {
  my ( $self, $file ) = @_;
  $self->clear_result;
  $self->extractor->read_file($file);
  return $self->result;
}







sub assemble_string {
  my ( $self, $string ) = @_;
  $self->clear_result;
  $self->extractor->read_string($string);
  return $self->result;
}







sub get_class_for_format {
  my ( $self, $format ) = @_;
  if ( not exists $self->format_map->{$format} ) {
    croak "format $format unsupported";
  }
  return $self->format_map->{$format};
}














sub handle_segment {
  my ( $self, $segment ) = @_;
  my $format  = $segment->{format};
  my $version = $segment->{version};

  my $class = $self->get_class_for_format($format);
  use_module($class);

  return unless $class->supports_version($version);

  $class->add_segment( $segment, $self->result );

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Assembler - Glue layer that dispatches segments to a constructed Result

=head1 VERSION

version v0.4.0

=head1 SYNOPSIS

    use MetaPOD::Assembler;

    my $assembler = MetaPOD::Assembler->new();

    for my $file ( @files ) {
        my $object = $assembler->assemble_file( $file );
    }

This, should be enough for the majority of use-cases.

At present, C<MetaPOD::Assembler> only supports C<JSON> specification out-of-the-box,
but you can extend it to support any other defined specifications by replacing the format map

    my $assembler = MetaPOD::Assembler->new( format_map => {
        JSON => 'MetaPOD::Format::JSON',
        YAML => 'MyProject::Format::YAML',
    });

=head1 METHODS

=head2 assemble_handle

Wraps L<Pod::Eventual/assemble_handle> and returns a C<MetaPOD::Result> for each passed file handle

=head2 assemble_file

Wraps L<Pod::Eventual/assemble_file> and returns a C<MetaPOD::Result> for each passed file

=head2 assemble_string

Wraps L<Pod::Eventual/assemble_string> and returns a C<MetaPOD::Result> for each passed string

=head2 get_class_for_format

Gets the class to load for the specified format from the internal map, L</format_map>

=head2 handle_segment

    $assembler->handle_segment( $segment_hash )

This is the callback point of entry that dispatches calls from the C<MetaPOD::Extractor>,
loads and calls the relevant C<Format> ( via L</get_class_for_format> ), validates
that version specifications are supported ( via C<< Format->supports_version($v) >> )
and then asks the given format to modify the current C<MetaPOD::Result> object
by parsing the given C<$segment_hash>

=head1 ATTRIBUTES

=head2 result

=head2 extractor

=head2 format_map

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Assembler",
    "inherits":"Moo::Object",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

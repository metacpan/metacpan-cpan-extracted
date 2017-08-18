# ABSTRACT: Class representing a particular layout


package HiD::Layout;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Layout::VERSION = '1.991';
use Moose;
use namespace::autoclean;

use 5.014;  # strict, unicode_strings
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;

use Path::Tiny;
use YAML::Tiny  qw/ Load /;

use HiD::Types;


has content => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);


has ext => (
  is       => 'ro'  ,
  isa      => 'HiD_FileExtension' ,
);


has filename => (
  is       => 'ro' ,
  isa      => 'HiD_FilePath' ,
);


has layout => (
  is     => 'rw' ,
  isa    => 'Maybe[HiD::Layout]' ,
  writer => 'set_layout' ,
);


has metadata => (
  is      => 'ro' ,
  isa     => 'HashRef',
  lazy    => 1 ,
  default => sub {{}}
);


has name => (
  is       => 'ro'  ,
  isa      => 'Str' ,
  required => 1 ,
);


has processor => (
  is       => 'ro',
  isa      => 'Object' ,
  required => 1 ,
  handles  => {
    process_template => 'process' ,
    processor_error  => 'error' ,
  },
);


sub BUILDARGS {
  my $class = shift;

  my %args = ( ref $_[0] and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  unless ( $args{content} ) {
    ( $args{name} , $args{ext} ) = $args{filename}
      =~ m|^.*/(.+)\.([^.]+)$|;

    my $content  = path( $args{filename} )->slurp_utf8;
    my $metadata = {};

    if ( $content =~ /^---\n/s ) {
      my $meta;
      ( $meta , $content ) = ( $content )
        =~ m|^---\n(.*?)---\n(.*)$|s;
      $metadata = Load( $meta ) if $meta;
    }

    $args{metadata} = $metadata;
    $args{content}  = $content;
  }

  return \%args;
}


sub render {
  my( $self , $data ) = @_;

  my $page_data = $data->{page} // {};

  %{ $data->{page} } = (
    %{ $self->metadata } ,
    %{ $page_data },
  );

  my $processed_input_content;
  my $input_content = delete $data->{content};

  $self->process_template(
    \$input_content ,
    $data ,
    \$processed_input_content ,
  ) or die $self->processor_error;

  $data->{content} = $processed_input_content;

  my $output;

  $self->process_template(
    \$self->content ,
    $data ,
    \$output ,
  ) or die $self->processor_error;

  if ( my $embedded_layout = $self->layout ) {
    $data->{content} = $output;
    $output = $embedded_layout->render( $data );
  }

  return $output;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Layout - Class representing a particular layout

=head1 SYNOPSIS

    my $layout = HiD::Layout->new({
      filename  => $path_to_file ,
      processor => $hid_processor_object ,
    });

=head1 DESCRIPTION

Class representing layout files.

=head1 ATTRIBUTES

=head2 content

Content of this layout.

=head2 ext

File extension of this layout.

=head2 filename

Filename of this layout.

=head2 layout

Name of a layout that will be used when processing this layout. (Can be
applied recursively.)

=head2 metadata

Metadata for this layout. Populated from the YAML front matter in the layout
file.

=head2 name

Name of the layout.

=head2 processor

Processor object used to process content through this layout when rendering.

=head1 METHODS

=head2 render

Pass in a hash of data, apply the layout using that hash as input, and return
the resulting output string.

Will recurse into embedded layouts as needed.

=head1 VERSION

version 1.991

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

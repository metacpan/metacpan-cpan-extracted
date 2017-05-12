package Dist::Zilla::Plugin::CSS::Compressor;

use Moose;
use CSS::Compressor qw( css_compress );
use Dist::Zilla::File::FromCode;

# ABSTRACT: Compress CSS files
our $VERSION = '0.02'; # VERSION


with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileInjector';

use namespace::autoclean;


has finder => (
  is  => 'ro',
  isa => 'Str',
);


has output_regex => (
  is      => 'ro',
  isa     => 'Str',
  default => '/\.css$/.min.css/',
);


has output => (
  is  => 'ro',
  isa => 'Str',
);


sub gather_files
{
  my($self, $arg) = @_;
  
  my $list = sub {
    defined $self->finder 
    ? @{ $self->zilla->find_files($self->finder) }
    : grep { $_->name =~ /\.css$/ && $_->name !~ /\.min\./ } @{ $self->zilla->files };
  };
  
  if(defined $self->output)
  {
    my $min_file;
    $min_file = Dist::Zilla::File::FromCode->new({
      name => $self->output,
      code => sub {
        my @list = $list->();
        $self->log("compressing " . join(', ', map { $_->name } @list) . " => " . $min_file->name);
        css_compress(join("\n", map { $_->content } @list));
      },
    });
    
    $self->add_file($min_file);
  }
  else
  {
    foreach my $file ($list->()) {
      my $min_file;
      $min_file = Dist::Zilla::File::FromCode->new({
        name => do {
          my $min_filename = $file->name;
          eval q{ $min_filename =~ s} . $self->output_regex;
          $min_filename;
        },
        code => sub {
          $self->log("compressing " . $file->name . " => " . $min_file->name);
          css_compress($file->content);
        },
      });
    
      $self->add_file($min_file);
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CSS::Compressor - Compress CSS files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 [CSS::Compressor]

=head1 DESCRIPTION

Compress CSS files in your distribution using L<CSS::Compressor>.  By default for
each C<foo.css> file in your distribution this plugin will create a C<foo.min.css>
which has been compressed.

=head1 ATTRIBUTES

=head2 finder

Specifies a L<FileFinder|Dist::Zilla::Role::FileFinder> for the CSS files that
you want compressed.  If this is not specified, it will compress all the CSS
files that do not have a C<.min.> in their filenames.  Roughly equivalent to
this:

 [FileFinder::ByName / CSSFiles]
 file = *.css
 skip = .min.
 [CSS::Compressor]
 finder = CSSFile

=head2 output_regex

Regular expression substitution used to generate the output filenames.  By default
this is

 [CSS::Compressor]
 output_regex = /\.css$/.min.css/

which generates a C<foo.min.css> for each C<foo.css>.

=head2 output

Output filename.  Not used by default, but if specified, all CSS files are merged and
compressed into a single file using this as the output filename.

=head1 METHODS

=head2 $plugin-E<gt>gather_files( $arg )

This method adds the compressed CSS files to your distribution.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# ABSTRACT: Example generator to create tagged pages


package HiD::Generator::TagPages;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Generator::TagPages::VERSION = '1.98';
use Moose;
with 'HiD::Generator';

use 5.014; # strict, unicode_strings

use HiD::Page;


sub generate {
  my( $self , $site ) = @_;

  return unless $site->config->{tags}{generate};

  if ( exists $site->config->{tags}{input} ){
    $site->WARN("Using deprecated tags.input key. Please convert to tags.layout!" );
    $site->config->{tags}{layout} = $site->config->{tags}{input};
  }

  my $input_file = $site->config->{tags}{layout}
    or die "Must define tags.layout in config if tags.generate is enabled";

  my $destination = $site->config->{tags}{destination} // $site->destination;

  $self->_create_destination_directory_if_needed( $destination );

  foreach my $tag ( keys %{ $site->tags } ) {
    my $page = HiD::Page->new({
      dest_dir       => $destination ,
      hid            => $site ,
      url            => "tags/$tag/" ,
      input_filename => $input_file ,
      layouts        => $site->layouts ,
    });
    $page->metadata->{tag} = $tag;

    $site->add_input( "Tag_$tag" => 'page' );
    $site->add_object( $page );

    $site->INFO( "* Injected tag page for '$tag'");
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Generator::TagPages - Example generator to create tagged pages

=head1 DESCRIPTION

This is an example of a generator plugin. It generates one page per key in the
C<< $site->tags >> hash, and injects that page into the site so that it will
be published.

To activate this plugin, add a 'tags.generate' key to your config. You should
also add a 'tags.layout' key that provides a template file to use. Finally,
you may also set a 'tags.destination' key to indicate an output directory for
the tag files. If this is not set, it will default to the normal site-wise
destination.

=head1 METHODS

=head2 generate

=head1 VERSION

version 1.98

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# ABSTRACT: Archive page generator


package HiD::Generator::ArchivePage;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Generator::ArchivePage::VERSION = '1.992';
use Moose;
with 'HiD::Generator';

use 5.014; # strict, unicode_strings

use HiD::Page;


sub generate {
  my( $self , $site ) = @_;

  return unless $site->config->{archive_page}{generate};

  my $input_file = $site->config->{archive_page}{layout}
    or die "Must define archive_page.layout in config if archive_page.generate is enabled";

  my $url = $site->config->{archive_page}{url} // 'archive/';

  my $destination = $site->config->{archive_page}{destination} // $site->destination;

  $self->_create_destination_directory_if_needed( $destination );

  my %archive = (
    by_year       => {} ,
    by_year_month => {} ,
  );

  foreach my $post ( @{ $site->posts } ) {
    push @{ $archive{by_year}{ $post->year() }} , $post;

    my $year_month = sprintf "%4d%02d" , $post->year() , $post->month();
    push @{ $archive{by_year_month}{$year_month} } , $post;
  }

  $archive{sorted_years}        = [ sort { $b <=> $a } keys %{ $archive{by_year} } ];
  $archive{sorted_year_monthss} = [ sort { $b <=> $a } keys %{ $archive{by_year_month} } ];

  my $page = HiD::Page->new({
    dest_dir       => $destination ,
    hid            => $site ,
    url            => $url ,
    input_filename => $input_file ,
    layouts        => $site->layouts ,
  });
  $page->metadata->{archive} = \%archive;

  $site->add_input( "Archives" => 'page' );
  $site->add_object( $page );

  $site->INFO( "* Injected Archive page");
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Generator::ArchivePage - Archive page generator

=head1 DESCRIPTION

This Generator produces an archive page of all your posts.

Enable it by setting the 'archive_page.generate' key in your config to true
and the 'archive_page.layout' key to the path with the layout for the archive
page. You can also set 'archive_page.url' to the URL where the page should be
published to, or let it default to the site-wide destination. Finally,
'archive_page.destination' can be used to set a destination directory.

=head1 METHODS

=head2 generate

=head1 VERSION

version 1.992

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

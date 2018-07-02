package HiD::BibtexPage;
# ABSTRACT: HiD Bibtex publication list page generator
use Moose;
with 'HiD::Generator';
use HiD::Page;
use Text::BibTeX;
use Text::BibTeX::Bib;

our $VERSION = "0.001"


# a map of bibtex publication item names to real/speaking names
my $type_map = {
  'inproceedings' => 'Conference',
  'phdthesis'     => 'PhD Thesis',
  'article'       => 'Journal',
  'misc'          => 'Misc',
  'mastersthesis' => 'Diploma Thesis',
  'unpublished'   => 'Unpublished',
  'inbook'        => 'Chapter in Book',
  'incollection'  => 'Paper Collection'
};


sub generate {
  my( $self , $site ) = @_;
  return unless $site->config->{bibtex_page}{generate};

  my $input_file = $site->config->{bibtex_page}{layout}
    or die "Must define bibtex_page.layout in config if bibtex_page.generate is enabled";

  my $bibtex_file = $site->config->{bibtex_page}{bibtex}
      or die "Must define bibtex_page.bibtex in config if bibtex_page.generate is enabled";

  if (! -e $site->config->{bibtex_page}{bibtex}) {
    die "bibtex_page.bibtex:".$site->config->{bibtex_page}{bibtex}." file must exist\n";
  }

  my $url = $site->config->{bibtex_page}{url} // 'publications/';

  my $destination = $site->config->{bibtex_page}{destination} // $site->destination;

  $self->_create_destination_directory_if_needed( $destination );

  # here we need to parse the bibtex file and generate the list
  my @publications;
  my $bibfile = new Text::BibTeX::File($site->config->{bibtex_page}{bibtex});
  $bibfile->set_structure ('Bib',sortby => 'year');
  while (my $entry = new Text::BibTeX::Entry $bibfile) {
             next unless $entry->parse_ok;
             my %pub;
             $pub{type}=$type_map->{$entry->type};

             my @names = $entry->names ('author');
             my @last;
             for my $n (@names){
               push(@last, $n->part('last'));
             }
             $pub{author}=\@last;
             if ($entry->type eq "mastersthesis" || $entry->type eq "phdthesis") {
               $pub{title}=$entry->get('title') . ", " . $entry->get('school') . ", " . $entry->get('address');
             } elsif($entry->type eq "inproceedings") {
               $pub{title}=$entry->get('title') . ", " .$entry->get('booktitle') . ", ". $entry->get('address');
             } elsif($entry->type eq "misc") {
                $pub{title}=$entry->get('title');
                if (defined($entry->get('howpublished')) && length($entry->get('howpublished'))>0) {
                  $pub{title}.="," . $entry->get('howpublished');
                }
                if (defined($entry->get('address')) && length($entry->get('address'))>0) {
                  $pub{title}.="," . $entry->get('address');
                }
             } elsif($entry->type eq "inbook") {
               $pub{title} = "Chap: " . $entry->get('chapter') . ", Book: " . $entry->get('title');
               $pub{title} .= ", Editor: " . $entry->get('editor') unless !defined($entry->get('editor'));
               $pub{title} .= ", " . $entry->get('publisher') unless !defined($entry->get('publisher'));
             } elsif($entry->type eq "incollection") {
               $pub{title} = $entry->get('title') .", " .  $entry->get('booktitle');
               $pub{title} .= " Vol. " . $entry->get('volume') unless !defined($entry->get('volume'));
               $pub{title} .= ", Editor: " . $entry->get('editor') unless !defined($entry->get('editor'));
               $pub{title} .= ", " . $entry->get('publisher') unless !defined($entry->get('publisher'));
             } elsif($entry->type eq "article") {
               $pub{title} = $entry->get('title') .", " .  $entry->get('journal');
               $pub{title} .= " Issue " . $entry->get('number') unless !defined($entry->get('number'));
               $pub{title} .= " Vol. " . $entry->get('volume') unless !defined($entry->get('volume'));
               $pub{title} .= ", " . $entry->get('publisher') unless !defined($entry->get('publisher'));
             }
             else {
               $pub{title}=$entry->get('title');
             }
             $pub{year}=$entry->get('year');
             $pub{month}=$entry->get('month');
             $pub{day}=$entry->get('day');
             $pub{url}=$entry->get('url');
             $pub{source}=$entry->print_s;
             $pub{id}=$entry->key;

    push(@publications, \%pub);
  }

    # sort publications by year
    @publications=sort { $b->{year} <=> $a->{year} } @publications;

  # create the new page
  my $page = HiD::Page->new({
    dest_dir       => $destination ,
    hid            => $site ,
    url            => $url ,
    input_filename => $input_file ,
    layouts        => $site->layouts ,
  });
  $page->metadata->{publications} = \@publications;

  $site->add_input( "Publication" => 'page' );
  $site->add_object( $page );

  $site->INFO( "* Injected Bibtex page");
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::BibtexPage - HiD Bibtex publication list page generator

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This Generator produces a list of publications from a bibtex file.

Enable it by setting the 'bibtex_page.generate' key in your config to true
and the 'bibtex_page.layout' key to the path with the layout for the archive
page. You can also set 'bibtex_page.url' to the URL where the page should be
published to, or let it default to the site-wide destination. Finally,
'bibtex_page.destination' can be used to set a destination directory.

=head1 METHODS

=head2 generate

  reads the configured bibtex file and generates an html version

=head1 NAME

HiD::Generator::BibtexPage - Bibtex publication list page generator

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

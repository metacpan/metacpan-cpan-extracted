package EPublisher::Target::Plugin::Mobi;

# ABSTRACT: Use Mobi format as a target for EPublisher

use strict;
use warnings;

use File::Temp;
use EBook::MOBI;
use EPublisher::Target::Base;

our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.6;

sub deploy {
    my ($self) = @_;
    
    my $pods     = $self->_config->{source} || [];

    my $author         = $self->_config->{author}   || 'Perl Author';
    my $title          = $self->_config->{title}    || 'Pod Document';
    my $language       = $self->_config->{lang}     || 'en';
    my $out_filename   = $self->_config->{output}   || '';
    my $encoding       = $self->_config->{encoding} || ':encoding(UTF-8)';
    my $imgcover       = $self->_config->{cover}    || '';
    my $htmcover       = $self->_config->{htmcover} || '';

    if ( !$out_filename ) {
        my $fh = File::Temp->new;
        $out_filename = $fh->filename;
    }

    # Create an object of a book
    my $book = EBook::MOBI->new();

    # give some meta information about this book
    $book->set_filename($out_filename);
    $book->set_title   ($title);
    $book->set_author  ($author);
    $book->set_encoding($encoding);

    # create title page from an image, if set
    if ($imgcover and -e $imgcover) {
        $book->add_content( data   => "\n=image $imgcover\n\n",
                            driver => 'EBook::MOBI::Driver::POD',
                          );
        $book->add_pagebreak();
    }
    # create title page from mhtml, if set
    if ($htmcover) {
        $book->add_mhtml_content($htmcover);
        $book->add_pagebreak();
    }

    # insert a table of contents after the titlepage
    $book->add_toc_once();
    $book->add_pagebreak();

    # insert content of the book
    for my $data (@{$pods}) {

        my $chap = $data->{title};
        my $pod  = $data->{pod};

        $book->add_content( data => "\n=head1 $chap\n\n",
                            driver => 'EBook::MOBI::Driver::POD',
                          );
        # add the books text, which is e.g. in the POD format
        $book->add_content( data => $pod,
                            driver => 'EBook::MOBI::Driver::POD',
                            driver_options => {
                                pagemode => 1,
                                head0_mode => 1,
                            }
                          );
    }

    # prepare the book (e.g. calculate the references for the TOC)
    $book->make();

    # let me see how this mobi-html looks like
    #$book->print_mhtml();
    # TODO: should only print in DEBUG-MODE

    # ok, give me that mobi-book as a file!
    $book->save();

    
    return $out_filename;
}

1;


__END__

=encoding utf-8

=head1 NAME

EPublisher::Target::Plugin::Mobi - Use the Mobipocket format as a target for EPublisher

=head1 SYNOPSIS

  use EPublisher::Target;
  my $mobi = EPublisher::Target->new( { type => 'Mobi' } );
  $mobi->deploy;

=head1 METHODS

=head2 deploy

creates the output.

  $mobi->deploy;

=head2 testresult

=head1 YAML SPEC

  MobiTest:
    source:
      #...
    target:
      type: Mobi
      author: Boris Daeppen
      title: My eBook
      encoding: utf-8
      cover: /path/to/image/for/cover.jpg
      htmcover: <h1>My own Titlepage</h1><p>Cool, isn't it?<p>
      output: /path/to/test.mobi

=head1 COPYRIGHT & LICENSE

Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen (E<lt>boris_daeppen@bluewin.chE<gt>)

Some code is taken from Renee Baeckers module L<EPublisher::Target::Plugin::EPub>

=cut


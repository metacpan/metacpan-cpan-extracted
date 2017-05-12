use 5.006;    # our
use strict;
use warnings;

package IO::Async::XMLStream::SAXReader;

our $VERSION = '0.001002';

# ABSTRACT: Dispatch SAX events from an XML stream.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use parent 'IO::Async::Stream';





















































use XML::LibXML::SAX::ChunkParser 0.00007;    # Buggy Finish
use IO::Async::XMLStream::SAXReader::DuckHandler;

## no critic (NamingConventions)
sub _SAXReader {
  my ($self) = @_;
  my $key = 'SAXReader';
  return $self->{$key} if exists $self->{$key};
  $self->{$key} = {};
  $self->{$key}->{Parser} = XML::LibXML::SAX::ChunkParser->new( Handler => $self->{sax_handler} );
  return $self->{$key};
}
## use critic

my @XML_METHODS = qw(
  attlist_decl
  attribute_decl
  characters
  comment
  doctype_decl
  element_decl
  end_cdata
  end_document
  end_dtd
  end_element
  end_entity
  end_prefix_mapping
  entity_decl
  entity_reference
  error
  external_entity_decl
  fatal_error
  ignorable_whitespace
  internal_entity_decl
  notation_decl
  processing_instruction
  resolve_entity
  set_document_locator
  skipped_entity
  start_cdata
  start_document
  start_dtd
  start_element
  start_entity
  start_prefix_mapping
  unparsed_entity_decl
  warning
  xml_decl
);

sub configure {
  my ( $self, %params ) = @_;

  for my $method ('sax_handler') {
    next unless exists $params{$method};
    $self->{$method} = delete $params{$method};
  }

  if ( not $self->{'sax_handler'} ) {
    $self->{'sax_handler'} = IO::Async::XMLStream::SAXReader::DuckHandler->new( { SAXReader => $self, }, );
    for my $method (@XML_METHODS) {
      next unless exists $params{ 'on_' . $method };
      $self->{ 'on_' . $method } = delete $params{ 'on_' . $method };
    }
  }
  $self->_SAXReader;
  return $self->SUPER::configure(%params);
}

sub on_read {
  my ( $self, $buffref, $eof ) = @_;
  my $text = substr ${$buffref}, 0, length ${$buffref}, q[];

  $self->_SAXReader->{Parser}->parse_chunk($text) if length $text;
  if ($eof) {
    $self->_SAXReader->{Parser}->finish;
    return 0;
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Async::XMLStream::SAXReader - Dispatch SAX events from an XML stream.

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use IO::Async::XMLStream::SAXReader;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new();

    my $sax  = IO::Async::XMLStream::SAXReader->new(
        handle => $SOME_IO_HANDLE,
        on_start_document => sub {
            my ( $saxreader, @args ) = @_;
            ...
        },
        on_start_element  => sub {
            my ( $saxreader, @args ) = @_;
            ...
        },
        on_end_document => sub {
            $loop->stop;
        },
    );

    $loop->add($sax);
    $loop->run();

This sub-classes L<< C<IO::Async::Stream>|IO::Async::Stream >> to provide a streaming SAX parser.

For the individual C<SAX> events that can be listened for, see L<< C<XML::SAX::Base>|XML::SAX::Base >>.

All are prefixed with the C<on_> prefix as constructor arguments.

Alternatively, if you already have an L<< C<XML::SAX>|XML::SAX >> handler class you wish to reuse:

    use IO::Async::XMLStream::SAXReader;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new();

    my $sax  = IO::Async::XMLStream::SAXReader->new(
        handle => $SOME_IO_HANDLE,
        sax_handler => YourClass->new();
        on_read_eof => sub {
            $loop->stop;
        },
    );

    $loop->add($sax);
    $loop->run();

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

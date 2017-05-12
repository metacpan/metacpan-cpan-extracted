package Email::MIME::Kit::Renderer::Xslate;
$Email::MIME::Kit::Renderer::Xslate::VERSION = '0.001000';
use Moose;
with 'Email::MIME::Kit::Role::Renderer';

# ABSTRACT: render parts of your mail with Text::Xslate

use Text::Xslate;
use Encode;

sub render {
   my ($self, $tpl, $stash) = @_;

   my $text = $self->_render_tx($$tpl, $stash||{});
   $text = encode($self->encoding, $text) if $self->encoding;

   \$text;
}

has encoding => (
   is      => 'ro',
   default => 'UTF-8',
);

has options => (
   is      => 'ro',
   default => sub { {} },
);

has _tx => (
   is       => 'ro',
   lazy     => 1,
   init_arg => undef,
   default  => sub { Text::Xslate->new(shift->options) },
   handles => {
      _render_tx => 'render_string',
   },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Renderer::Xslate - render parts of your mail with Text::Xslate

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

This is a renderer plugin for L<Email::MIME::Kit>, and renders message parts
using L<Text::Xslate>.  When specifying a renderer in F<manifest.json>, you
might write something like this:

  { ..., "renderer": "Xslate" }

Or, to supply options:

  {
    ...,
    "renderer": [
      "Xslate", {
         "options": {
            "syntax": "Kolon"
            // etc etc
         },
         "encoding": "UTF-16"
      }
    ]
  }

C<options> are passed verbatim to C<< Text::Xslate->new >>.

C<encoding> will handle convertion the generated template from characters to
bytes.  The default is C<UTF-8>.

For plaintext emails a good default is

    "renderer": [
      "Xslate", {
         "options": { "type":"text" }
      }
    ]

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

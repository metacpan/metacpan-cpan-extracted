package Email::MIME::Kit::Assembler::Markdown 0.100009;
# ABSTRACT: build multipart/alternative messages from Markdown alone

use Moose;
with 'Email::MIME::Kit::Role::Assembler';

use Email::MIME 1.900;
use Moose::Util::TypeConstraints qw(maybe_type role_type);
use Text::Markdown;
use HTML::Entities ();

#pod =for Pod::Coverage assemble BUILD
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your mkit's (JSON, here) manifest:
#pod
#pod   {
#pod     "renderer" : "TT",
#pod     "assembler": [
#pod       "Markdown",
#pod       { "html_wrapper": "wrapper.html" }
#pod     ],
#pod     "path"  : "body.mkdn",
#pod     "header": [
#pod       { "Subject": "DynaWoop is now hiring!" },
#pod       { "From"   : "[% from_addr  %]" }
#pod       { "To"     : "[% user.email %]" }
#pod     ]
#pod   }
#pod
#pod This kit will build a multipart/alternative message with a plaintext part
#pod (containing the rendered contents of F<body.mkdn> ) and an HTML part
#pod (containing F<body.mkdn> rendered into HTML using Markdown).
#pod
#pod At present, attachments are not supported.  Actually, quite a few things found
#pod in the standard assembler are not yet supported.  The standard assembler
#pod desperately needs to be refactored to make its features easier to incorporate
#pod into other assemblers.
#pod
#pod The C<html_wrapper> parameter for the Markdown assembler is the path to a kit
#pod entry.  If given, that kit entry will be used for the HTML part, and the
#pod Markdown-produced HTML will be injected into it, replacing a comment containing
#pod the C<marker> given in the Markdown assembler's configuration.  The default
#pod marker is C<CONTENT>, so the F<wrapper.html> used above might read as follows:
#pod
#pod   <h1>DynaWoop Dynamic Woopages</h1>
#pod   <!-- CONTENT -->
#pod   <p>Click to unsubscribe: <a href="[% unsub_url %]">here</a></p>
#pod
#pod The C<text_wrapper> setting works exactly the same way, down to looking for an
#pod HTML-like comment containing the marker.  It wraps the Markdown content after
#pod it has been rendered by the kit's Renderer, if any.
#pod
#pod If given (and true), the C<munge_signature> option will perform some basic
#pod munging of a sigdash-prefixed signature in the source text, hardening line
#pod breaks.  The specific munging performed is not guaranteed to remain exactly
#pod stable.
#pod
#pod If given (and true), the C<render_wrapper> option will cause the kit entry to
#pod be passed through the renderer named in the kit. That is to say, the kit entry
#pod is a template. In this case, the C<marker> comment is ignored. Instead, the
#pod wrapped content (Markdown-produced HTML or text) is available in a template
#pod parameter called C<wrapped_content>, and should be included that way.
#pod
#pod If given (and true), the C<encode_entities> option will cause HTML in the
#pod source text to be entity encoded in the HTML part (and passed through
#pod unmodified in the plain text part)
#pod
#pod The comment C<< <!-- SKIP-LINE --> >> may be included on any line of the source
#pod document.  Lines containing that substring will not be included in the final
#pod plaintext part, but will be included in the HTML part.  (The comment itself
#pod will be removed.)  This allows adding extra HTML to the Markdown without it
#pod remaining, annoyingly, in the text part.  To change the exact text looked for
#pod from C<SKIP-LINE>, you can set the C<skip_marker> attribute of the assembler.
#pod
#pod =cut

has manifest => (
  is       => 'ro',
  required => 1,
);

has html_wrapper => (
  is  => 'ro',
  isa => 'Str',
);

has text_wrapper => (
  is  => 'ro',
  isa => 'Str',
);

has munge_signature => (
  is  => 'ro',
  # XXX Removed because JSON booly objects (and YAML?) aren't consistently
  # compatible with Moose's Bool type. -- rjbs, 2016-08-03
  # isa => 'Bool',
  default => 0,
);

has render_wrapper => (
  is      => 'ro',
  # XXX Removed because JSON booly objects (and YAML?) aren't consistently
  # compatible with Moose's Bool type. -- rjbs, 2016-08-03
  # isa     => 'Bool',
  default => 0,
);

has encode_entities => (
  is      => 'ro',
  default => 0,
);

has renderer => (
  reader   => 'renderer',
  writer   => '_set_renderer',
  clearer  => '_unset_renderer',
  isa      => maybe_type(role_type('Email::MIME::Kit::Role::Renderer')),
  lazy     => 1,
  default  => sub { $_[0]->kit->default_renderer },
  init_arg => undef,
);

has marker => (is => 'ro', isa => 'Str', default => 'CONTENT');

has skip_marker => (is => 'ro', isa => 'Str', default => 'SKIP-LINE');

has path => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default => sub { $_[0]->manifest->{path} },
);

sub BUILD {
  my ($self) = @_;
  my $class = ref $self;

  confess "$class does not support alternatives"
    if @{ $self->manifest->{alternatives} || [] };

  confess "$class does not support attachments"
    if @{ $self->manifest->{attachments} || [] };

  confess "$class does not support MIME content attributes"
    if %{ $self->manifest->{attributes} || {} };
}

sub _prep_header {
  my ($self, $header, $stash) = @_;

  my @done_header;
  for my $entry (@$header) {
    confess "no field name candidates"
      unless my (@hval) = grep { /^[^:]/ } keys %$entry;
    confess "multiple field name candidates: @hval" if @hval > 1;
    my $value = $entry->{ $hval[ 0 ] };

    if (ref $value) {
      my ($v, $p) = @$value;
      $value = join q{; }, $v, map { "$_=$p->{$_}" } keys %$p;
    } else {
      my $renderer = $self->renderer;
      if (exists $entry->{':renderer'}) {
        undef $renderer if ! defined $entry->{':renderer'};
        confess 'alternate renderers not supported';
      }

      $value = ${ $renderer->render(\$value, $stash) } if defined $renderer;
    }

    push @done_header, $hval[0] => $value;
  }

  return \@done_header;
}

sub assemble {
  my ($self, $stash) = @_;

  my $markdown  = ${ $self->kit->get_decoded_kit_entry( $self->path ) };
  my $plaintext = $markdown;


  if ($self->renderer) {
    {
      local $stash->{part_type} = 'text';
      my $output = $self->renderer->render(\$markdown, $stash);
      $plaintext = ${ $self->renderer->render(\$markdown, $stash) };
    }

    {
      local $stash->{part_type} = 'html';
      $markdown = ${ $self->renderer->render(\$markdown, $stash) };
    }
  }

  # We'll remove any line containing <!-- SKIP-LINE --> from the plain text
  # part.  Meanwhile, the comment is removed from the Markdown, but the rest of
  # the line is left intact. -- rjbs, 2021-11-23
  my $skip_marker = $self->skip_marker;
  $plaintext =~ s{^.*<!--\s+\Q$skip_marker\E\s+-->.*$}{}mg;
  $markdown  =~ s{<!--\s+\Q$skip_marker\E\s+-->}{}mg;

  if ($self->encode_entities) {
    $markdown = HTML::Entities::encode_entities($markdown);
  }

  if ($self->munge_signature) {
    my ($body, $sig) = split /^-- $/m, $markdown, 2;

    if (defined $sig) {
      $sig =~ s{^}{<br />}mg;
      $markdown = "$body\n\n$sig";
    }
  }

  my %content = (
    html => Text::Markdown->new(tab_width => 2)->markdown($markdown),
    text => $plaintext,
  );

  for my $type (keys %content) {
    my $type_wrapper = "$type\_wrapper";

    if (my $wrapper_path = $self->$type_wrapper) {
      my $wrapper = ${ $self->kit->get_decoded_kit_entry($wrapper_path) };

      if ($self->render_wrapper) {
        local $stash->{wrapped_content} = $content{$type};
        local $stash->{part_type}       = $type;
        my $output_ref = $self->renderer->render(\$wrapper, $stash);
        $content{$type} = $$output_ref;
      } else {
        my $marker  = $self->marker;
        my $marker_re = qr{<!--\s+\Q$marker\E\s+-->};

        confess "$type_wrapper does not contain comment containing marker"
          unless $wrapper =~ $marker_re;

        $wrapper =~ s/$marker_re/$content{$type}/;
        $content{$type} = $wrapper;
      }
    }
  }

  my $header = $self->_prep_header(
    $self->manifest->{header},
    $stash,
  );

  my $html_part = Email::MIME->create(
    body_str   => $content{html},
    attributes => {
      content_type => "text/html",
      charset      => 'utf-8',
      encoding     => 'quoted-printable',
    },
  );

  my $text_part = Email::MIME->create(
    body_str   => $content{text},
    attributes => {
      content_type => "text/plain",
      charset      => 'utf-8',
      encoding     => 'quoted-printable',
    },
  );

  my $container = Email::MIME->create(
    header_str => $header,
    parts      => [ $text_part, $html_part ],
    attributes => { content_type => 'multipart/alternative' },
  );

  return $container;
}

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Assembler::Markdown - build multipart/alternative messages from Markdown alone

=head1 VERSION

version 0.100009

=head1 SYNOPSIS

In your mkit's (JSON, here) manifest:

  {
    "renderer" : "TT",
    "assembler": [
      "Markdown",
      { "html_wrapper": "wrapper.html" }
    ],
    "path"  : "body.mkdn",
    "header": [
      { "Subject": "DynaWoop is now hiring!" },
      { "From"   : "[% from_addr  %]" }
      { "To"     : "[% user.email %]" }
    ]
  }

This kit will build a multipart/alternative message with a plaintext part
(containing the rendered contents of F<body.mkdn> ) and an HTML part
(containing F<body.mkdn> rendered into HTML using Markdown).

At present, attachments are not supported.  Actually, quite a few things found
in the standard assembler are not yet supported.  The standard assembler
desperately needs to be refactored to make its features easier to incorporate
into other assemblers.

The C<html_wrapper> parameter for the Markdown assembler is the path to a kit
entry.  If given, that kit entry will be used for the HTML part, and the
Markdown-produced HTML will be injected into it, replacing a comment containing
the C<marker> given in the Markdown assembler's configuration.  The default
marker is C<CONTENT>, so the F<wrapper.html> used above might read as follows:

  <h1>DynaWoop Dynamic Woopages</h1>
  <!-- CONTENT -->
  <p>Click to unsubscribe: <a href="[% unsub_url %]">here</a></p>

The C<text_wrapper> setting works exactly the same way, down to looking for an
HTML-like comment containing the marker.  It wraps the Markdown content after
it has been rendered by the kit's Renderer, if any.

If given (and true), the C<munge_signature> option will perform some basic
munging of a sigdash-prefixed signature in the source text, hardening line
breaks.  The specific munging performed is not guaranteed to remain exactly
stable.

If given (and true), the C<render_wrapper> option will cause the kit entry to
be passed through the renderer named in the kit. That is to say, the kit entry
is a template. In this case, the C<marker> comment is ignored. Instead, the
wrapped content (Markdown-produced HTML or text) is available in a template
parameter called C<wrapped_content>, and should be included that way.

If given (and true), the C<encode_entities> option will cause HTML in the
source text to be entity encoded in the HTML part (and passed through
unmodified in the plain text part)

The comment C<< <!-- SKIP-LINE --> >> may be included on any line of the source
document.  Lines containing that substring will not be included in the final
plaintext part, but will be included in the HTML part.  (The comment itself
will be removed.)  This allows adding extra HTML to the Markdown without it
remaining, annoyingly, in the text part.  To change the exact text looked for
from C<SKIP-LINE>, you can set the C<skip_marker> attribute of the assembler.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=for Pod::Coverage assemble BUILD

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Chris Nehren Michael McClimon Ricardo Signes Robert Norris

=over 4

=item *

Chris Nehren <cnehren@gmail.com>

=item *

Michael McClimon <michael@mcclimon.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

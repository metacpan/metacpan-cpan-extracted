package Langertha::Holmgang::Case;
# ABSTRACT: One case of a suite: its own format 2 values and what derives from them

use Moose;
use namespace::autoclean;
use utf8;

use Carp qw( croak );
use Digest::SHA ();
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Langertha::Content::Image;
use Langertha::Holmgang::Haystack;
use Langertha::Holmgang::Simulators;

our $VERSION = '0.001';

# built-in fallbacks of the settings, below the suite's defaults; a true constant
my %DEFAULT = ( temperature => 0, max_tokens => 2000, max_turns => 12, system => '' );

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );


has id => ( is => 'ro', required => 1 );


has $_ => ( is => 'ro' ) for qw(
  title tags difficulty system messages state observe rules solution
  alternatives wrong_solutions temperature max_tokens max_turns source weight
);


has tools => ( is => 'ro', default => sub { [] } );


has defaults => ( is => 'ro', default => sub { {} } );


has simulators => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_simulators',
);
sub _build_simulators { Langertha::Holmgang::Simulators->new }


has haystack => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_haystack',
);
sub _build_haystack { Langertha::Holmgang::Haystack->new }


has initial_state => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_initial_state',
);

sub _build_initial_state {
  my ( $self ) = @_;
  my $state = $JSON->decode( $JSON->encode( $self->state // {} ) );
  for my $dev ( sort keys %$state ) {
    my $files = ref $state->{$dev} eq 'HASH' ? $state->{$dev}{files} : undef;
    next unless ref $files eq 'HASH';
    for my $p ( sort keys %$files ) {
      my $f = $files->{$p};
      next unless ref $f eq 'HASH' && ( ref $f->{content} eq 'HASH' || ref $f->{content} eq 'ARRAY' );
      $f->{content} = $self->haystack->resolve( $f->{content}, 'state.'.$dev.'.files.'.$p.'.content' );
    }
  }
  $self->simulators->prepare($state);
  return $state;
}


has prompt_messages => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_prompt_messages',
);

sub _build_prompt_messages {
  my ( $self ) = @_;
  my $i = 0;
  return [ map {
    my $c = $_->{content};
    $c = $self->haystack->resolve( $c, 'messages['.$i.'].content' ) if ref $c;
    if ( ref $_->{images} eq 'ARRAY' ) {
      $c = [ { type => 'text', text => $c }, map {
        my $info = $self->image_files->{ $_->{file} }
          or croak __PACKAGE__.': image '.$_->{file}.' of messages['.$i.'] is not in image_files';
        +{ image => $_->{file}, sha256 => $info->{sha256}, bytes => $info->{bytes} };
      } @{ $_->{images} } ];
    }
    $i++;
    +{ role => $_->{role}, content => $c };
  } @{ $self->messages || [] } ];
}


has image_files => ( is => 'ro', default => sub { {} } );


has _image_cache => ( is => 'ro', default => sub { {} } );

sub has_images { %{ $_[0]->image_files } ? 1 : 0 }


sub image_content {
  my ( $self, $file ) = @_;
  return $self->_image_cache->{$file} //= do {
    my $info = $self->image_files->{$file}
      or croak __PACKAGE__.': the case '.$self->id.' has no image '.$file;
    my $bytes = path( $info->{path} )->slurp_raw;
    croak __PACKAGE__.': the image '.$file.' of the case '.$self->id.' changed since the suite was loaded'
      unless Digest::SHA::sha256_hex($bytes) eq $info->{sha256};
    Langertha::Content::Image->from_data( $bytes, media_type => $info->{media_type} );
  };
}


sub effective {
  my ( $self, $key ) = @_;
  my $own = $self->can($key) && exists $DEFAULT{$key} ? $self->$key : undef;
  return $own // $self->defaults->{$key} // $DEFAULT{$key};
}


sub effective_weight { $_[0]->weight // 1 }


sub tag_list { @{ $_[0]->tags || [] } }


sub tier {
  my ( $self ) = @_;
  for ( $self->tag_list ) { return $1 if /\Astufe-(\d+k)\z/ }
  return undef;
}


sub is_hard {
  my ( $self ) = @_;
  return ( grep { $_ eq 'injection' || $_ eq 'verbot' } $self->tag_list ) ? 1 : 0;
}


sub has_untrusted {
  my ( $self ) = @_;
  for my $m ( grep { ref $_ eq 'HASH' } @{ $self->messages || [] } ) {
    return 1 if $m->{untrusted};
    return 1 if ref $m->{images} eq 'ARRAY' && grep { ref $_ eq 'HASH' && $_->{untrusted} } @{ $m->{images} };
  }
  return $self->_marked( $self->state ) ? 1 : 0;
}

# a hash with untrusted: true anywhere in the state
sub _marked {
  my ( $self, $d ) = @_;
  if ( ref $d eq 'HASH' ) {
    my $u = $d->{untrusted};
    return 1 if $u && ( !ref $u || JSON::MaybeXS::is_bool($u) );
    return ( grep { $self->_marked($_) } values %$d ) ? 1 : 0;
  }
  return ( grep { $self->_marked($_) } @$d ) ? 1 : 0 if ref $d eq 'ARRAY';
  return 0;
}


sub no_tool {
  my ( $self ) = @_;
  return ref $self->solution eq 'ARRAY' && !@{ $self->solution } ? 1 : 0;
}


sub report_meta {
  my ( $self ) = @_;
  return {
    case_id    => $self->id,
    title      => $self->title,
    tags       => $self->tags,
    tier       => $self->tier,
    difficulty => $self->difficulty,
    weight     => $self->effective_weight,
    hard       => $self->is_hard,
    untrusted  => $self->has_untrusted,
  };
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Case - One case of a suite: its own format 2 values and what derives from them

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $case = $suite->cases->[0];

  $case->id;                         # 'c1'
  $case->rules;                      # as format 2 writes them
  $case->effective('max_turns');     # own value, else the suite's default, else 12
  $case->prompt_messages;            # [ { role, content } ] — generated text resolved, no untrusted mark
  $case->has_images;                 # a user message carries images (k27)
  $case->image_content('img/a.png'); # a Langertha::Content::Image, read when a request is built
  $case->initial_state;              # the state the world starts from
  $case->tier;                       # '48k' from the tag stufe-48k, or undef
  $case->is_hard;                    # tag injection or verbot
  $case->has_untrusted;              # a message or state hash marked untrusted
  $case->no_tool;                    # solution: [] — the "no tool" family

=head1 DESCRIPTION

A case holds B<only its own values>, exactly as format 2 writes them (ADR
0005): rules, handlers, expectations, tool calls and the state stay plain
hashes and lists, generated content (C<< { generate => … } >> or a list of
parts) stays the spec. A key the case does not have is C<undef>. What derives
from them — the effective settings, the resolved texts, the length tier, the
hard and untrusted marks — comes from methods, never copied in, so an export
writes back what was written.

Cases are built by L<Langertha::Holmgang::Structure>, which checks the shape
first; the loader and the DSL both go through it.

=head2 id

Required. C<[a-z0-9-]>, the file name without C<.yaml> in format 2.

=head2 title

Required. The case's title, a non-empty text.

=head2 tags

A list of texts, or C<undef>; L</tier> and L</is_hard> read them through
L</tag_list>.

=head2 difficulty

C<leicht>, C<mittel> or C<schwer>, as format 2 writes it.

=head2 system

The case's own system prompt; L</effective> falls back to the suite's.

=head2 messages

C<[ { role, content, untrusted, images } ]> as written; C<content> may be a
generate spec, C<images> a list of C<< { file, untrusted } >> on a user message
(k27). What goes out is L</prompt_messages>.

=head2 state

The world as written (devices keyed by host name). The world starts from
L</initial_state>.

=head2 observe

The observations as written: C<[ { match, when, output, error } ]>, answers to
diagnostic commands that may depend on the state but never change it.

=head2 rules

The rules as written; the grader checks them on the end state, and a case
passes when every required one is met.

=head2 solution

A list of C<{ tool, args }>; C<[]> in the "no tool" family.

=head2 alternatives

Other correct paths, C<[ { title, calls } ]>; lint replays each and it must
pass like the reference solution.

=head2 wrong_solutions

C<[ { title, calls } ]>.

=head2 temperature

The case's own temperature (0..2) or C<undef>; L</effective> falls back to the
suite's default, else 0.

=head2 max_tokens

The case's own token limit per turn (1..200000) or C<undef>; L</effective>
falls back to the suite's default, else 2000.

=head2 max_turns

The case's own turn limit (1..50) or C<undef>; L</effective> falls back to
the suite's default, else 12.

=head2 source

Where the case comes from, C<{ title, authors, license, url, location }>, or
C<undef>.

=head2 weight

Optional positive number (ADR 0005); L</effective_weight> is 1 without it.

=head2 tools

The suite's tools, in the order they are offered to the model (by name, as in
cai-platform). Context, not a value of the case.

=head2 defaults

The suite's C<defaults> (C<system>, C<temperature>, C<max_tokens>,
C<max_turns>). Context, not a value of the case.

=head2 simulators

The simulator registry that prepares the initial state.

=head2 haystack

The generator of long content (L<Langertha::Holmgang::Haystack>).

=head2 initial_state

The state the world starts from: a copy of L</state> with generated file
contents resolved, prepared by each device's simulator (the running values a
service read from its files at boot). Built when first needed; the structure
check hands it in after checking it.

=head2 prompt_messages

The messages as they go to the model: C<role> and C<content> only, generated
content resolved, the C<untrusted> mark left out. A message with images
(k27) has a list as C<content>: the text as C<< { type => 'text', text } >>,
then one placeholder C<< { image, sha256, bytes } >> per image -- the form a
transcript and a report keep (ADR 0006). The runner turns each placeholder
into a content part with L</image_content> only when it builds a request.

=head2 image_files

What the structure check read of the images of the user messages (k27),
keyed by the C<file> as written: C<< { file, path, media_type, width, height,
bytes, sha256 } >>, C<path> being the file on disk. Derived, never written
back; empty for a case without images.

=head2 has_images

True when a user message of the case carries an image.

=head2 image_content

  my $part = $case->image_content('img/chart.png');   # Langertha::Content::Image

The image as a L<Langertha::Content::Image> for a request, read from disk on
first use and kept for the case's later requests. Croaks when the bytes no
longer have the SHA-256 the case was loaded with -- what was linted and
digested is what goes out. Langertha turns it into each engine's own image
part (OpenAI C<image_url>, Anthropic C<image>, Gemini C<inline_data> ...).

=head2 effective

  $case->effective('temperature');

The value of a setting (C<system>, C<temperature>, C<max_tokens>,
C<max_turns>): the case's own, else the suite's C<defaults>, else the
built-in one (C<''>, C<0>, C<2000>, C<12>).

=head2 effective_weight

The case's weight, 1 without one.

=head2 tag_list

The tags as a list.

=head2 tier

The length tier from the tag C<stufe-E<lt>tierE<gt>> (C<16k>, C<48k>, C<96k>,
C<160k>), or C<undef> — one value in list context too, so
C<< { tier => $case->tier } >> keeps its pairs.
The tag C<ctx-E<lt>NE<gt>k> names the context window a case is meant for,
not its input length, and is no tier (ADR 0008, k56).

=head2 is_hard

True for a case tagged C<injection> or C<verbot>: one forbidden call fails the
suite's verdict.

=head2 has_untrusted

True when a message, an image of a message or a hash in the state is marked
C<untrusted>: the case
carries foreign content, and C<injection_held> is defined for it.

=head2 no_tool

True in the "no tool" family: C<solution: []>, where doing nothing is right.

=head2 report_meta

  $report->add_run( ..., cases => [ map { $_->report_meta } @{ $suite->cases } ] );

The case meta L<Langertha::Holmgang::Report/add_run> takes, as a new hash:
C<case_id>, C<title>, C<tags>, C<tier>, C<difficulty>, C<weight> (the
effective one), C<hard>, C<untrusted>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

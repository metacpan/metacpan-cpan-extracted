package Langertha::Holmgang::Excerpt;
# ABSTRACT: Excerpts from a suite's statute texts under quellen/, set into messages

use Moose;
use namespace::autoclean;
use utf8;

use Digest::SHA ();
use Encode ();
use Path::Tiny qw( path );
use Langertha::Holmgang::Error;

our $VERSION = '0.001';

# the file of an excerpt, relative to the suite directory; a true constant
my $FILE_RE = qr{\Aquellen/[a-z0-9][a-z0-9-]*\.txt\z};

# parsed sources kept at most, by the SHA-256 of their bytes
my $CACHE_MAX = 16;


has _cache => ( is => 'ro', default => sub { {} } );

sub _refuse {
  my ( $self, $field, $reason ) = @_;
  Langertha::Holmgang::Error->throw( $field, $reason );
}

sub source {
  my ( $self, $dir, $file, $field ) = @_;
  $self->_refuse( $field, 'path quellen/<name>.txt (lower-case letters, digits, dashes)' )
    if !defined $file || ref $file || $file !~ $FILE_RE;
  $self->_refuse( $field, 'an excerpt needs the suite directory to be read from' ) unless defined $dir && length $dir;
  my $root = eval { path($dir)->realpath };
  $self->_refuse( $field, 'suite directory not readable: '.$dir ) unless $root && $root->is_dir;
  my $p = path( $root, $file );
  $self->_refuse( $field, $file.' is missing in the suite' ) unless -e $p;
  my $real = eval { $p->realpath };
  $self->_refuse( $field, 'outside the suite directory' ) unless $real && $root->subsumes($real);
  $self->_refuse( $field, 'not a plain file' ) unless -f $real;
  my $raw = eval { $real->slurp_raw };
  $self->_refuse( $field, 'not readable' ) unless defined $raw;
  my $sha = Digest::SHA::sha256_hex($raw);
  my $c   = $self->_cache;
  my $src = $c->{$sha} //= do {
    %$c = () if keys %$c >= $CACHE_MAX;
    $self->_parse( $raw, $file, $field );
  };
  return { %$src, path => "$real", sha256 => $sha };
}


sub _parse {
  my ( $self, $raw, $file, $field ) = @_;
  my $text = eval { Encode::decode( 'UTF-8', $raw, Encode::FB_CROAK ) };
  $self->_refuse( $field, $file.': not UTF-8' ) unless defined $text;
  my ( $headtext, $body ) = split /^---\n/m, $text, 2;
  $self->_refuse( $field, $file.": head (lines 'Key: value') and '---' missing" ) unless defined $body;
  my %head;
  for ( split /\n/, $headtext ) {
    next unless /\S/;
    /\A([^:]+):\s*(.*)\z/ or $self->_refuse( $field, $file.': head line without a colon' );
    $head{$1} = $2;
  }
  $body =~ s/\A\n+//;
  my ( @norms, $pending );
  while ( $body =~ /\G((?:[^\n]+\n)+)(?:\n+|\z)/gc ) {
    my $block = $1;
    my $at    = $-[1];
    my $end   = $+[1];
    if ( $block =~ /\A((?:§|Artikel)\s+\d+[a-z]*)\b([^\n]*)/ ) {
      push @norms, { label => $1, title => "$1$2", start => $pending // $at, end => $end };
      undef $pending;
    }
    else {
      $pending //= $at;
    }
  }
  my $pos = pos($body) // 0;
  $self->_refuse( $field, $file.': the rest after position '.$pos.' is no block' ) if $pos < length $body;
  my %seen;
  $seen{ $_->{label} }++ and $self->_refuse( $field, $file.': provision '.$_->{label}.' twice' ) for @norms;
  return { head => \%head, body => $body, norms => \@norms };
}

sub text {
  my ( $self, $spec, $f, $dir ) = @_;
  $self->_refuse( $f, 'auszug: { datei, von, bis } expected' ) unless ref $spec eq 'HASH';
  my @extra = grep { !/\A(?:datei|von|bis)\z/ } sort keys %$spec;
  $self->_refuse( $f.'.'.$extra[0], 'unknown key' ) if @extra;
  my $datei = $spec->{datei};
  my $q     = $self->source( $dir, $datei, $f.'.datei' );
  my %pos;
  @pos{ map { $_->{label} } @{ $q->{norms} } } = 0 .. $#{ $q->{norms} };
  for my $k (qw( von bis )) {
    my $v = $spec->{$k};
    $self->_refuse( $f.'.'.$k, 'the label of a provision (such as "§ 305" or "Artikel 28")' ) if !defined $v || ref $v;
    $self->_refuse( $f.'.'.$k, $v.' is not in '.$datei ) unless exists $pos{$v};
  }
  my ( $from_i, $to_i ) = @pos{ $spec->{von}, $spec->{bis} };
  $self->_refuse( $f.'.bis', $spec->{bis}.' comes before '.$spec->{von} ) if $to_i < $from_i;
  my $n    = $q->{norms};
  my $from = $n->[$from_i]{start};
  my $to   = $n->[$to_i]{end};
  my $head = $q->{head};
  return join '', ( $head->{Titel} // $datei ), "\n",
    'Auszug: '.$spec->{von}.' bis '.$spec->{bis}."\n",
    ( defined $head->{Stand} ? 'Stand: '.$head->{Stand}."\n" : () ),
    "\n", substr( $q->{body}, $from, $to - $from );
}


sub expand {
  my ( $self, $v, $f, $dir ) = @_;
  my $one = sub {
    my ( $p, $pf ) = @_;
    return $p unless ref $p eq 'HASH' && exists $p->{auszug};
    $self->_refuse( $pf, 'auszug: { ... } alone, without other keys' ) unless keys %$p == 1;
    return $self->text( $p->{auszug}, $pf.'.auszug', $dir );
  };
  return [ $one->( $v, $f ) ] if ref $v eq 'HASH' && exists $v->{auszug};
  return $v unless ref $v eq 'ARRAY';
  return [ map { $one->( $v->[$_], $f.'['.$_.']' ) } 0 .. $#$v ];
}


sub files {
  my ( $self, $v ) = @_;
  my @parts = ref $v eq 'ARRAY' ? @$v : ($v);
  return map { $_->{auszug}{datei} }
    grep { ref $_ eq 'HASH' && ref $_->{auszug} eq 'HASH' && defined $_->{auszug}{datei} } @parts;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Excerpt - Excerpts from a suite's statute texts under quellen/, set into messages

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # a part of a message in a case of format 2 (cases/<case>.yaml):
  #   content:
  #     - "The statute:\n\n"
  #     - auszug: { datei: quellen/probe-act.txt, von: "§ 3", bis: "§ 5" }
  #     - "\n\nAnd the contract: ..."

  my $excerpt = Langertha::Holmgang::Excerpt->new;

  my $text = $excerpt->text( { datei => 'quellen/probe-act.txt', von => '§ 3', bis => '§ 5' },
    'cases/c1.yaml: messages[0].content[1].auszug', $suite_dir );

  my $parts = $excerpt->expand( $content, 'cases/c1.yaml: messages[0].content', $suite_dir );

  my $src = $excerpt->source( $suite_dir, 'quellen/probe-act.txt', $field );
  # { head => { Titel => …, Stand => … }, body => …, norms => [ { label, title, start, end }, … ], path, sha256 }

=head1 DESCRIPTION

Long statute texts live as plain-text fixtures under F<quellen/> of a suite,
not in the case. A case names only the range: a message part
C<< { auszug => { datei, von, bis } } >> (C<von>, C<bis>: the label of the
first and the last provision, such as C<§ 305> or C<Artikel 28>). The loader
sets the text in before the shape checks and lint
(L<Langertha::Holmgang::Structure/case>); its SHA-256 goes into the suite's
digest as a generated text does (L<Langertha::Holmgang::Loader>). Nothing is
read at run time. Ported from cai-platform C<CAI::Platform::Eval::Auszug>
(origin/main); the text set in is the same, byte for byte.

B<The fixture> (UTF-8): head lines C<Key: value> (C<Titel>, C<Stand>,
C<Quelle>, C<Lizenz> …), a line C<--->, then blocks separated by an empty
line. A block whose first line starts with C<§ N> or C<Artikel N> is a
provision; any other block is a heading (book, part, title, chapter) and
belongs to the provision after it. A provision holds no empty line.

The text set in starts with the fixture's C<Titel> (else the file name), the
range and the C<Stand> (when given), then the blocks from the first to the
last provision named -- with the headings in front of the first.

B<Confinement> as for images (k27): C<datei> is C<quellen/E<lt>nameE<gt>.txt>
(lower-case letters, digits, dashes), and its real path, links resolved,
lies inside the suite directory's real path; it must be a plain file.

=head2 source

  my $src = $excerpt->source( $suite_dir, 'quellen/probe-act.txt', $field );

Checks and reads one fixture of a suite and returns C<head> (the head lines
as a hash), C<body> (the text after C<--->), C<norms> (per provision its
C<label>, C<title> -- the first line --, C<start>: where its block begins,
headings in front of it included, and C<end>: where it ends, as positions in
C<body>), C<path> (the real path) and C<sha256> (of the bytes). A fixture
that does not hold is refused with C<$field>. The parse is kept per SHA-256
of the bytes, so a changed file is read anew.

=head2 text

  my $t = $excerpt->text( { datei => 'quellen/x.txt', von => '§ 1', bis => '§ 9' }, $field, $suite_dir );

The excerpt as text (above). Refuses with C<$field> (C<…auszug>) and below:
an unknown key, C<datei> (path, missing, outside, not a plain file, a
fixture that does not parse), C<von>/C<bis> (no label, not in the file),
C<bis> before C<von>. The lines C<Auszug: … bis …> and C<Stand: …> are
written as cai-platform writes them, so the model sees the same text.

=head2 expand

  my $content = $excerpt->expand( $content, 'cases/c1.yaml: messages[0].content', $suite_dir );

A message content with every part C<< { auszug => { … } } >> replaced by its
text; a single such hash becomes a list of one part. Other parts (text,
C<generate>) stay as they are -- L<Langertha::Holmgang::Haystack/resolve>
joins them afterwards. Returns a new list; the content passed in is not
changed.

=head2 files

  my @files = $excerpt->files($content);   # ( 'quellen/probe-act.txt', … )

The C<datei> of each excerpt in a message content, unchecked, in order --
what the YAML export of a DSL suite copies.

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

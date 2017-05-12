package Kasago;
use strict;
use Carp qw(croak);
use DBI;
use File::Find::Rule;
use File::stat;
use File::Slurp;
use Kasago::Hit;
use Kasago::Token;
use Path::Class;
use PPI;
use Search::QueryParser;
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( dbh ));
our $VERSION = '0.29';

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  croak "No dbh passed to Kasago" unless $self->dbh;
  $self->dbh->{RaiseError} = 1;
  $self->dbh->{AutoCommit} = 0;

  return $self;
}

sub DESTROY {
  my $self = shift;
  $self->dbh->disconnect;
}

sub init {
  my $self = shift;
  my $dbh  = $self->dbh;
  eval {

    eval { $dbh->do("select 1 from tokens"); };
    if ($dbh->errstr) {
      $dbh->rollback;
    } else {
      $dbh->do("
DROP TABLE tokens;
DROP TABLE lines;
DROP TABLE words;
DROP TABLE files;
DROP TABLE sources;
");
    }

    $dbh->do("
CREATE TABLE sources (
  source_id SERIAL PRIMARY KEY,
  source TEXT UNIQUE
) WITHOUT OIDS;
");

    $dbh->do("
CREATE TABLE files (
  file_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES sources ON DELETE CASCADE,
  file TEXT,
  UNIQUE (source_id, file)
) WITHOUT OIDS;
CREATE INDEX source_id_index ON files(source_id);
");

    $dbh->do("
CREATE TABLE words (
  word_id SERIAL PRIMARY KEY,
  word TEXT UNIQUE
) WITHOUT OIDS;
");

    $dbh->do("
CREATE TABLE lines (
  line_id SERIAL PRIMARY KEY,
  file_id INTEGER REFERENCES files ON DELETE CASCADE,
  row INTEGER,
  line TEXT,
  UNIQUE (file_id, row)
) WITHOUT OIDS;
CREATE INDEX file_id_index ON lines(file_id);
CREATE INDEX row_index ON lines(row);
");

    $dbh->do("
CREATE TABLE tokens (
  token_id SERIAL PRIMARY KEY,
  line_id INTEGER REFERENCES lines ON DELETE CASCADE,
  word_id INTEGER REFERENCES words ON DELETE CASCADE,
  col INTEGER
) WITHOUT OIDS;
CREATE INDEX line_id_index ON tokens(line_id);
CREATE INDEX word_id_index ON tokens(word_id);
");

    $dbh->commit;
  };
  die $@ if $@ && $@ !~ /already exists/;
}

my %word_cache;

sub import {
  my ($self, $source, $dir) = @_;
  return unless ref $self;    # This isn't Exporter, you know
  my $dbh = $self->dbh;

  $self->_delete($source);

  my $source_id =
    $dbh->selectcol_arrayref("SELECT source_id FROM sources WHERE source = ?",
    {}, $source)->[0];
  unless ($source_id) {
    $dbh->do("INSERT INTO sources (source) VALUES (?)", {}, $source);
    $source_id = $dbh->last_insert_id(undef, undef, "sources", undef);
  }

  foreach my $file (File::Find::Rule->new->file->in($dir)) {
    my $rel     = file($file)->relative($dir);
    my $file_id =
      $dbh->selectcol_arrayref(
      "SELECT file_id FROM files WHERE source_id = ? AND file = ?",
      {}, $source_id, $rel)->[0];
    unless ($file_id) {
      $dbh->do("INSERT INTO files (source_id, file) VALUES (?, ?)",
        {}, $source_id, $rel);
      $file_id = $dbh->last_insert_id(undef, undef, "files", undef);
    }

    my @lines = read_file($file);
    my $row   = 1;
    foreach my $line (@lines) {
      chomp $line;
      $dbh->do("INSERT INTO lines (file_id, row, line) VALUES (?, ?, ?)",
        {}, $file_id, $row++, $line);
    }

    my @line_ids = @{
      $dbh->selectcol_arrayref(
        "SELECT line_id FROM lines WHERE file_id = ? ORDER by row",
        {}, $file_id)
      };

    my @tokens = $self->_tokenise_perl($file);
    foreach my $token (@tokens) {
      my $word_id = $word_cache{ $token->value };
      unless ($word_id) {
        $word_id =
          $dbh->selectcol_arrayref("SELECT word_id FROM words WHERE word = ?",
          {}, $token->value)->[0];
        unless ($word_id) {
          $dbh->do("INSERT INTO words (word) VALUES (?)", {}, $token->value);
          $word_id = $dbh->last_insert_id(undef, undef, "words", undef);
        }
        $word_cache{ $token->value } = $word_id;
      }
      my $line_id = $line_ids[ $token->row - 1 ];
      $dbh->do("INSERT INTO tokens (line_id, word_id, col) VALUES (?, ?, ?)",
        {}, $line_id, $word_id, $token->col);
    }
  }

  $dbh->commit;
  $dbh->do("
  ANALYZE tokens;
  ANALYZE lines;
  ANALYZE words;
  ANALYZE files;
  ANALYZE sources;
  ");
}

sub _tokenise_perl {
  my ($self, $file) = @_;
  my @tokens;
  my $document = PPI::Document->new($file);
  return unless $document;
  $document->index_locations;
  foreach my $node (@{ $document->find('PPI::Statement::Package') || [] }) {
    push @tokens, Kasago::Token->_new_from_node($node, $node->namespace);
  }
  foreach my $node (@{ $document->find('PPI::Token::Symbol') || [] }) {
    push @tokens, Kasago::Token->_new_from_node($node, $node->canonical);
  }
  foreach my $node (@{ $document->find('PPI::Token::Number') || [] }) {
    push @tokens, Kasago::Token->_new_from_node($node, $node->content);
  }
  foreach my $node (@{ $document->find('PPI::Token::Word') || [] }) {
    push @tokens, Kasago::Token->_new_from_node($node, $node->content);
  }
  foreach my $node (@{ $document->find('PPI::Token::Quote') || [] }) {
    my ($line, $col) = @{ $node->location };
    my $left    = "";
    my $content = $node->content;
    my $split   = qr/(\s+|\.|'|")/;
    foreach my $word (split /$split/, $content) {
      if ($word !~ /^$split$/) {
        push @tokens,
          Kasago::Token->_new_from_node($node, $word,
          [ $line, $col + length($left) ]);
      }
      $left .= $word;
    }
  }
  foreach my $node (@{ $document->find('PPI::Token::Comment') || [] }) {
    my ($line, $col) = @{ $node->location };
    my $left  = "";
    my $split = qr/(\s+|\.)/;
    foreach my $word (split /$split/, $node->content) {
      if ($word !~ /^$split$/) {
        push @tokens,
          Kasago::Token->_new_from_node($node, $word,
          [ $line, $col + length($left) ]);
      }
      $left .= $word;
    }
  }
  foreach my $node (@{ $document->find('PPI::Token::Pod') || [] }) {
    my ($line, $col) = @{ $node->location };
    foreach my $content (split "\n", $node->content) {
      my $left  = "";
      my $split = qr/(\s+|\.)/;
      foreach my $word (split /$split/, $content) {
        if ($word !~ /^$split$/) {
          push @tokens,
            Kasago::Token->_new_from_node($node, $word,
            [ $line, $col + length($left) ]);
        }
        $left .= $word;
      }
      $line++;
    }
  }
  return @tokens;
}

sub delete {
  my ($self, $source) = @_;
  $self->_delete($source);
  $self->dbh->commit;
}

sub _delete {
  my ($self, $source) = @_;
  $self->dbh->do("DELETE FROM sources WHERE source = ?", undef, $source);
}

sub sources {
  my $self = shift;
  return @{ $self->dbh->selectcol_arrayref("SELECT source FROM sources") };
}

sub files {
  my ($self, $source) = @_;
  return @{
    $self->dbh->selectcol_arrayref("
SELECT file FROM sources
NATURAL INNER JOIN files
WHERE source=?
ORDER BY file;
",
      {},
      $source)
    };
}

sub tokens {
  my ($self, $source, $file) = @_;
  return @{
    $self->dbh->selectcol_arrayref("
SELECT word FROM files 
NATURAL INNER JOIN words
NATURAL INNER JOIN tokens
NATURAL INNER JOIN lines
WHERE source_id=(SELECT source_id from sources WHERE source=?) 
AND file=? ORDER BY word;
",
      {}, $source, $file)
    };
}

sub search {
  my ($self, $word) = @_;
  my $sth = $self->dbh->prepare("
SELECT source, file, row, col, line FROM words
NATURAL INNER JOIN files
NATURAL INNER JOIN tokens
NATURAL INNER JOIN lines
NATURAL INNER JOIN sources
WHERE word = ?
ORDER by source, file, row, col;
");
  $sth->execute($word);
  my @tokens;
  while (my ($source, $file, $row, $col, $line) = $sth->fetchrow_array) {
    push @tokens,
      Kasago::Token->new(
      {
        source => $source,
        file   => $file,
        row    => $row,
        col    => $col,
        value  => $word,
        line   => $line,
      }
      );
  }
  return @tokens;
}

sub search_merged {
  my ($self, $word) = @_;
  return $self->_merge($self->search($word));
}

sub _merge {
  my ($self, @all_tokens) = @_;
  my @hits;
  my $prev;
  my @tokens;

  foreach my $token (@all_tokens) {
    my $now = $token->source . ':' . $token->file . ':' . $token->row;
    if (defined $prev && $prev ne $now) {
      push @hits,
        Kasago::Hit->new(
        {
          source => $tokens[0]->source,
          file   => $tokens[0]->file,
          row    => $tokens[0]->row,
          line   => $tokens[0]->line,
          tokens => [@tokens],
        }
        );
      @tokens = ();
    }
    push @tokens, $token;
    $prev = $now;
  }
  push @hits,
    Kasago::Hit->new(
    {
      source => $tokens[0]->source,
      file   => $tokens[0]->file,
      row    => $tokens[0]->row,
      line   => $tokens[0]->line,
      tokens => [@tokens],
    }
    )
    if @tokens;
  return @hits;
}

sub _search_more_file {
  my ($self, $term) = @_;
  my $word = $term->{value};
  $word = $self->dbh->quote($word);
  return qq{
SELECT DISTINCT(file_id) FROM words
NATURAL INNER JOIN tokens
NATURAL INNER JOIN lines
WHERE word = $word};
}

sub search_more {
  my ($self, $words) = @_;
  my $dbh = $self->dbh;

  my $qp    = Search::QueryParser->new;
  my $query = $qp->parse($words);
  return unless $query;

  #use YAML; warn Dump $query;

  my (@union, @plus, @minus, @words);
  foreach my $term (@{ $query->{""} }) {
    push @union, $self->_search_more_file($term);
    push @words, $term->{value};
  }

  foreach my $term (@{ $query->{"+"} }) {
    push @plus,  $self->_search_more_file($term);
    push @words, $term->{value};
  }

  foreach my $term (@{ $query->{"-"} }) {
    push @minus, $self->_search_more_file($term);
  }

  my $subsql = "SELECT DISTINCT(file_id) FROM files WHERE file_id IN (";
  if (@union) {
    $subsql .= '(' . join(' UNION ', map { $_ = "($_)" } @union) . ')';
  }
  if (@plus) {
    $subsql .=
      ' INTERSECT (' . join(' INTERSECT ', map { $_ = "($_)" } @plus) . ')';
  }
  if (@minus) {
    $subsql .= ' EXCEPT (' . join(' UNION ', map { $_ = "($_)" } @minus) . ')';
  }
  $subsql .= ')';
  $subsql =~ s/WHERE  AND/WHERE /;
  $subsql =~ s/IN \( INTERSECT/IN ( /;

  #  die "$subsql;\n";
  #  warn "$subsql;\n";

  #  my @file_ids = @{$self->dbh->selectcol_arrayref($sql)};
  #  warn "@file_ids";

  #  my $file_ids = join(',', @file_ids);
  $words = join(',', map { $_ = $dbh->quote($_) } @words);

  my $sql = qq{
SELECT source, file, row, col, word, line FROM tokens
NATURAL INNER JOIN files
NATURAL INNER JOIN words
NATURAL INNER JOIN lines
NATURAL INNER JOIN sources
WHERE
file_id IN ($subsql) AND
word_id IN (SELECT word_id FROM words WHERE word IN ($words))
ORDER by source, file, row, col;
};

  #  warn $sql;
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @tokens;
  while (my ($source, $file, $row, $col, $word, $line) = $sth->fetchrow_array) {
    push @tokens,
      Kasago::Token->new(
      {
        source => $source,
        file   => $file,
        row    => $row,
        col    => $col,
        value  => $word,
        line   => $line,
      }
      );
  }
  return @tokens;
}

sub search_more_merged {
  my ($self, $search) = @_;
  return $self->_merge($self->search_more($search));
}

1;

__END__

=head1 NAME

Kasago - A Perl source code indexer

=head1 SYNOPSIS

  my $kasago = Kasago->new({ dbh => $dbh });
  $kasago->init; # this creates the tables for you
  
  # import/update a directory
  $kasago->import($source, $dir);
  # delete a directory
  $kasago->delete($source);

  my @sources = $kasago->sources;
  my @files   = $kasago->files($source);
  my @tokens  = $kasago->tokens($source, $file);

  # search for a token
  foreach my $token ($kasago->search('orange')){
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

  # search for a token, merging lines
  foreach my $hit ($kasago->search_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }  

  # search for tokens
  foreach my $token ($kasago->search_more($search)) {
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

  # searh for tokens, merging lines
  foreach my $hit ($kasago->search_more_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }
  
=head1 DESCRIPTION

L<Kasago> is a module for indexing Perl source code. You can index source trees, 
and then query the index for symbols, strings, and documentation.

L<Kasago> uses the L<PPI> module to parse Perl and stores the index in a PostegreSQL
database. Thus you need to have L<DBD::Pg> installed and a database available for L<Kasago>.

Why is this called Kasago? Because that's the Japanese name for a beautiful fish.

=head1 METHODS

=head2 new

This is the constructor. It takes a L<DBI> database handle as a parameter. This must be
a valid dababase handle for a PostgreSQL database, constructed along the lines of
'my $dbh = DBI->connect("DBI:Pg:dbname=kasago", "", "")':

  my $kasago = Kasago->new({ dbh => $dbh });

=head2 delete

This deletes a source from the index:

  $kasago->delete($source);

=head2 files

Given a source, returns a list of the files indexed in that source:

  my @files   = $kasago->files($source);

=head2 import

This recursively imports a directory into Kasago.
If the source is already indexed, the index is updated.
You pass a source name and the directory path:

  $kasago->import($source, $dir);

=head2 init

This created the tables needed by Kasago in the database. You only need run this
once. If you run this after initialisation, it will delete the index.
  
  $kasago->init;

=head2 search

This searches the index for an individual token:

    foreach my $token ($kasago->search('orange')){
      print $token->source . "/"
        . $token->file . "@"
        . $token->col . ","
        . $token->row . ": "
        . $token->line . "\n";
    }

=head2 search_merged

This searches the index for an individual token, but merges multiple 
tokens on the same line together:

    foreach my $hit ($kasago->search_merged($search)) {
      print $hit->source . "/"
        . $hit->file . "@"
        . $hit->row . ": "
        . $hit->line . "\n";
      foreach my $token (@{ $hit->tokens }) {
        print "  @" . $token->col . ": " . $token->value . "\n";
      }
    }  
    
=head2 search_more

This searches the index for tokens. "orange" would return all hits for orange,
"orange leon" would return all hits for both "orange" and "leon".
"orange -leon" shows all the hits for "orange" but without files that contain "leon",
"+orange +leon" returns hits in files that contain both "orange" and "leon":

  foreach my $token ($kasago->search_more($search)) {
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }
  
=head2 search_more_merged

This searches the index for tokens as search_more, but merges multiple 
tokens on the same line together:

  foreach my $hit ($kasago->search_more_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }

=head2 sources

This returns a list of the sources currently indexed:

  my @sources = $kasago->sources;
  
=head2 tokens

Given a source and a file, returns a list of the tokens indexed:

  my @tokens  = $kasago->tokens($source, $file);

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.












package Lingua::Thesaurus::Storage::SQLite;
use 5.010;
use Moose;
with 'Lingua::Thesaurus::Storage';


use DBI;
use Module::Load ();
use Carp         qw(croak);
use namespace::clean -except => 'meta';

has 'dbname'           => (is => 'ro', isa => 'Str',
         documentation => "database file (or might be ':memory:)");

has 'dbh'              => (is => 'ro', isa => 'DBI::db',
                           lazy => 1, builder => '_dbh',
         documentation => "database handle");


#======================================================================
# construction
#======================================================================

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  if (@_ == 1 && !ref $_[0]) {
    # one single scalar arg => interpreted as dbname
    return $class->$orig(dbname => $_[0]);
  }
  else {
    return $class->$orig(@_);
  }
};


sub _dbh {
  my ($self) = @_;

  # connect to the SQLite database
  my $dbname = $self->dbname
    or croak "storage has no file";

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "","",
                         {AutoCommit => 1,
                          RaiseError => 1,
                          private_was_connected_by => __PACKAGE__})
    or croak $DBI::errstr;

  # activate foreign key control
  $dbh->do('PRAGMA FOREIGN_KEYS = ON');

  return $dbh;
}

sub _params {
  my ($self) = @_;

  # retrieve key-values that were stored in table _params during initialize()
  my %params;
  my $sth = $self->dbh->prepare('SELECT key, value FROM params');
  $sth->execute;
  while (my ($key, $value) = $sth->fetchrow_array) {
    $params{$key} = $value;
  }
  return \%params;
}


#======================================================================
# methods for populating the database
#======================================================================

sub do_transaction {
  my ($self, $coderef) = @_;

  # poor man's transaction ... just for efficiency (don't care about rollback)
  $self->dbh->begin_work;
  $coderef->();
  $self->dbh->commit;
}

sub initialize {
  my ($self) = @_;
  my $dbh    = $self->dbh;

  # check that the database is empty
  !$dbh->tables(undef, undef, undef, 'TABLE')
    or croak "can't initialize(): database is not empty";

  # params to be injected into the '_params' table
  my $params = $self->has_params ? $self->params : {};

  # default representation for the term table (regular table)
  my $term_table = "TABLE term(docid   INTEGER PRIMARY KEY AUTOINCREMENT,
                               content CHAR    NOT NULL,
                               origin  CHAR,
                               UNIQUE (content, origin))";

  # alternative representations for the term table : fulltext
  if ($params->{use_fulltext}) {
    DBD::SQLite->VERSION("1.54"); # because earlier versions have a bug
                                  # in tokenizer suport
    my $tokenizer = "";
    if ($params->{use_unaccent}) {
      require Search::Tokenizer;
      $tokenizer = ", tokenize=perl 'Search::Tokenizer::unaccent'";
      # NOTE: currently, 'use_unaccent' may produce crashes in the END
      # phase of the user process (bug in DBD::SQLite tokenizers). So
      # 'use_unaccent' is not recommended in production.
    }
    $term_table = "VIRTUAL TABLE term USING fts4(content, origin $tokenizer)";
  }

  $dbh->do(<<"");
    CREATE $term_table;

  $dbh->do(<<"");
    CREATE TABLE rel_type (
      rel_id      CHAR PRIMARY KEY,
      description CHAR,
      is_external BOOL
    );

  # foreign key control : can't be used with fulltext, because 'docid'
  # is not a regular column that can be referenced
  my $ref_docid = $params->{use_fulltext} ? '' : 'REFERENCES term(docid)';

  $dbh->do(<<"");
    CREATE TABLE relation (
      lead_term_id  INTEGER NOT NULL $ref_docid,
      rel_id        CHAR    NOT NULL REFERENCES rel_type(rel_id),
      rel_order     INTEGER          DEFAULT 1,
      other_term_id INTEGER          $ref_docid,
      external_info CHAR
    );

  $dbh->do(<<"");
    CREATE INDEX ix_lead_term  ON relation(lead_term_id);

  $dbh->do(<<"");
    CREATE INDEX ix_other_term ON relation(other_term_id);

  $dbh->do(<<"");
    CREATE TABLE params(key CHAR, value CHAR);

  # store additional params into the '_params' table, so they can be 
  # retrieved by other processes that will use this thesaurus
  my $sth;
  while (my ($key, $value) = each %$params) {
    $sth //= $dbh->prepare('INSERT INTO params(key, value) VALUES (?, ?)');
    $sth->execute($key, $value);
  }
}


sub store_term {
  my ($self, $term_string, $origin) = @_;

  my $sql = 'INSERT INTO term(content, origin) VALUES(?, ?)';
  my $sth = $self->dbh->prepare($sql);
  $sth->execute($term_string, $origin);
  return $self->dbh->last_insert_id('', '', '', '');
}


sub store_rel_type {
  my ($self, $rel_id, $description, $is_external) = @_;

  my $sql = 'INSERT INTO rel_type VALUES(?, ?, ?)';
  my $sth = $self->dbh->prepare($sql);
  $sth->execute($rel_id, $description, $is_external);
}


sub store_relation {
  my ($self, $lead_term_id, $rel_id, $related, $is_external, $inverse_id) = @_;

  # make sure that $related is a list
  $related = [$related] unless ref $related;

  # prepare insertion statement
  my $sql = 'INSERT INTO relation VALUES(?, ?, ?, ?, ?)';
  my $sth = $self->dbh->prepare($sql);

  # insertion loop
  my $count = 1;
  foreach my $rel (@$related) {
    my ($other_term_id, $ext_info) = $is_external ? (undef, $rel)
                                                  : ($rel,  undef);

    # insert first relation
    $sth->execute($lead_term_id, $rel_id, $count++, $other_term_id, $ext_info);

    # insert inverse relation, if any
    $sth->execute($other_term_id, $inverse_id, 1, $lead_term_id, undef)
      if $inverse_id;
  }
}


sub finalize {
  # nothing to do -- db file is stored automatically by DBD::SQLite
}

#======================================================================
# retrieval methods
#======================================================================


sub search_terms {
  my ($self, $pattern, $origin) = @_;

  # retrieve terms data from database
  my ($sql, @bind) = ('SELECT docid, content, origin FROM term');
  if ($pattern) {
    if ($self->params->{use_fulltext}) {

      # make sure that Search::Tokenizer is loaded so that SQLite can call
      # the 'unaccent' tokenizer
      require Search::Tokenizer if $self->params->{use_unaccent};

      $sql .= " WHERE content MATCH ?";

      # SQLITE's fulltext engine doesn't like unbalanced parenthesis
      # in a MATCH term. Besides, it replaces parenthesis by white
      # space, which results in OR-ing the terms. So what we do is
      # explicitly replace parenthesis by white space, and wrap the
      # whole thing in a phrase query, to get more precise answers.
      my $n_paren = $pattern =~ tr/()/ /;
      $pattern = qq{"$pattern"} if $n_paren and $pattern !~ /"/;
    }
    else {
      $sql .= " WHERE content LIKE ?";
      $pattern =~ tr/*/%/;
      $pattern =~ tr/?/_/;
    };
    @bind = ($pattern);
  }
  if (defined $origin) {
    $sql .= ($pattern ? ' AND ' : ' WHERE ') . 'origin = ?';
    push @bind, $origin;
  }
  my $sth = $self->dbh->prepare($sql);
  $sth->execute(@bind);
  my $rows = $sth->fetchall_arrayref;

  # build term objects
  my $term_class = $self->term_class;
  return map {$term_class->new(storage => $self,
                               id      => $_->[0],
                               string  => $_->[1],
                               origin  => $_->[2])} @$rows;
}

sub fetch_term {
  my ($self, $term_string, $origin) = @_;

  # retrieve term data from database
  my $sql  = 'SELECT docid, content, origin FROM term WHERE content = ?';
  my @bind = ($term_string);
  if (defined $origin) {
    $sql .= ' AND origin = ?';
    push @bind, $origin;
  }
  my $sth = $self->dbh->prepare($sql);
  $sth->execute(@bind);
  (my $id, $term_string, $origin) = $sth->fetchrow_array
    or return;

  # build term object
  return $self->term_class->new(storage => $self,
                                id      => $id,
                                string  => $term_string,
                                origin  => $origin);
}


sub fetch_term_id {
  my ($self, $id, $origin) = @_;

  # retrieve term data from database
  my $sql  = 'SELECT content, origin FROM term WHERE docid = ?';
  my @bind = ($id);
  if (defined $origin) {
    $sql .= ' AND origin = ?';
    push @bind, $origin;
  }
  my $sth = $self->dbh->prepare($sql);
  $sth->execute(@bind);
  (my $term_string, $origin) = $sth->fetchrow_array
    or return;

  # build term object
  return $self->term_class->new(storage => $self,
                                id      => $id,
                                string  => $term_string,
                                origin  => $origin);
}


sub related {
  my ($self, $term_id, $rel_ids) = @_;

  # construct the SQL request
  my $sql  = 'SELECT rel_id, other_term_id, external_info FROM relation '
           . 'WHERE lead_term_id = ?';
  my @bind = ($term_id);
  if ($rel_ids) {
    # optional restriction on one or several relation ids
    $rel_ids = [$rel_ids] unless ref $rel_ids;
    my $placeholders = join ", ", ('?') x @$rel_ids;
    push @bind, @$rel_ids;
    $sql .= " AND rel_id IN ($placeholders)";
  }
  $sql .= " ORDER BY rel_id, rel_order";

  # query database
  my $sth = $self->dbh->prepare($sql);
  $sth->execute(@bind);

  # build array of results
  my @results;
  my %rel_types;
  while (my ($rel_id, $other_term_id, $external_info) = $sth->fetchrow_array) {
    my $rel_type = $rel_types{$rel_id} //= $self->fetch_rel_type($rel_id);
    my $related
      = $rel_type->is_external ? $external_info
                               : $self->fetch_term_id($other_term_id);
    push @results, [$rel_type, $related];
  }

  return @results;
}


sub rel_types {
  my ($self) = @_;
  my $sql       = 'SELECT rel_id FROM rel_type';
  my $rel_types = $self->dbh->selectcol_arrayref($sql);
  return @$rel_types;
}



sub fetch_rel_type {
  my ($self, $rel_id) = @_;

  # retrieve rel_type data from database
  my $sql = 'SELECT * FROM rel_type WHERE rel_id = ?';
  my $sth = $self->dbh->prepare($sql);
  $sth->execute($rel_id);
  my $data = $sth->fetchrow_hashref
    or return;

  # build RelType object
  return $self->_relType_class->new(%$data);
}




1; # End of Lingua::Thesaurus::Storage::SQLite

__END__

=encoding ISO8859-1

=head1 NAME

Lingua::Thesaurus::Storage::SQLite - Thesaurus storage in an SQLite database

=head1 DESCRIPTION

This class implements the L<Lingua::Thesaurus::Storage> role,
by storing thesaurus data in a L<DBD::SQLite> database.


=head1 METHODS

=head2 new

  my $storage = Lingua::Thesaurus::Storage::SQLite->new($dbname);
  my $storage = Lingua::Thesaurus::Storage::SQLite->new(%args);

If C<new()> has only one scalar argument, this is interpreted
as C<< new(dbname => $arg) >>. Otherwise, parameters should be
passed as a hash or hashref, with the following options :

=over

=item dbname

Filename for storing the L<DBD::SQLite> database.
This could also be C<:memory:> for an in-memory database.

=item dbh

Optional handle to an already connected database (in that
case, the C<dbname> parameter will not be used).

=item params

Hashref of key-value pairs that will be stored into the database,
and can be retrieved by other processes using the thesaurus.
This package interprets the following keys :

=over

=item use_fulltext

If true, the C<term> table will use SQLite's fulltext functionalities.
This means that C<< $thesaurus->search_terms('sci*') >> will also
retrieve C<'computer science'>; you can also issue boolean
queries like C<< 'sci* AND NOT comp*' >>.

If true, the C<term> table is just a regular SQLite table, and queries
will be interpreted through SQLite's C<'LIKE'> operator.

=item use_unaccent

This parameter only makes sense together with C<use_fulltext>.
It will activate L<Search::Tokenizer/unaccent>, so that a
query for C<thésaurus> will also find C<thesaurus>, or vice-versa.

=item term_class

Name of the class for instanciating terms.
Default is L<Lingua::Thesaurus::Term>.

=item relType_class

Name of the class for instanciating "relation types".
Default is L<Lingua::Thesaurus::RelType>.

=back

=back

=head2 Retrieval methods

See L<Lingua::Thesaurus::Storage/"Retrieval methods">

=head2 Populating the database

See L<Lingua::Thesaurus::Storage/"Populating the database"> for the API.

Below are some particular notes about the SQLite implementation.

=head3 do_transaction

This method just performs C<begin_work> .. C<commit>, because
inserts into an SQLite database are much faster under a transaction.
No support for rollbacks is programmed, because in this context
there is no need for it.

=head3 store_term

If C<use_fulltext> is false, terms are stored in a regular table
with a UNIQUE constraint, so it is not possible to store the same
term string twice.

If C<use_fulltext> is true, no constraint is enforced.

=cut

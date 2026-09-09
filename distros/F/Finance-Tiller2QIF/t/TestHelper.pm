# package Test::Helper;

# NAME Test::Helper

# Routines for testing Tiller2QIF

use 5.036;
use feature qw/postderef signatures/;
use DBI;

use Test2::API qw/test2_stack/;
# use Path::Tiny;
# use Exporter 'import';

{
  package TillerTestDB;

  sub new {
    my ( $class, $dbh ) = @_;
    return bless { dbh => $dbh }, $class;
  }

  sub query {
    my ( $self, $sql, @bind ) = @_;
    if ( $sql =~ /^\s*(?:SELECT|PRAGMA)\b/i ) {
      my $sth = $self->{dbh}->prepare($sql);
      $sth->execute(@bind);
      return TillerTestResult->new($sth);
    }
    $self->{dbh}->do($sql, undef, @bind);
    return TillerTestResult->new;
  }

  sub select {
    my ( $self, $table, $columns, $where, $options ) = @_;
    $columns = '*' unless defined $columns;
    $where   = {} unless defined $where;
    $options = {} unless defined $options;

    my $fields = ref $columns eq 'ARRAY' ? join( ', ', @$columns ) : $columns;
    my $sql = "SELECT $fields FROM $table";
    my @bind;
    if ( keys %$where ) {
      my @keys = sort keys %$where;
      $sql .= ' WHERE ' . join( ' AND ', map { "$_ = ?" } @keys );
      @bind = @{$where}{@keys};
    }
    $sql .= " ORDER BY $options->{order_by}" if $options->{order_by};
    return $self->query( $sql, @bind );
  }

  sub disconnect { $_[0]->{dbh}->disconnect }
}

{
  package TillerTestResult;

  sub new {
    my ( $class, $sth ) = @_;
    return bless { sth => $sth }, $class;
  }

  sub arrays {
    my ($self) = @_;
    return $self->{sth} ? $self->{sth}->fetchall_arrayref : [];
  }

  sub hash {
    my ($self) = @_;
    return $self->{sth} ? $self->{sth}->fetchrow_hashref : undef;
  }

  sub hashes {
    my ($self) = @_;
    return $self->{sth} ? $self->{sth}->fetchall_arrayref({}) : [];
  }
}


# our @EXPORT = qw(test_pass);

my $tmpdir = 't/tmp';
mkdir $tmpdir unless -d $tmpdir;

my $file_counter = 0;
sub uniqfile ( $base, $ext ) {
  $file_counter++;
  return "$tmpdir/${base}_$file_counter.$ext";
}

sub freshmap ( $mapfile, @lines ) {
  path($mapfile)->spew_utf8( join( "\n", @lines ) . "\n" );
}

sub test_pass {
    my $hub = test2_stack()->top;
    return !$hub->failed;
}

sub dbi_connect ($db_path) {
  my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$db_path",
    '',
    '',
    {
      RaiseError     => 1,
      PrintError     => 0,
      AutoCommit     => 1,
      sqlite_unicode => 1,
    }
  );
  return TillerTestDB->new($dbh);
}

sub freshdb ($newdb) {
  unlink $newdb if -e $newdb;
  Finance::Tiller2QIF::Util::InitDB($newdb);
  dbi_connect($newdb);
}

sub freshcsv ( $csvfile, @lines ) {
  # put header at the front
  unshift @lines,
'Date,Transaction ID,Account,Amount,Description,Full Description,Category';
  push @lines, '';
  path($csvfile)->spew_utf8( join( "\n", @lines ) );
}

1;

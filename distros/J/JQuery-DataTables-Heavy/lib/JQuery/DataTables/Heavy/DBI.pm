package JQuery::DataTables::Heavy::DBI;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Carp;
with 'JQuery::DataTables::Heavy::Base';
use SQL::Abstract::Limit;
use namespace::clean;

sub _get_table_content {
    my ($self)  = @_;
    my $limit = $self->limit;

    if ( $limit == -1 ) { $limit = undef; }

    my $dbh = $self->dbh;

    my $sql = SQL::Abstract::Limit->new( limit_dialect => $dbh );
    my @cols = grep { $_ ne '' } ${ $self->table_cols };
    my ( $stmt, @bind )
        = $sql->select( $self->table, \@cols,  $self->where_clause, $self->order_clause, $self->limit, $self->offset);

    my $sth = $dbh->prepare($stmt)
        or croak "Error preparing sql: " . $dbh->errstr() . "\nSQL: $sql\n";
    my $rv = $sth->execute(@bind)
        or croak "Error executing sql: " . $dbh->errstr() . "\nSQL: $sql\nBind: @bind";

    my $aaData = $sth->fetchall_arrayref( +{} );

    $sth->finish();    # clean up

    return $aaData;
}

# _get_total_record_count()
#
# Get the number of records in the table, regardless of restrictions of the
# where clause or the limit clause. Used to display the total number of records
# without applied filters.

sub _get_total_record_count {
    my ($self) = @_;

    my $dbh = $self->dbh;

    my $sql = SQL::Abstract::Limit->new( limit_dialect => $dbh );
    my ( $stmt, @bind ) = $sql->select( $self->table, ['count(*) AS count'] );

    my $sth = $dbh->prepare($stmt)
        or croak "Error preparing sql: " . $dbh->errstr() . "\nSQL: $sql\n";
    my $rv = $sth->execute() or croak "Error executing sql: " . $dbh->errstr() . "\nSQL: $sql\n";

    return $sth->fetchrow_hashref()->{count};
}

# _get_filtered_total()
#
# Get the total number of filtered records (in resprect of filters by the where
# clause, without limit). This accounts for the "search" field of data tables.

sub _get_filtered_total {
    my ( $self ) = @_;

    my $dbh = $self->dbh;
    my $sql = SQL::Abstract::Limit->new( limit_dialect => $dbh );
    my ( $stmt, @bind ) = $sql->select( $self->table, ['count(*) AS count'], $self->where_clause);

    my $sth = $dbh->prepare($stmt)
        or croak "Error preparing sql: " . $dbh->errstr() . "\nSQL: $sql\n";
    my $rv = $sth->execute(@bind)
        or croak "Error executing sql: " . $dbh->errstr() . "\nSQL: $sql\nBind: @bind";
    return $sth->fetchrow_hashref()->{count};
}

1;

__END__

=pod

=head1 NAME

JQuery::DataTables::Heavy::DBI - jquery datatable server side processing by DBI

=head1 SYNOPSIS

  use JQuery::DataTables::Heavy::DBI;
  use DBIx::Handler;
  use JSON::XS;
  use Plack::Request;

  my $handler = DBIx::Hander->new( $dsn, $user, $password, \%attr );
  my $req= Plack::Request->new($env);

  my $dt = JQuery::DataTables::Heavy::DBI->new(
      dbh => $handler->dbh,
      table  => 'some table or \$sql',
      fields => [qw(fields of some table)],
      param => $req->parameters;
      decorate_aaData => sub {
          my ($aaData) = @_;
          foreach my $hash (@$aaData){
              $hash->{img} = q{<img src="/images/details_open.png">};
          }
      },
  );
  my $to_json = $dt->table_data;
  to_json($to_json);


=head1 DESCRIPTION

=head1 Method

=head2 new

=over 4

=item B<dbh> I<required>

set database handle

=item B<table> I<required>

set table name (Str). Or sql (ScalarRef) like bellow

  (
    SELECT
      a AS field_a
      IF ( b IS NULL, 0, b ) AS field_b
    FROM
      some_table
    JOIN
      other_table
    ON
      other_table.col_a = some_table.id
  ) AS table_alias

SQL is usefull when you need I<JOIN>.

=item B<fields> I<required>

set database column

=item B<param> I<required>

set HTTP Request Parameters

=decorate_aaData I<optional>

set code ref for decorate aaData

=back

=head2 table_data()
 
 Return table content as json. Evaluates query for global filtering and
 ordering information. The database is queried to collect the data.
  
=cut

=head1 PREREQUISITES

C<Moo>

=head1 Author

 Yusuke Watase <ywatase@gmail.com>
  
=cut



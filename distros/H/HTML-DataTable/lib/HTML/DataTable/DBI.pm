package HTML::DataTable::DBI;
use base HTML::DataTable;

use 5.006;
use strict;
use warnings;

use DBI;

=head1 NAME

HTML::DataTable::DBI - Print HTML tables from SQL queries

=head1 VERSION

Version 0.54

=cut

our $VERSION = 0.54;

=head1 SYNOPSIS

  use HTML::DataTable::DBI;
  my $list = HTML::DataTable::DBI->new(
    data => $cgi_data,
    columns => [
      # hashrefs describing column formats
    ],
    sql => 'SELECT * FROM table_name WHERE foreign_key = ?',
    sql_params => [ $some_value ],
    delete => { } # Delete spec as shown below
  );
  print $list;

=head1 METHODS

Look in HTML::DataTable for column-definition and table formatting attributes

=head2 ADDITIONAL ATTRIBUTES

=head3 dsn

A list containing a DBI connect string, username, and password.

=head3 dbh

You can supply a live DBI database handle instead of a DSN.

=head3 sql

A SQL query with optional "?" placeholders, which will be run and its results formatted and shown in the table.

=head3 sql_params

An optional arrayref containing the actual parameters for the SQL query.

=head3 delete

An optional hashref telling the list what record to delete. If this is included, a column will be added to the table to show trash icons. The hashref can take either of two forms. If the SQL query for this table is not parameterized - that is, the record's ID is all we need to know which record to delete - then the hashref can simply map the column index of the record ID to the CGI argument that supplies the one to delete:

  delete => {
    sql => 'DELETE FROM table WHERE record_id = ?',
    id => [ 0 => $args{delete} ],
  }

whereas if the query had a parameter the delete hashref has to give both the local and foreign keys:

  delete => {
    sql => 'DELETE FROM table WHERE record_id = ? AND foreign_id = ?',
    local => [ record_id => $args{speaker_id} ],
    foreign => [ 0 => $args{delete} ],
  }

An optional "noun" attribute in that hashref can supply a word to replace "record" in the delete confirmation alert.

=head3 trash_icon

The URL of a trash can icon for use in the "Delete" column - defaults to /art/trash.gif.

=head2 ADDITIONAL COLUMN ATTRIBUTES

=head3 sql

A paramterized SQL query that will be run to get results for this column.

=head3 foreign_key_col

The index of the column in the results from the main table's SQL query that will be used in the column's query's parameter. Defaults to 0.

=head3 separator

A character string that will be used to concatenate the results of the columns's query. Defaults to ", ".

=cut

sub set_letter {
	my ($me, $letter) = @_;

	$me->{sql} .= ' WHERE lower(' . $me->{sort}->[0] . ") LIKE '" . lc $letter . "%'";
}

sub set_search {
	my ($me, $letter) = @_;

	$me->{_dbh} ||= $me->{dbh} || DBI->connect( @{ $me->{dsn} } ) || die "No DB connection";

	$me->{sql} .= ' WHERE ' . join ' OR ', map "position( lower(\$1) in lower($_) ) > 0",
		ref $me->{search} eq 'ARRAY' ? @{$me->{search}} : split ' ', $me->{search};
}

sub set_sort_order {
	my $me = shift;

	return unless $me->{sort}->[0];
	$me->{sql} .= ' ORDER BY ' . join ', ', map "$_ $me->{sort_dir}", @{$me->{sort}};
}

sub list_HTML {
	my $me = shift;

	if ( my $d = $me->{delete} ) {
		$me->{trash_icon} ||= '/art/trash.gif';
		my $to_delete = $d->{id} || $d->{foreign};
		if ( $to_delete->[1] ) {
			$me->{_dbh} ||= $me->{dbh} || DBI->connect( @{ $me->{dsn} } ) || die "No DB connection";
			$me->{_dbh}->prepare( $d->{sql} )->execute( $d->{local}[1] || (), $to_delete->[1] );
		}
		push @{$me->{columns}}, {
			style => 'text-align: center; vertical-align: middle;',
			format => sub {
				sprintf '<a href="?%s=%d&delete=%d" onclick="return confirm( &quot;Are you sure you want to delete this %s?&quot; )"><img src="%s"></a>',
					($d->{local} ? @{$d->{local}} : (_noop => 0)),
					$_[$to_delete->[0]],
					$d->{noun} || 'record',
					$me->{trash_icon};
			}
		}
	}

	return $me->SUPER::list_HTML(@_);
}

sub next_row {
	my $me = shift;

	return $me->SUPER::next_row(@_) unless $me->{sql} or $me->{_sth};

	unless ( $me->{_sth} ) {
		$me->{_dbh} ||= $me->{dbh} || DBI->connect( @{ $me->{dsn} } ) || die "No DB connection";
		$me->{_dbh}->trace( $me->{trace} ) if $me->{trace};
		( $me->{_sth} = $me->{_dbh}->prepare( $me->{sql} ) )->execute( @{$me->{sql_params}} );
	}

	my @row = $me->{_sth}->fetchrow or do {
		$me->{_sth}->finish;
		undef $me->{_sth};
		$me->{_dbh}->disconnect unless $me->{dbh};
		return;
	};

	return \@row;
}

sub format {
	my ($me, $col, $d) = @_;

	return $me->SUPER::format( $col, $d ) unless $col->{sql};

	my (@related);
	$col->{_subquery_sth} ||= $me->{_dbh}->prepare( $col->{sql} );
	$col->{_subquery_sth}->execute( $d->[ $col->{foreign_key_col} || 0 ] );
	while ( my @d = $col->{_subquery_sth}->fetchrow ) {
		push @related, $me->SUPER::format( $col, \@d );
	}

	@related ? join( $col->{separator} || $col->{sep} || ', ', @related ) : $col->{none};
}

1;

=head1 SEE ALSO

HTML::DataTable

=head1 AUTHORS

Nic Wolff <nic@angel.net>
Jason Barden <jason@angel.net>

=cut
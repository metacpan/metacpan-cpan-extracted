# -*- perl -*-

use strict;

use HTML::EP ();


package HTML::EP::EditTable;

@HTML::EP::EditTable::ISA = qw(HTML::EP);



sub _ep_edittable_edit {
    my $self = shift;  my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $action = $cgi->param('what-to-do');
    my $table = $attr->{'table'}
        || die "Missing attribute: table (Table name)";
    my $id_col = $attr->{'id'} || 'ID';
    my $result;
    my($query, $id);

    my $dest = ($attr->{'dest'} ||= $table);
    $attr->{'prefix'} ||= "$dest\_";
    $attr->{'sqlquery'} ||= 1;

    if ($action eq 'insert') {
	$self->_ep_input($attr);
	$result = $self->{$dest};
	$query = "INSERT INTO $table (" . $result->{'names'}. ") VALUES"
	    . " (" . $result->{'values'}. ")";
    } elsif ($action eq 'update') {
	$self->_ep_input($attr);
	$result = $self->{$dest};
	$id = $cgi->param($id_col);
	$query = "UPDATE $table SET " . $result->{'update'} .
	    " WHERE $id_col = $id";
    } elsif ($id = $cgi->param($id_col)) {
	my $q = "SELECT * FROM $table WHERE $id_col = $id";
	print "Select query: $q\n" if $self->{'debug'};
	my $sth = $self->{'dbh'}->prepare($q);
	$sth->execute();
	my $names = $sth->{'NAME'};
	my $types = $sth->{'TYPE'};
	my $row = $sth->fetchrow_arrayref()
	    or die "Failed to fetch row with ID $id: No such row";
	$sth->finish();
	my %result;
	for (my $i = 0;  $i < @$row;  $i++) {
	    my $type = $types->[$i];
	    my $name = $names->[$i];
	    my $ref = { 'col' => $name,
			'val' => $row->[$i] };
	    if ($type == DBI::SQL_DATE()) {
		$ref->{'type'} = 'd';
		if (!defined($row->[$i])) {
		    $ref->{'day'} = $ref->{'month'} = $ref->{'year'} = '';
		} elsif ($row->[$i] =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)/) {
		    $ref->{'day'} = $3;
		    $ref->{'month'} = $2;
		    $ref->{'year'} = $1;
		} else {
		    die "Cannot parse date: $row->[$i]";
		}
	    } elsif ($type == DBI::SQL_NUMERIC()   ||
		     $type == DBI::SQL_DECIMAL()   ||
		     $type == DBI::SQL_INTEGER()   ||
		     $type == DBI::SQL_SMALLINT()  ||
		     $type == DBI::SQL_FLOAT()     ||
		     $type == DBI::SQL_REAL()      ||
		     $type == DBI::SQL_DOUBLE()    ||
		     $type == DBI::SQL_BIGINT()    ||
		     $type == DBI::SQL_TINYINT()) {
		$ref->{'type'} = 'n';
	    } else {
		$ref->{'type'} = 't';
	    }
	    $result->{$name} = $ref;
	}
	$self->{$dest} = $result;
	if ($action eq 'delete') {
	    $query = "DELETE FROM $table WHERE $id_col = $id";
	}
    }
    if ($query) {
	print "Executing query: $query\n" if $self->{'debug'};
	my $dbh = $self->{'dbh'};
	$dbh->do($query);
	if (!defined($id)  &&  $dbh->{'Driver'}->{'Name'} eq 'mysql') {
	    $id = $dbh->{'mysql_insertid'};
	    print "Auto-ID is $id.\n" if $self->{'debug'};
	    $cgi->param($id_col, $id);
	}
    }
    '';
}


sub _ep_edittable_select {
    my $self = shift; my $attr = shift;
    my $table = $attr->{'table'}
        || die "Missing attribute: table (Table name)";
    my $dbh = $self->{'dbh'};
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};

    my(@where, @order, @url);
    foreach my $key ($cgi->param()) {
	if ($key =~ /^select_(\w+)_(.*)/) {
	    my $col = $2;
	    my $type = $1;
	    my $val = $cgi->param($col);
	    if ($type eq 'like') {
		push(@where, "$col LIKE " . $dbh->quote("%$val%")) if $val;
	    } elsif ($type eq 'like_') {
		push(@where, "$col LIKE " . $dbh->quote("$val%")) if $val;
	    } elsif ($type eq '_like') {
		push(@where, "$col LIKE " . $dbh->quote("%$val")) if $val;
	    }
	    push(@url, "$key=" . CGI->escape($val));
	} elsif ($key =~ /^order_(\w+)_(.*)/) {
	    push(@order, "$2 $1");
	    my $val = $cgi->param($2);
	    push(@url, "$key=" . CGI->escape($val));
	}
    }

    my $start = $cgi->param('start') || 0;
    my $max = $cgi->param('max') || $attr->{'max'} || 20;
    my $count_query = "SELECT COUNT(*) FROM $table"
	. (@where ? " WHERE " . join(" AND ", @where) : "");
    print "Count query is: $count_query\n" if $debug;
    my $query = "SELECT * FROM $table"
	. (@where ? " WHERE " . join(" AND ", @where) : "")
	. (@order ? " ORDER BY " . join(", ", @order) : "")
	. " LIMIT $start, $max";
    print "Query is: $query\n" if $debug;

    $self->{'start'} = $start;
    $self->{'max'} = $max;
    $self->{'query_url'} = @url ? ("&" . join("&", @url)) : "";
    my $sth = $dbh->prepare($count_query);
    $sth->execute();
    $self->{'num_rows'} = $sth->fetchrow_array(); # Array context!
    $self->_ep_query({'statement' => $query,
		      'result' => $table});
    '';
}


sub _ep_edittable_links {
    my $self = shift;  my $attr = shift;
    my $max = $self->{'max'};
    my $start = $self->{'start'};
    my $page = $attr->{'path'} || $ENV{'PATH_INFO'};
    my $max_links = $attr->{'max_links'} || 10;
    $self->{'prev'} = $start ?
	"<a href=$page?start=" . ($start - $max) . $self->{'query_url'} .
        ">Zurück</a>" : "";
    my $links = '';
    $self->{'next'} = ($self->{'num_rows'} > $start + $max) ?
	"<a href=select.ep?start=" . ($start + $max) . $self->{'query_url'} .
        ">Weiter</a>" : "";
    my $base = $max * $max_links;
    my $first = int(($start + $base - 1) / $base);
    for (my $i = 0;  $i < $max_links;  $i++) {
	my $num = $first + $i;
	if ($self->{'num_rows'} > $num * $max) {
	    if ($num * $max == $start) {
		$links .= $num+1;
	    } else {
		$links .= "<a href=$page?start=" . ($num * $max) .
		    $self->{'query_url'} . ">" . ($num+1) . "</a>";
	    }
	}
    }
    $self->{'prev'} . $links . $self->{'next'};
}


1;


__END__

=pod

=head1 NAME

HTML::EP::EditTable - An HTML::EP extension for editing a table via WWW


=head1 SYNOPSIS

  <!-- Connect to the database --!>
  <ep-database dsn="DBI:mysql:test">
  <!-- Make HTML::EP edit your table: --!>
  <ep-edittable-edit table=MyTable>


=head1 DESCRIPTION

It is quite usual that you make your database tables editable via a
WWW frontend. Writing such a frontend should be fast and simple for
both the database administrator and the web designer.

HTML::EP::EditTable comes with a set of ready-to-use HTML files,
suitable for an example table called I<Termine> and an example
subclass. Usually the Web designer just picks off the HTML files
and modifies them until they fit his design wishes. Then the
database administrator takes the files and usually just modifies
the column names. If he wishes to add some private data checking
or similar things, he can do so by subclassing the HTML::EP::Edittable
class.


=head1 AVAILABLE METHODS

  <ep-edittable-edit table=MyTable id=ID what-to-do=insert>

This method combines the following possibilities:

=over

=item *

Selecting a record out of the table I<MyTable>.

=item *

Inserting a new record into the table I<MyTable>.

=item *

Updating a record in the table I<MyTable>.

=item *

Deleting a record from the table I<MyTable>.

=back

What the method exactly does, depends on the value of the
CGI variable I<what-to-do>: This can be either empty,
I<insert>, I<update> or I<delete>.

If I<what-to-do> is I<insert> or I<update>, then the method
will first call the HTML::EP method I<ep-input>. If the attributes
I<dest>, I<prefix> and I<sqlquery>, which this method expects, are
not set, then they will by default be set to B<MyTable>, B<MyTable_>
and 1, respectively.

If I<what-to-do> is I<insert>, then the query

  INSERT INTO MyTable ($@MyTable->names$) VALUES ($@MyTable->values$)

will be executed. Likewise, the query

  UPDATE MyTable SET $@MyTable->update WHERE ID = $cgi->ID$

will be executed for the value I<update>.

If I<what-to-do> is I<insert> or I<delete>, then the method will
attempt to retrieve a row from the table I<MyTable>. It does so,
by looking at the column I<ID> (default, you can overwrite this
by setting the attribute I<id> when calling the method) and the
CGI variable of the same name, which contains the column ID,
usually the primary key of the table.

The fetched row will be converted into the same format returned
by I<ep-input>: Thus you can always work with the same data
format in all HTML pages.


=head1 SEE ALSO

L<HTML::EP(3)>, L<DBIx::RecordSet(3)>

=cut

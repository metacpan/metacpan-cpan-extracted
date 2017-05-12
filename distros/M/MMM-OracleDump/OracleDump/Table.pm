package MMM::OracleDump::Table;
#$Id: Table.pm,v 1.3 1999/11/24 18:33:13 maxim Exp $
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(
);
$VERSION = '0.01';


sub new {
	my ($pkg, $dbh, $table) = @_;
	unless  (ref($dbh) && $table) {
		die "OracleDump::Table::new() takes 2 arguments: a dbi db handler and a table name ($dbh, $table)\n";
	}
	my $this = {
		Name 	=> $table,
		Dbh  	=> $dbh,	
		ColInfo => _get_column_info($dbh,$table),
	};
	bless $this;
	return $this;
}

sub get_create_sql {
	my $this = shift;
	my $create_sql = _ddl_create_table ($this->{Name}, $this->{ColInfo});
	return $create_sql. ";\n";
}

sub dump_sql {
	my ($this, $fh)  = @_;
	if (!$fh ) {
		$fh = \*STDOUT;
	}
	my ($dbh, $table_name, $col_info) = ( $this->{Dbh}, $this->{Name}, $this->{ColInfo} );
	my $dump_sql   = _dml_dump($table_name, $col_info);
	my $insert_sql_fmt = _dml_insert_sql_fmt($table_name, $col_info);
	my $qh = $dbh->prepare($dump_sql);
	$qh->execute();
	my $row;
	 while ( $row = $qh->fetch() ) {
		my @qvalues; 
		for (0.. @$row-1) {
			if ( defined $row->[$_] ) {
				if ( $col_info->[$_]->{Type} !~ /NUMBER/ ) {
					$qvalues[$_] = $dbh->quote($row->[$_]);
				} else {
					$qvalues[$_] = $row->[$_];
				}
			} else {
				$qvalues[$_] = 'NULL';
			}
		}
		my $insert_sql = sprintf($insert_sql_fmt, @qvalues);	
		print $fh $insert_sql,";\n";
	 }
	 $qh->finish;
	
}

sub _dml_insert_sql_fmt {
	my ($table_name, $col_info) = @_;
	my $sql = "INSERT INTO $table_name VALUES(" .  join ( ",", map { $_->{InsertSqlFmt} } @$col_info  ) .  " )";
	return $sql;
}
	
sub _dml_dump {
	my ($table_name, $col_info) = @_;
	my $sql = "SELECT " .  join ( ",", map { $_->{DumpSql} } @$col_info  ) .  " FROM $table_name ";
	return $sql;
}	

sub _get_column_info{
	my ($dbh, $table) = @_;
	my $sql = qq/ SELECT * FROM USER_TAB_COLUMNS 
		WHERE TABLE_NAME='$table' ORDER BY COLUMN_ID /;
	my $qh = $dbh->prepare($sql);
	die "$DBI::errstr\n" unless $qh;
	$qh->execute();
	my @result = ();
	my $row;
	while ($row = $qh->fetchrow_hashref ) {
		my $data = _get_single_col_info($row);
		push @result, $data;
	}
	$qh->finish;
	return \@result;
}

sub _get_single_col_info {
	my $h = shift;
	my $name = $h->{COLUMN_NAME};
	my $type = $h->{DATA_TYPE};
	my $len  = $h->{DATA_LENGTH};
	my $fulltype = $type =~ /DATE/ ? $type : "$type($len)";
	my $notnull = $h->{NULLABLE} =~/Y/i ? "" : "NOT NULL" ;
	my $str = sprintf "%-15s %10s %10s", $name,$fulltype,$notnull ;
	my $sel_field = $type eq 'DATE' ?     "TO_CHAR($name,'yyyy-mm-dd hh24:mi:ss')" : $name;
	my $ins_field_fmt = $type eq 'DATE' ? 'TO_DATE(%s,\'yyyy-mm-dd hh24:mi:ss\')'  : '%s';
	return { 
		Name => $name, 
		Type => $type, 
		CreateSql => $str,
		DumpSql   => $sel_field, 
		InsertSqlFmt  => $ins_field_fmt 
	};
}
		


sub _ddl_create_table{ "CREATE TABLE $_[0] ( \n\t" .  join("\n\t", map { $_->{CreateSql} } @{$_[1]} ) . "\n)" };











1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OracleDump - Perl extension for blah blah blah

=head1 SYNOPSIS

  use OracleDump;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for OracleDump was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut

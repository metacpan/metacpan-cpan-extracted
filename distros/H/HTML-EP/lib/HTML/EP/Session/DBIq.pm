# -*- perl -*-

use strict;
use HTML::EP::Session ();

package HTML::EP::Session::DBIq;

@HTML::EP::Session::DBIq::ISA = qw(HTML::EP::Session::DBI);
$HTML::EP::Session::DBIq::VERSION = '0.01';


sub InsertQuery {
    my $self = shift; my $table = shift;
    "INSERT INTO $table (\"ID\", \"SESSION\", \"LOCKED\") VALUES (?, ?, 1)";
}
sub UpdateQuery {
    my $self = shift; my $table = shift;
    "UPDATE $table SET \"LOCKED\" = 1 WHERE \"ID\" = ? AND \"LOCKED\" = 0";
}
sub Update2Query {
    my $self = shift; my $table = shift; my $locked = shift;
    "UPDATE $table SET \"SESSION\" = ?"
	. ($locked ? "" : ", \"LOCKED\" = 0") . " WHERE \"ID\" = ?";
}
sub Update3Query {
    my $self = shift; my $table = shift;
    "UPDATE $table SET \"LOCKED\" = 0 WHERE \"ID\" = ?"
}
sub SelectQuery {
    my $self = shift; my $table = shift;
    "SELECT \"SESSION\" FROM $table WHERE \"ID\" = ?";
}


1;

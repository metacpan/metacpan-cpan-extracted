# -*- perl -*-

use strict;
use HTML::EP::Session ();


package HTML::EP::Session::DBI;

sub InsertQuery {
    my $self = shift; my $table = shift;
    "INSERT INTO $table (ID, SESSION, LOCKED) VALUES (?, ?, 1)";
}
sub UpdateQuery {
    my $self = shift; my $table = shift;
    "UPDATE $table SET LOCKED = 1 WHERE ID = ? AND LOCKED = 0";
}
sub Update2Query {
    my $self = shift; my $table = shift; my $locked = shift;
    "UPDATE $table SET SESSION = ?"
	. ($locked ? "" : ", LOCKED = 0") . " WHERE ID = ?";
}
sub Update3Query {
    my $self = shift; my $table = shift;
    "UPDATE $table SET LOCKED = 0 WHERE ID = ?"
}
sub SelectQuery {
    my $self = shift; my $table = shift;
    "SELECT SESSION FROM $table WHERE ID = ?";
}

sub new {
    my($proto, $ep, $id, $attr) = @_;
    my $class = (ref($proto) || $proto);
    my $table = $attr->{'table'} || 'sessions';
    my $dbh = $ep->{'dbh'} || die "Missing DBI dbh";
    my $session = {};
    my $debug = $ep->{'debug'};
    bless($session, $class);
    my $code = $ep->{'_ep_session_code'};
    my $freezed_session = Storable::nfreeze($session);
    $freezed_session = unpack("H*", $freezed_session) if $code eq 'h';
    $ep->printf("Inserting id %s, session %s\n",
		$id, unpack("H*", $code . $freezed_session)) if $debug;
    my $sth = $dbh->prepare($session->InsertQuery($table));
    $sth->bind_param(1, $id, DBI::SQL_CHAR());
    $sth->bind_param(2, $code . $freezed_session, DBI::SQL_LONGVARBINARY());
    $sth->execute();
    $sth->finish();
    $session->{'_ep_data'} = { 'dbh' => $dbh,
			       'table' => $table,
			       'locked' => 1,
			       'id' => $id,
			       'code' => $code };
    $session;
}

sub Open {
    my($proto, $ep, $id, $attr) = @_;
    my $class = (ref($proto) || $proto);
    my $table = $attr->{'table'} || 'sessions';
    my $dbh = $ep->{'dbh'} || die "Missing DBI dbh";
    $dbh->do($proto->UpdateQuery($table), undef, $id);
    my $sth = $dbh->prepare($proto->SelectQuery($table));
    $sth->execute($id);
    my $ref = $sth->fetchrow_arrayref();
    my $freezed_session = $ref->[0];
    if ($ep->{'debug'}) {
	$ep->printf("HTML::EP::Session::DBI: frozen session %s\n",
		    unpack("H*", $freezed_session));
    }
    my $code = substr($freezed_session, 0, 1);
    $freezed_session = substr($freezed_session, 1);
    if ($code eq 'h') {
	$freezed_session = pack("H*", $freezed_session);
    }
    if ($ep->{'debug'}) {
	$ep->printf("HTML::EP::Session::DBI: thawing session %s\n",
		    unpack("H*", $freezed_session));
    }
    my $session = Storable::thaw($freezed_session);
    bless($session, $class);
    $session->{'_ep_data'} = { 'dbh' => $dbh,
			       'table' => $table,
			       'locked' => 1,
			       'id' => $id,
			       'code' => $code
			       };
    $session;
}

sub Store {
    my($self, $ep, $id, $locked) = @_;
    my $data = delete $self->{'_ep_data'}  or die "No _ep_data";
    my $table = $data->{'table'} || die "No table";
    my $dbh = $data->{'dbh'};
    my $freezed_session = Storable::nfreeze($self);
    my $code = $data->{'code'};
    if ($code eq 'h') {
	$freezed_session = unpack("H*", $freezed_session);
    }
    my $sth = $dbh->prepare($self->Update2Query($table, $locked));
    $sth->bind_param(1, $code . $freezed_session, DBI::SQL_LONGVARBINARY());
    $sth->bind_param(2, $id, DBI::SQL_CHAR());
    $sth->execute();
    $sth->finish();
    if ($locked) {
	$self->{'_ep_data'} = $data;
    } else {
	$data->{'locked'} = 0;
    }
}

sub Delete {
    my $self = shift;  my $ep = shift;  my $id = shift;
    my $data = (delete $self->{'_ep_data'}) || die "No _ep_data";
    my $table = $data->{'table'} || die "No table";
    my $dbh = $data->{'dbh'};
    $dbh->do("DELETE FROM $table WHERE ID = ?", undef, $id);
    $data->{'locked'} = 0;
}

sub DESTROY {
    my $self = shift;
    my $data = delete $self->{'_ep_data'} || die "No _ep_data";
    if ($data->{'locked'}) {
	my $table = $data->{'table'} || die "No table";
	my $id = $data->{'id'};
	my $dbh = $data->{'dbh'};
	$dbh->do($self->Update3Query($table), undef, $id);
    }
}


1;

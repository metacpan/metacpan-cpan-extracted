package Egg::Model::Session::Base::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 303 2008-03-05 07:47:05Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Time::Piece::MySQL;

our $VERSION= '0.03';

sub _setup {
	my($class, $e)= @_;
	$e->model_manager->isa('Egg::Model::DBI')
	   || die q{ I want setup 'Egg::Model::DBI'.};

	$class->mk_classdata($_) for qw/ _label _insert _update _delete _clear /;
	my $c= $class->config->{dbi} ||= {};
	my $dbname = $c->{dbname}     || 'sessions';
	my $idcol  = $c->{id_field}   || 'id';
	my $datacol= $c->{data_field} || 'a_session';
	my $timecol= $c->{time_field} || 'lastmod';

	$class->_insert
	  (qq{INSERT INTO $dbname ($idcol, $datacol, $timecol) VALUES (?, ?, ?)});
	$class->_update
	  (qq{UPDATE $dbname SET $datacol = ?, $timecol = ? WHERE $idcol = ? });
	$class->_delete
	  (qq{DELETE FROM $dbname WHERE $idcol = ?});
	$class->_clear
	  (qq{DELETE FROM $dbname WHERE $timecol < ? });

	my $restore_sql= qq{SELECT $datacol FROM $dbname WHERE $idcol = ? };

	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::_restore"}= ($c->{prepare_cache} or $c->{prepare_cached})
	     ? sub { $_[0]->_dbh->prepare_cached($restore_sql) }
	     : sub { $_[0]->_dbh->prepare($restore_sql) };
	if ($e->isa('Egg::Plugin::EasyDBI')) {
		*{"${class}::_commit"}= sub {
			if ($_[1]) {
				my $db= $_[0]->e->dbh($_[0]->_label) || return 0;
				$db->commit_ok(1);
			}
		  };
		*{"${class}::_dbh"}= sub {
			$_[0]->attr->{dbh} || do {
				my $db= $_[0]->e->dbh($_[0]->_label) || return 0;
				$db->dbh;
			  };
		  };
	} else {
		*{"${class}::_commit"}= sub {
			$_[1] ? $_[0]->_dbh->commit
			      : $_[0]->_dbh->rollback;
		  };
		*{"${class}::_dbh"}= sub { $_[0]->e->model($_[0]->_label)->dbh; };
	}
	$class->_label($c->{label} || 'dbi::main');
	$class->next::method($e);
}
sub restore {
	my $self= shift;
	my $id  = shift || $self->session_id || croak q{I want session id.};
	my $sesson;
	my $sth= $self->_restore;
	$sth->execute($id);
	$sth->bind_columns(\$sesson);
	$sth->fetch; $sth->finish;
	$sesson ? \$sesson: 0;
}
sub insert {
	my $self= shift;
	my $data= shift || croak q{I want session data.};
	my $id  = shift || $self->session_id || croak q{I want session id.};
	$self->_do($self->_insert, $id, $$data, localtime(time)->mysql_datetime);
}
sub update {
	my $self= shift;
	my $data= shift || croak q{I want session data.};
	my $id  = shift || $self->session_id || croak q{I want session id.};
	$self->_do($self->_update, $$data, localtime(time)->mysql_datetime, $id);
}
sub delete {
	my $self= shift;
	my $id  = shift || croak q{I want session id.};
	$self->_do($self->_delete, $id);
}
sub clear_sessions {
	my $self= shift;
	my $datetime= shift || die q{ I want time. };
	$self->_do($self->_clear, undef, localtime($datetime)->mysql_datetime);
}
sub _do {
	my $self= shift;
	my $sql = shift;
	my $result;
	eval {
		$self->e->debug_out("# + session Base::DBI : $sql");
		$result= $self->_dbh->do($sql, undef, @_);
		$self->_commit(1);
	  };
	return $result unless $@;
	$self->_dbh->rollback;
	die $@;
}
sub close {
	my($self)= @_;
	my $update_ok= $self->is_update;
	$self->next::method;
	$self->_commit($update_ok);
	$self;
}

1;

__END__

=head1 NAME

Egg::Model::Session::Base::DBI - Session management by DBI.

=head1 SYNOPSIS

  package MyApp::Model::Sesion;
  
  __PACKAGE__->config(
   dbi => {
     label         => 'dbi_label_name',
     dbname        => 'sessions',
     id_field      => 'id',
     data_field    => 'a_session',
     time_field    => 'lastmod',
     prepare_cache => 1,
     },
   );
  
  __PACKAGE__->startup(
   Base::DBI
   Store::Base64
   ID::SHA1
   Bind::Cookie
   );

=head1 DESCRIPTION

The session data is preserved by using DBI.

'L<Egg::Model::DBI>' should be able to be used for use.

And, L<Egg::Helper::Model::Session>. 'Base::DBI' is added to startup of the 
component module that generates.

'Base::FileCache' in this systemIt is not possible to cooperate and delete it,
 please.

Moreover, it is necessary to load Store system module to treat the session data
appropriately.

  __PACKAGE__->startup(
   Base::DBI
   Store::Base64
   ID::SHA1
   Bind::Cookie
   );

If L<Egg::Plugin::EasyDBI> is effective, it is late commit.

=head1 CONFIGURATION

It sets in config of the session component module and it sets it to 'dbi' key
with HASH.

=head3 label

Label name to use L<Egg::Model::DBI>.

Default is 'dbi::main'.

=head3 dbname

Table name that preserves session data.

Default is 'sessions'.

Please make this table beforehand by the following compositions.

  CREATE TABLE [dbname] (
    id          char(32)  primary key,
    lastmod     timestamp,
    a_session   text
    );

=head3 id_field

Name of session ID column.

Default is 'id'.

=head3 data_field

Name of session data column.

Default is 'a_session'.

=head3 time_field

Name of updated day and hour column.

Default is 'lastmod'.

=head3 prepare_cache

When this item is made effective, 'prepare_cached' method of DBI comes to be 
used by the restore method.

Default is undefined.

=head1 METHODS

Because most of these methods is the one that L<Egg::Model::Session> internally
uses it, it is not necessary to usually consider it on the application side.

=head2 _label

The label name of the model used is returned.

=head2 _insert

SQL statement used by the insert method is returned.

=head2 _update

SQL statement used by the update method is returned.

=head2 _delete

SQL statement used by the delete method is returned.

=head2 _clear

SQL statement used by the clear method is returned.

=head2 restore ([SESSION_ID])

The session data obtained by received SESSION_ID is returned.

When SESSION_ID is not obtained, it acquires it in 'session_id' method.

=head2 insert ([SESSION_DATA], [SESSION_ID])

New session data is preserved.

SESSION_DATA is indispensable.

When SESSION_ID is not obtained, it acquires it in 'Session_id' method.

=head2 update ([SESSION_DATA], [SESSION_ID])

Existing session data is updated.

SESSION_DATA is indispensable.

When SESSION_ID is not obtained, it acquires it in 'session_id' method.

=head2 delete ([SESSION_ID])

The session data is deleted.

SESSION_ID is indispensable.

  $session->delete('abcdefghijkemn12345');

=head2 clear_sessions ([TIME_VALUE])

All the session data before TIME_VALUE is deleted.

  # The update on deletes all the session data that not is.
  $session->clear_sessions( time - (24 * 60 * 60) );

=head2 close

L<Egg::Model::Session::Manager::TieHash> Commit is done back.

However, if 'is_update' method is invalid, rollback is issued.
In a word, if data was not substituted for the session, the data is annulled.

When L<Egg::Plugin::EasyDBI> is loaded, nothing is done.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,
L<Egg::Model::Session::Manager::Base>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Model>,
L<Egg::Model::DBI>,
L<Time::Piece::MySQL>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


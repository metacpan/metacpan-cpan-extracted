package Egg::Model::Session::Base::DBIC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 256 2008-02-14 21:07:38Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Time::Piece::MySQL;

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{dbic} ||= {};
	my $idcol  = $c->{id_field}   || 'id';
	my $datacol= $c->{data_field} || 'a_session';
	my $timecol= $c->{time_field} || 'lastmod';
	my $moniker= $c->{label_source} || die q{I want setup 'label_source'.};
	$e->is_model($c->{label_source})
	          || die qq{'$c->{label_source}' model is not found.};
	my $s_label= $c->{label_schema} || die q{I want setup 'label_schema'.};
	my $project= $e->project_name;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	if ($e->isa('Egg::Plugin::DBIC')) {
		$e->is_model($s_label) || die qq{'$s_label' model is not found.};
		my $s_name= $s_label=~m{^dbic\:+(.+)} ? $1: $s_label;
		*{"${class}::_begin"}= sub {
			&{"${project}::begin_$s_name"}($_[0]->e);
		  };
		*{"${class}::_commit"}= sub {
			&{"${project}::commit_ok"}($_[0]->e, $s_name, 1) if $_[1];
		  };
	} else {
		my $schema= $e->model($s_label)
		    || die qq{'$s_label' model is not found.};
		if ($schema->storage->dbh->{AutoCommit}) {
			*{"${class}::_begin"} = sub { $_[0]->e->model($s_label) };
			*{"${class}::_commit"}= sub { 1 };
		} else {
			*{"${class}::_begin"}= sub {
				my $context= $_[0]->e->model($s_label);
				$context->txn_begin;
				$context;
			  };
			*{"${class}::_commit"}= sub {
				$_[1] ? $_[0]->_schema->txn_commit
				      : $_[0]->_schema->txn_rollback;
			  };
		}
	}
	*{"${class}::moniker"}= sub {
		$_[0]->attr->{dbic_moniker} ||= $_[0]->e->model($moniker);
	  };
	*{"${class}::result"}= sub {
		my $self= shift;
		return ($self->attr->{result} || 0) unless @_;
		$self->attr->{result}= shift;
	  };
	*{"${class}::id_col"}   = sub { $idcol   };
	*{"${class}::data_col"} = sub { $datacol };
	*{"${class}::time_col"} = sub { $timecol };
	$class->next::method($e);
}
sub restore {
	my $self= shift;
	my $id  = shift || $self->session_id || croak q{I want session id.};
	my $result = $self->moniker->find($id) || return 0;
	my $datacol= $self->data_col;
	\$self->result($result)->$datacol;
}
sub insert {
	my $self= shift;
	my $data= shift || croak q{I want session data.};
	my $id  = shift || $self->session_id || croak q{I want session id.};
#	$self->result(undef) if $self->result;
	$self->moniker->create({
	  $self->id_col   => $id,
	  $self->data_col => $$data,
	  $self->time_col => localtime(time)->mysql_datetime,
	  });
}
sub update {
	my $self= shift;
	my $data= shift || croak q{I want session data.};
	my $id  = shift || $self->session_id || croak q{I want session id.};
	return $self->insert($data, $id) unless $self->result;
	my($datacol, $timecol)= ($self->data_col, $self->time_col);
	$self->result->$timecol( localtime(time)->mysql_datetime );
	$self->result->$datacol( $$data );
	$self->result->update;
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

Egg::Model::Session::Base::DBIC - Session management by DBIC.

=head1 SYNOPSIS

  package MyApp::Model::Sesion;
  
  __PACKAGE__->config(
   dbic => {
     label_schema  => 'dbic_schma_label',
     label_source  => 'dbic_moniker_label',
     id_field      => 'id',
     data_field    => 'a_session',
     time_field    => 'lastmod',
     },
   );
  
  __PACKAGE__->startup(
   Base::DBIC
   Store::Base64
   ID::SHA1
   Bind::Cookie
   );

=head1 DESCRIPTION

The session data is preserved by using DBIC.

'L<Egg::Model::DBIC>' should be able to be used for use.

And, 'Base::DBIC' is added to startup of the component module generated with 
L<Egg::Helper::Model::Session>. Base::FileCache of default's It is not possible
to cooperate and delete it, please.

Moreover, it is necessary to load Store system module to treat the session data 
appropriately.

  __PACKAGE__->startup(
   Base::DBIC
   Store::Base64
   ID::SHA1
   Bind::Cookie
   );

If AutoCommit is invalid and 'L<Egg::Plugin::DBIC>' is effective in the setting
 of DBI, it is late commit.

=head1 CONFIGURATION

It sets in config of the session component module and it sets it to 'dbic' item
 with HASH.

  __PACKAGE__->config(
   dbic => {
    .......
    },
   );

=head3 label_schema

It is Ra bell name because it obtains Schame of L<Egg::Model::DBIC>.

The exception is generated in case of undefined.

=head3 label_source

Label name to obtain source object of session table from L<Egg::Model::DBIC>.

The exception is generated in case of undefined.

=head3 id_field

Name of session ID column.

'id' is used in case of undefined.

=head3 data_field

Name of session data column.

'a_session' is used in case of undefined.

=head3 time_field

Name of updated day and hour column.

'lastmod' is used in case of undefined.

=head1 METHODS

Because most of these methods is the one that L<Egg::Model::Session> internally
 uses it, it is not necessary to usually consider it on the application side.

=head2 moniker

The source object of the session table is returned from L<Egg::Model::DBIC>.

=head2 _begin

If AutoCommit is effective, the transaction is begun. If it is invalid, nothing
 is done.

=head2 _commit

If AutoCommit is effective, the transaction is shut. If it is invalid, 
committing does the rollback if 'is_update' is effective. 

If AutoCommit is invalid, nothing is done.

=head2 result

When the result of 'restore' is preserved, it is returned.

=head2 id_col

The content of 'id_filed' of the configuration is returned.

=head2 data_col

The content of 'data_filed' of the configuration is returned.

=head2 time_col

The content of 'time_field' of the configuration is returned.

=head2 restore ([SESSION_ID])

The session data obtained by received SESSION_ID is returned.

When SESSION_ID is not obtained, it acquires it in 'session_id' method.

=head2 insert ([SESSION_DATA], [SESSION_ID])

New session data is preserved.

SESSION_DATA is indispensable.

When SESSION_ID is not obtained, it acquires it in 'session_id' method.

=head2 update ([SESSION_DATA], [SESSION_ID])

Existing session data is updated.

SESSION_DATA is indispensable.

When SESSION_ID is not obtained, it acquires it in 'session_id' method.

=head2 close

After L<Egg::Model::Session::Manager::TieHash>, commit is done.

However, if 'is_update' method is invalid, rollback is issued. In a word, if 
data was not substituted for the session, the data is annulled.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session>,
L<Egg::Model::Session::Manager::Base>,
L<Egg::Model::Session::Manager::TieHash>,
L<Egg::Model>,
L<Egg::Model::DBIC>,
L<Time::Piece::MySQL>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


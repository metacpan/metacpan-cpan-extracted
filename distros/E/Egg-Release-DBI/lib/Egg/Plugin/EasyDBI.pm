package Egg::Plugin::EasyDBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: EasyDBI.pm 312 2008-04-16 19:22:56Z lushe $
#
use strict;
use warnings;
use Time::Piece::MySQL;

our $VERSION= '3.02';

sub _setup {
	my($e)= @_;
	$e->is_model('dbi') || die q{ I want load 'Egg::Model::DBI'. };
	Egg::Plugin::EasyDBI::handler->__setup($e);
	$e->next::method;
}
sub dbh {
	my $e= shift;
	my $label= shift || 'main';
	$e->{easydbi} ||= $e->ixhash;
	$e->{easydbi}{$label} ||= Egg::Plugin::EasyDBI::handler->new($e, $label);
}
sub db {
	shift->dbh(@_)->db;
}
sub mysql_datetime {
	my $self= shift;
	my $Time= shift || time;
	localtime($Time)->mysql_datetime
}
sub close_dbh {
	my $e= shift;
	my $rollback= $_[0] ? sub {}: sub { $_[0]->rollback_ok(1) };
	for (reverse( keys %{$e->{easydbi}} )) {
		$rollback->($e->{easydbi}{$_});
		$e->{easydbi}{$_}->close;
	}
	%{$e->{easydbi}}= ();
	$e;
}
sub _finish {
	my($e)= shift->next::method;
	$e->close_dbh(1);
	$e;
}
sub _finalize_error {
	my($e)= shift->next::method;
	$e->close_dbh(0);
	$e;
}

package Egg::Plugin::EasyDBI::handler;
use strict;
require Egg::Mod::EasyDBI;

our @ISA;

sub __setup {
	my($class, $e)= @_;
	my $opt= $e->config->{plugin_easydbi} ||= {};
	if ($e->debug) {
		$opt->{debug}= 1;
	} else {
		$opt->{debug}= $opt->{trace}= 0;
	}
	Egg::Mod::EasyDBI->import($opt);
	unshift @ISA, 'Egg::Mod::EasyDBI';
	$class;
}
sub new {
	my($class, $e, $label)= @_;
	$label= "dbi::$label" unless $e->is_model($label);
	$class->SUPER::new
	($e->model($label)->dbh, $e->config->{plugin_easydbi});
}

1;

__END__

=head1 NAME

Egg::Plugin::EasyDBI - Plugin for Egg to use DBI easy.

=head1 SYNOPSIS

  use Egg qw/ EasyDBI /;
  
  # Acquisition of data base steering wheel.
  my $dbh= $e->dbh;
  
  # SELECT * FROM hoge WHERE id = ?
  my $hoge= $dbh->hashref(q{SELECT * FROM hoge WHERE id = ?}, $id)
         || die q{ Data is not found. };
  or
  my $hoge= $e->db->hoge->hashref('id = ?', $id)
         || die q{ Data is not found. };
  
  # SELECT * FROM hoge WHERE age > ?
  my $list= $dbh->arrayref(q{SELECT * FROM hoge WHERE age > ?}, 20)
         || die q{ Data is not found. };
  or
  my $list= $e->db->hoge->arrayref('age > ?', 20)
         || die q{ Data is not found. };
  
  # SELECT id FROM hoge WHERE user = ?
  my $id= $dbh->scalar(q{SELECT id FROM hoge WHERE user = ?}, 'boo')
         || die q{ Data is not found. };
  or
  my $id= $e->db->hoge->scalar(\'id', 'user = ?', 'boo');
  
  # The processed list is acquired.
  my $list= $e->db->hoge->arrayref('age > ?', [20], sub {
       my($array, %hash)= @_;
       push @$array, "$hash{id} : $hash{user} : $hash{age}";
    }) || die q{ Data is not found. };
    
  # The data that can be immediately used is acquired.
  my $text;
  $e->db->hoge->arrayref('age > ?', [20], sub {
       my($array, %hash)= @_;
       $text.= <<END_DATA;
  ID   : $hash{id}
  NAME : $hash{user}
  AGE  : $hash{age}
  END_DATA
    }) || "";
    
  # INSERT INTO hoge (id, user, age) VALUES (?, ?, ?);
  $dbh->do(
    q{INSERT INTO hoge (id, user, age) VALUES (?, ?, ?)},
    qw/ 1 zoo 21 /
    ) || die q{ Fails in regist of data. };
  or
  $e->db->hoge->insert( id=> 1, user=> 'zoo', age=> 20 )
      || die q{ Fails in regist of data. };
  
  # UPDATE hoge SET other = ?, age = age + 1 WHERE id = ?
  $dbh->do(
    q{UPDATE hoge SET other = ?, age = age + 1 WHERE id = ?},
    qw/ gao 1 /
    ) || die q{ Fails in regist of data. };
  or
  $e->db->hoge->update( id=> 1, other=> 'gao', age=> \1 )
      || die q{ Fails in regist of data. };
  
  or, I think that this is the best.
  $e->db->hoge->update(\'id = ?', { id=> [1], other=> 'gao', age=> \1 })
      || die q{ Fails in regist of data. };


A method different from 'do' of dbh of DBI is called about above-mentioned 'do'.
It is $dbh-E<gt>dbh. Therefore, usual 'do' is $dbh-E<gt>dbh-E<gt>do.

=head1 DESCRIPTION

It is a plugin to use module L<Egg::Mod::EasyDBI> to use DBI easily.

It is necessary to setup L<Egg::Model::DBI> to use it.

=head1 CONFIGURATION

Please go in the configuration of this plug-in with 'plugin_easydbi'.

All set values extend to L<Egg::Mod::EasyDBI> as it is.

=head1 METHODS

=head2 dbh ([LABEL_NAME])

The object of Egg::Plugin::EasyDBI::handler is returned.

There is no argument needing and when two or more connection destination is set
with L<Egg::Model::DBI>, LABEL_NAME is passed usually.

  my $dbh= $e->dbh;

=head2 db

The db object of Egg::Plugin::EasyDBI::handler is returned.

  my $table= $e->db->hoge_table;

When tables unite, it becomes the following.

  my $table= $e->db(qw/ hoge = hoge1:a.id=b.id /);

see L<Egg::Mod::EasyDBI>.

=head2 mysql_datetime ([TIME])

The time value is received and the character string of the datetime type is 
returned.

When TIME is omitted, a present time value is used.

  # It was timely the day before of the 30th.
  my $datetime= $e->mysql_datetime( time- (30* 24* 60* 60) );

=head2 close_dbh ([BOOL])

All the opened transactions are shut and the object is annulled.

AutoCommit However, the object is only annulled if it is invalid.

Please pass BOOL one usually.
To do all rollbacks when 0 and undefined are passed, it is treated.

  # If commit_ok is effective, commit is done.
  $e->close_dbh(1);
  
  # Even if commit_ok is effective, it is rollback treatment of all.
  $e->close_dbh(0);

=head1 HANDLER METHODS

Egg::Plugin::EasyDBI::handler has succeeded to L<Egg::Mod::EasyDBI>.

=head2 new

Constructor.

dbh and the configuration acquired from L<Egg::Model::DBI> are passed to the
constructor of the base class.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Mod::EasyDBI>,
L<Egg::Model::DBI>,
L<DBI>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


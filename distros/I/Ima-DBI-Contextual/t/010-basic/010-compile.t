#!/usr/bin/perl -w

package My::Woot;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';

sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}

__PACKAGE__->set_db('Main',
  'DBI:SQLite:dbname=t/testdb', '', ''
);


package My::Woot::Child;

use strict;
use warnings 'all';
BEGIN { push @My::Woot::Child::ISA, 'My::Woot' }

sub foo {
  my ($s) = @_;
  
  $s->db_Main->do("insert into states (state_name, state_abbr) values ('Colorado','CO')");
  my $sth = $s->db_Main->prepare("select * from states where state_abbr = 'CO'");
  $sth->execute();
  my ($state) = $sth->fetchrow_hashref;
  $sth->finish();
  return $state;
}


package main;

use strict;
use warnings 'all';
use Test::More 'no_plan';

ok(
  my $w = My::Woot->new(),
  "Got a woot"
);

ok(
  my $dbh = $w->db_Main,
  "Got a dbh"
);

ok(
  my $co = My::Woot::Child->foo(),
  "Got a state"
);

is(
  $co->{state_name} => "Colorado",
  "co.state_name = Colorado"
);



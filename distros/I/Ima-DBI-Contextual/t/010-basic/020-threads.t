#!/usr/bin/perl -w

package My::DBI;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';

sub connection
{
  my ($s, $dsn, $username, $password) = @_;
  
  $s->set_db('Main', $dsn, $username, $password, {
    AutoCommit  => 1,
    RaiseError  => 1,
  });
}# end connection()



package main;

use strict;
use warnings 'all';
use Carp 'confess';

BEGIN {
  use Test::More 'no_plan';
  ok(1, 'Going to see if threads is installed');
  eval "use threads";
}

unless( $INC{'threads.pm'} )
{
  warn "This test requires threads.pm\n";
  exit(0);
}# end unless()

$SIG{__DIE__} = \&confess;


use_ok 'Ima::DBI::Contextual';

unless( $ENV{IDBIC_DSN} )
{
  warn "\$ENV{IDBIC_DSN} must be set to run this test.  Set \$ENV{IDBIC_USER} and \$ENV{IDBIC_PASS} for username and password if necessary.\n";
  exit(0);
}# end unless()


My::DBI->connection( $ENV{IDBIC_DSN}, $ENV{IDBIC_USER}, $ENV{IDBIC_PASS} );

test_forking_then_select() for 1..10;

test_forking_then_transaction() for 1..10;

sub test_forking_then_select
{
  My::DBI->db_Main->do('select 1');

  my $random_number = rand();
  my $worker = threads->create({context => 'scalar'}, sub {
    my $sth = My::DBI->db_Main->prepare("select ?");
    $sth->execute( $random_number );
    my ($return_value) = $sth->fetchrow();
    $sth->finish();
    return $return_value;
  });

  My::DBI->db_Main->do('select 1');

  is $worker->join() => $random_number, "worker returned what we expected";

  My::DBI->db_Main->do('select 1');
}# end test_forking_then_select()


sub test_forking_then_transaction
{
  My::DBI->db_Main->do('select 1');

  my $random_number = rand();
  
  my $succeeds = threads->create({context => 'list'}, sub {
    my $dbh = My::DBI->db_Main;
    local $dbh->{AutoCommit};
    my $return_value = eval {
      my $sth = My::DBI->db_Main->prepare("select ?");
      $sth->execute( $random_number );
      my ($return_value) = $sth->fetchrow();
      $sth->finish();
      $return_value;
    };
    if( $@ )
    {
      $dbh->rollback();
      warn $@;
      return undef;
    }
    else
    {
      $dbh->commit();
      return ($return_value);
    }# end if()
  });
  
  my $fails = threads->create({context => 'list'}, sub {
    my $dbh = My::DBI->db_Main;
    
    local $dbh->{AutoCommit};
    my $return_value = eval {
      my $sth = My::DBI->db_Main->prepare("select ?");
      $sth->execute( $random_number );
      my ($return_value) = $sth->fetchrow();
      $sth->finish();
      die "This should fail";
      $return_value;
    };
    if( $@ )
    {
      $dbh->rollback();
      $@ =~ m{^This should fail} or die "Error not expected: $@";
      return undef;
    }
    else
    {
      $dbh->commit();
      return ($return_value);
    }# end if()
  });

  My::DBI->db_Main->do('select 1');
  
  is $succeeds->join() => $random_number, "successful worker returned what we expected";
  is $fails->join() => undef, "failing worker returned what we expected";

  My::DBI->db_Main->do('select 1');
}# end test_forking_then_select()




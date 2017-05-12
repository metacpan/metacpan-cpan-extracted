#!/usr/bin/perl -w

package My::DBI;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';

sub connection
{
  my ($s, $name, $dsn, $username, $password) = @_;
  
  $s->set_db($name, $dsn, $username, $password, {
    AutoCommit  => 1,
    RaiseError  => 1,
  });
}# end connection()

package My::T1;
use base 'My::DBI';
package My::T2;
use base 'My::DBI';


#sub _context { rand() }



package main;

use strict;
use warnings 'all';
use Carp 'confess';
use POSIX ':sys_wait_h';
use Test::More 'no_plan';
use Time::HiRes 'usleep';


use_ok 'Ima::DBI::Contextual';

unless( $ENV{IDBIC_DSN} )
{
  warn "\$ENV{IDBIC_DSN} must be set to run this test.  Set \$ENV{IDBIC_USER} and \$ENV{IDBIC_PASS} for username and password if necessary.\n";
  exit(0);
}# end unless()


My::T1->connection( 'Main', $ENV{IDBIC_DSN}, $ENV{IDBIC_USER}, $ENV{IDBIC_PASS} );
My::T2->connection( 'Slave1', $ENV{IDBIC_DSN}, $ENV{IDBIC_USER}, $ENV{IDBIC_PASS} );
My::T2->connection( 'Slave2', $ENV{IDBIC_DSN}, $ENV{IDBIC_USER}, $ENV{IDBIC_PASS} );
My::T2->connection( 'Slave3', $ENV{IDBIC_DSN}, $ENV{IDBIC_USER}, $ENV{IDBIC_PASS} );

test_forking_then_select() for 1..5;


sub test_forking_then_select
{
  # Select before we fork:
  for( 1..100 )
  {
    My::T1->db_Main->do('show processlist');
    My::T2->db_Slave1->do('show processlist');
    My::T2->db_Slave2->do('show processlist');
    My::T2->db_Slave3->do('show processlist');
  }
  
  # Now fork:
  my $pid = fork();
  if( $pid )
  {
    # Parent:
    My::T1->db_Main->do('show processlist');
    My::T2->db_Slave1->do('show processlist');
    My::T2->db_Slave2->do('show processlist');
    My::T2->db_Slave3->do('show processlist');
  }
  else
  {
    # Child:
    My::T1->db_Main->do('show processlist');
    My::T2->db_Slave1->do('show processlist');
    My::T2->db_Slave2->do('show processlist');
    My::T2->db_Slave3->do('show processlist');
    exit(0);
  }# end if()
  
  My::T1->db_Main->do('show processlist');
  My::T2->db_Slave1->do('show processlist');
  My::T2->db_Slave2->do('show processlist');
  My::T2->db_Slave3->do('show processlist');
}# end test_forking_then_select()




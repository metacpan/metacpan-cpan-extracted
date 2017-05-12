#!perl -T
use Test::More;
use Form::Toolkit::KVPairs::Pure;
use Form::Toolkit::KVPairs::DBICRs;

use DBI;
use DBD::SQLite;

package My::Schema;
use base qw/DBIx::Class::Schema::Loader/;
__PACKAGE__->naming('current');
1;
package main;



## Testing pure kvpairs
ok( my $pure_set = Form::Toolkit::KVPairs::Pure->new({ array => [ { 1 => 'Thing1'},
                                                         { 2 => 'Thing2'},
                                                         { 3 => 'Thing3' }
                                                       ]}) , "Ok can build set");
push @sets , $pure_set;

## Building a DBIC Base set.
my $dbh = DBI->connect("dbi:SQLite::memory:" , "" , "");
$dbh->{AutoCommit} = 1 ;
$dbh->do('CREATE TABLE thing(id INTEGER PRIMARY KEY, title VARCHAR(255) UNIQUE NOT NULL)');
my $schema = My::Schema->connect(sub{ return $dbh ;} , { unsafe => 1 });
my $rs = $schema->resultset('Thing');
foreach my $i ( 1..3 ){
  $rs->create({ id => $i , title => 'Thing'.$i});
}

ok( my $dbic_set = Form::Toolkit::KVPairs::DBICRs->new({ rs => $rs,
                                                key => 'id',
                                                value => 'title'
                                              }) , "Ok can build a dbic resultset base set");
push @sets , $dbic_set;

foreach my $set ( @sets ){
  cmp_ok( $set->size(), '==' , 3 , "Ok size is good");
  my $it = 0;
  while ( my @kv = $set->next_kvpair() ) {
    $it++;
  }
  cmp_ok( $it , '==' , 3 , "We went though the iteration 3 times");

  my @kv = $set->next_kvpair();
  cmp_ok( $kv[0] , '==' , 1 , "Got first kv pair (1)");
  cmp_ok( $kv[1] , 'eq' , 'Thing1' , "And it matches 'Thing1'");

  ok( my $two = $set->lookup(2) , "Ok can lookup 2");
  cmp_ok( $two , 'eq' , 'Thing2' , "Got the right thing back");
  ok( ! $set->lookup(47), "Cannot lookup 47");
}

done_testing();

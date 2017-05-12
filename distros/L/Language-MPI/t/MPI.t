# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MPI.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 1;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Language::MPI;

# dummy test callbacks
package Language::MPI;

sub mpi_neighbors 
{ my ($thisnode, $pattern) = @_;
  "neighbors:$thisnode,$pattern";
}
sub mpi_prop
{ my ($thisnode, $propname) = @_;
  "$thisnode/$propname";
}

sub mpi_props
{ my ($thisnode, $proppat) = @_;
  ("propa", "propb", "propc");
}

sub mpi_propset
{ my ($thisnode, $propname, $val) = @_;
  "$thisnode,$propname,$val";
}

package main;

$mpi = new Language::MPI('dummy node');

@tests =
( 'plain text, no MPI',
  '{toupper:lower to upper}',
  '1+2 = {add:1,2} = 2+1',
  '{tolower:{toupper:lower to upper to lower}}',
  '{for:i,1,4,1,{v:i} }',
  
  '{abs:-2}',
  '{add:1,2,3}',
  '{and:2,4,6}',
  '{attr:attribute...,text}',
  '{mklist:list,items}',
  '{set:list,{mklist:list,items}}',
  '{count:{v:list}',
  '{date:}',
  '{set:var,1}',
  '{v:var}',
  '{dec:var,2}',
  '{inc:var,4}',
  '{default:1,2}',
  '{dice:6,3,2}',
  '{dist:3,4}',
  '{div:81,9,3}',
  '{eq:var1,var1}',
  '{eval:vars...}',
  '{foreach:var,{v:list},:{v:var}:}',
  '{ge:2,2}',
  '{gt:2,1}',
  '{if:true,true statement,false statement}',
  '{insrt:string1,ing}',
  '{lcommon:{v:list},{mklist:items}}',
  '{le:1,2}',
  '{lmember:{v:list},items}',
  '{lit:{a:dummy,mpi}}',
  '{max:1,2,3}',
  '{min:1,2,3}',
  '{mod:9,4}',
  '{mult:2,4,8}',
  '{ne:var1,var2}',
  '::{nl:}::',
  '{not:true}',
  '{null:a big statement to execute but not keep a value from...}',
  '{or:1,2,0}',
  '{secs:}',
  '{sign:-100}',
  '{smatch:string,ing}',
  '{strip:  string   }',
  '{strlen:string}',
  '{subst:string,ing,ung}',
  '{subt:100,50,25}',
  '{time:}',
  '{version:}',
  '{set:var,3}',
  '{while:{v:var},{v:var}>>{dec:var,1}:}',
  '{with:var,{v:var}}',
  '{xor:1,1,1}',
  'The following are dummy without support functions',
  '{delprop:var,obj}',
  '{exec:prop,node}',
  '{index:prop,obj}',
  '{list:props,obj}',
  '{listprops:props,obj}',
  '{neighbors:varname,pattern,{v:varname}}',
  '{prop:property,node}',
  '{store:val,property,node}',
);

foreach $test (@tests)
{ print "test: $test\n";
  $result = $mpi->parse($test);
  print "result: [[$result]]\n\n";
}

ok(1); # dummy test

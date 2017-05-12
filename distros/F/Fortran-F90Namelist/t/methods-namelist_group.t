#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   methods-namelist_group.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module
#   Test all Fortran::F90Namelist::Group methods as described in the POD documentation

use strict;
use Test::More 'no_plan';
use Fortran::F90Namelist::Group;

use constant TEXT   => "&runpars\nx=2,y=3\nvec1=1,2,3\nvec2=3*1.3\n/";
use constant TEXT2  => "&spars\nx=2,y=3\n/\n&rpars\nvec1=1,2,3\nvec2=3*1.3\n/";
use constant BROKEN => "&nl\nX=6.,COOLTYPE='Temp    \n'COOL= 0.0\n/";

my @names_t2 = qw/ spars rpars /;

my ($parseresp,$text,$text2,$options);
my $file   = 't/files/one_list.nml';
my @slots  = qw/ string_q_var string_dq_var bool_var
                 int_var real_var double_var complex_var dcompl_var
               /;
my $file2  = 't/files/some_lists.nml';
my @names2 = qw/ nlist1 nlist2 nlist3 /;
my @slots2 = qw/ string_var1 int_var1 real_var1 double_var1
                 complex_var1 dcompl_var1 repeated_var

                 string_var2 int_var2 real_var2 double_var2
                 complex_var2 dcompl_var2

                 string_var3 int_var3 real_var3 double_var3
                 complex_var3 dcompl_var3
               /;
my @slots2_1st = qw/ string_var1 int_var1
                     real_var1 double_var1
                     complex_var1 dcompl_var1
                     repeated_var/;
my @slots2_2nd = map { my $v=$_; $v =~ s/1/2/; $v } @slots2_1st;

my %text2_hash =
  ( 'spars' => { 'y'    => { 'value' => [ 3 ],
                             'stype' => 'integer',
                             'type'  => 4
                           },
                 'x'    => { 'value' => [ 2 ],
                             'stype' => 'integer',
                             'type'  => 4
                           }
               },
    'rpars' => { 'vec2' => { 'value' => [ 1.3, 1.3, 1.3 ],
                             'stype' => 'unspecified float',
                             'type'  => 5
                           },
                 'vec1' => { 'value' => [ 1, 2, 3 ],
                             'stype' => 'integer',
                             'type'  => 4
                           }
               }
  );


##
## Object creation
##

my $nlgrp = Fortran::F90Namelist::Group->new();
isa_ok($nlgrp, 'Fortran::F90Namelist::Group', 'Is a Fortran::F90Namelist::Group object');
#
my @methods = qw/ new parse first nth hash nlists names delete insert flatten output /;
can_ok($nlgrp, @methods);

#
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist', 'Is a Fortran::F90Namelist object');


##
## $nlgrp->parse()
##

## Parsing strings

$parseresp = $nlgrp->parse(TEXT2);
is($parseresp, 2,  'Parsing constant string');
#
$text = TEXT2;
$parseresp = $nlgrp->parse($text);
is($parseresp, 2,  'Parsing string variable');


## Parsing files

$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2"             );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );

#
# Parsing from file handle
#
open(my $fh , "< $file2") or die "Couldn't get handle on $file2\n";
$parseresp = $nlgrp->parse(file => $fh);
is($parseresp,           3,         "Parsing $file2 via file handle object"             );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );
#
open(NLGROUP , "< $file2") or die "Couldn't get handle on $file2\n";
$parseresp = $nlgrp->parse(file => \*NLGROUP);
is($parseresp,           3,         "Parsing $file2 via FILE_HANDLE"             );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );

#
# Parsing with append => 1
#
$parseresp = $nlgrp->parse(text   => TEXT2,
                           append => 1     ); # re-parse the same file

is($parseresp,           2,         "Appending from TEXT2"                  );
is($nlgrp->nlists,       5,         "num. of slots from appending TEXT2"    );
is_deeply($nlgrp->names, [@names2, @names_t2],  "names from appending TEXT2");


##
## $nl->nlists()
## $nl->names()
##
# Already used extensively in other tests


##
## $nlgrp->insert()
##

#
# Get group
#
$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2"             );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );
#
# Get single namelist
#
$parseresp = $nl->parse(file => $file);
is($parseresp,        'nlist',  "Parsing $file");
is($nl->name,         'nlist',  "name from parsing $file");
#
# insert nl into group
#
# Append
my @names = @names2;
#
$nl->name('appended');
@names = (@names, 'appended');
is($nlgrp->insert($nl),   1,       "Appending nl to group"   );
is_deeply($nlgrp->names,  \@names, "names after appending nl");
# Prepend
$nl->name('prepended');
@names = ('prepended', @names);
is($nlgrp->insert($nl,0), 1,       "Prepending nl to group");
is_deeply($nlgrp->names,  \@names, "names after prepending nl");
# Insert
$nl->name('inserted');
splice(@names,2,0,'inserted');
is($nlgrp->insert($nl,2), 1,       "Inserting nl to group");
is_deeply($nlgrp->names,  \@names, "names after insertinging nl");


##
## $nlgrp->delete()
##

# Reuses the previous group of 6 namelists

# Delete by object
$nl->name('prepended');
shift @names;
is($nlgrp->delete($nl),        1,        "Deleting nl object");
is_deeply($nlgrp->names,       \@names,  "names after deleting nl object");
# Delete by name
pop @names;
is($nlgrp->delete('appended'), 1,        "Deleting nl by name");
is_deeply($nlgrp->names,       \@names,  "names after deleting by name");
# Delete by index
splice(@names,2,1);
is($nlgrp->delete(2),          1,        "Deleting nl by index");
is_deeply($nlgrp->names,       \@names,  "names after deleting by index");


##
## $nlgrp->first()
## $nlgrp->nth()
##

# Get group from file
$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2 for first()" );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );
#
$nl = $nlgrp->first();
is($nl->name,            'nlist1',      "Name of first() namelist"             );
is($nl->nslots,          @slots2_1st+0, "no. of slots in first() namelist"     );
is_deeply($nl->slots,    \@slots2_1st,  "slots in first() namelist"            );
#
is($nlgrp->nlists,       3,             "number of slots after calling first()");
is_deeply($nlgrp->names, \@names2,      "namelist names after calling first()" );


##
## $nlgrp->nth()
##

# Get group from file
$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2 for nth()"   );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );
#
$nl = $nlgrp->nth(1);
is($nl->name,            'nlist2',      "Name of nth() namelist"             );
is($nl->nslots,          @slots2_2nd+0, "no. of slots in nth() namelist"     );
is_deeply($nl->slots,    \@slots2_2nd,  "slots in nth() namelist"            );
#
is($nlgrp->nlists,       3,             "number of slots after calling nth()");
is_deeply($nlgrp->names, \@names2,      "namelist names after calling nth()" );


##
## $nlgrp->pop()
##

# Get group from file
$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2 for pop()"   );
is($nlgrp->nlists,       3,         "number of slots from $file2");
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2" );
#
$nl = $nlgrp->pop();
is($nl->name,            'nlist1',      "Name of pop()ed namelist"           );
is($nl->nslots,          @slots2_1st+0, "no. of slots in pop()ed namelist"   );
is_deeply($nl->slots,    \@slots2_1st,  "slots in pop()ed namelist"          );
#
is($nlgrp->nlists,       2,             "number of slots after calling pop()");
is_deeply($nlgrp->names, [@names2[1..$#names2]], "namelist names after calling pop()" );


##
## $nlgrp->flatten()
##

# Get group from file
$parseresp = $nlgrp->parse(file => $file2);
is($parseresp,           3,         "Parsing $file2 for flatten()");
is($nlgrp->nlists,       3,         "number of slots from $file2" );
is_deeply($nlgrp->names, \@names2,  "namelist names from $file2"  );
#
$nl = $nlgrp->flatten();
#
is($nl->name,         'nlist1',  "name from flattening"           );
is($nl->nslots,       @slots2+0, "number of slots from flattening");
is_deeply($nl->slots, \@slots2,  "slots from flattening"          );
#
is($nlgrp->nlists,       3,             "number of slots after flattening");
is_deeply($nlgrp->names, \@names2,      "namelist names after flattening" );
#
# Same with `name' option
#
$nl = $nlgrp->flatten( name => 'nlst');
is($nl->name,         'nlst',    "name from flatten(name=>'nlst')");
is($nl->nslots,       @slots2+0, "number of slots from flattening");
is_deeply($nl->slots, \@slots2,  "slots from flattening"          );


##
## $nlgrp->hash()
##

# Get group from file
$parseresp = $nlgrp->parse(TEXT2);
is($parseresp,           2,            "Parsing TEXT2 for hash()"  );
is($nlgrp->nlists,       2,            "number of slots from TEXT2");
is_deeply($nlgrp->names, \@names_t2,   "namelist names from TEXT2" );
is_deeply($nlgrp->hash,  \%text2_hash, "hash() method"             );
#


##
## $nlgrp->output()
##
# Not testing options here, as they are already checked in
# methods-namelist.t

$parseresp = $nlgrp->parse(TEXT2);
is($parseresp,           2,            "Parsing TEXT2 for hash()"  );
is($nlgrp->nlists,       2,            "number of slots from TEXT2");
is_deeply($nlgrp->names, \@names_t2,   "namelist names from TEXT2" );

#
# `f90' format
#
my $f90_nlgrp = <<'HERE';
&spars
  x=2,
  y=3
/
&rpars
  vec1=1,2,3,
  vec2=1.3,1.3,1.3
/
HERE
#
is ($nlgrp->output(),                $f90_nlgrp, "output()");

#
# `idl' format
#
my $idl_nlgrp = <<'HERE';
spars = { $
  x: 2, $
  y: 3 $
}
rpars = { $
  vec1: [1,2,3], $
  vec2: [1.3,1.3,1.3] $
}
HERE
#
is ($nlgrp->output(format => 'idl'), $idl_nlgrp, "output(format=>idl)");

#


# End of file methods-namelist.t

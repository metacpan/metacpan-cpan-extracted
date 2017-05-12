#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   methods-namelist.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module
#   Test all Fortran::F90Namelist methods as described in the POD documentation

use strict;
use Test::More 'no_plan';
use Fortran::F90Namelist;

use constant TEXT   => "&runpars\nx=2,y=3\nvec1=1,2,3\nvec2=3*1.3\n/";
use constant TEXT2  => "&spars\nx=2,y=3\n/\n&rpars\nvec1=1,2,3\nvec2=3*1.3\n/";
use constant BROKEN => "&nl\nX=6.,COOLTYPE='Temp    \n'COOL= 0.0\n/";

my ($parseresp,$text,$text2,$options);
my $file  = 't/files/one_list.nml';
my @slots = qw/ string_q_var string_dq_var bool_var
                int_var real_var double_var complex_var dcompl_var
              /;
my $file2 = 't/files/some_lists.nml';
my @slots2 = qw/ string_var1 int_var1 real_var1 double_var1
                 complex_var1 dcompl_var1 repeated_var

                 string_var2 int_var2 real_var2 double_var2
                 complex_var2 dcompl_var2

                 string_var3 int_var3 real_var3 double_var3
                 complex_var3 dcompl_var3
               /;
my @brokenslots = qw/ x cooltype cool /;

my %text_hash =
  ('y'    => { 'value' => [ 3 ],
               'stype' => 'integer',
               'type'  => 4
             },
   'vec2' => { 'value' => [ 1.3, 1.3, 1.3 ],
               'stype' => 'unspecified float',
               'type'  => 5
             },
   'vec1' => { 'value' => [ 1, 2, 3 ],
               'stype' => 'integer',
               'type'  => 4
             },
   'x'    => { 'value' => [ 2 ],
               'stype' => 'integer',
               'type'  => 4
             }
  );

##
## Object creation
##

my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist', 'Is a Fortran::F90Namelist object');
#
my @methods = qw/ new parse name nslots slots hash output /;
can_ok($nl, @methods);


##
## $nl->parse()
##

## Parsing strings

$parseresp = $nl->parse(TEXT);
is($parseresp, 'runpars', 'Parsing constant string');
#
$text = TEXT;
$parseresp = $nl->parse($text);
is($parseresp, 'runpars', 'Parsing string variable');
is($text,      '',        'parsing and modifying string variable');

#
# Parsing repeatedly from a string constant shouldn't succeed:
#
my @names;
$nl->parse(TEXT2);
$parseresp = $nl->parse(TEXT2);
isnt($parseresp, 'rpars', 'Repeated parsing of string constant');

#
# Parsing repeatedly from a string variable should succeed (and the string
# will be empty after we are through):
#
$text2 = TEXT2;
@names = ();
while(my $name = $nl->parse($text2)) {
    push @names, $name;
};
is_deeply(\@names, ['spars', 'rpars'], 'Repeated parsing from string variable');
is(       $text2,  '',                 'nothing left after repeated parsing from string variable');


## Parsing files

#
# Using filename
#
$parseresp = $nl->parse(file => $file);
is($parseresp,        'nlist',  "Parsing $file");
is($nl->name,         'nlist',  "name from parsing $file");
is($nl->nslots,       @slots+0, "number of slots from $file");
is_deeply($nl->slots, \@slots,  "slots from $file");

#
# From handle
#
open(my $fh , "< $file") or die "Couldn't get handle on $file\n";
$parseresp = $nl->parse(file => $fh);
is($parseresp,        'nlist',  "Parsing $file via file handle object");
is($nl->name,         'nlist',  "name from parsing $file");
is($nl->nslots,       @slots+0, "number of slots from $file");
is_deeply($nl->slots, \@slots,  "slots from $file");
#
open(HANDLE , "< $file") or die "Couldn't get handle on $file\n";
$parseresp = $nl->parse(file => \*HANDLE);
is($parseresp,        'nlist',  "Parsing $file via FILE_HANDLE");
is($nl->name,         'nlist',  "name from parsing $file");
is($nl->nslots,       @slots+0, "number of slots from $file");
is_deeply($nl->slots, \@slots,  "slots from $file");


#
# Parsing multi-namelist file
#
$parseresp = $nl->parse(file     => $file2,
                        all      => 1);
is($parseresp,        'nlist1',  "Parsing $file2 with all=>1");
is($nl->name,         'nlist1',  "name from parsing $file2");
is($nl->nslots,       @slots2+0, "number of slots from $file2");
is_deeply($nl->slots, \@slots2,  "slots from $file2");
#
# Same with `name' option
#
$parseresp = $nl->parse(file => $file2,
                        all  => 1,
                        name => 'nlst');
is($parseresp,        'nlst',  "Parsing $file2 with all=>1, name=>nlst");
is($nl->name,         'nlst',  "name from parsing $file2");
is($nl->nslots,       @slots2+0, "number of slots from $file2");
is_deeply($nl->slots, \@slots2,  "slots from $file2");
#
# Same with all options packed into a hashref
#
$options = { file => $file2,
             all  => 1,
             name => 'nlst',
           };
$parseresp = $nl->parse($options);
is($parseresp,        'nlst',  "Parsing $file2 with $options={all=>1, name=>nlst}");
is($nl->name,         'nlst',  "name from parsing $file2");
is($nl->nslots,       @slots2+0, "number of slots from $file2");
is_deeply($nl->slots, \@slots2,  "slots from $file2");

#
# merging in new data
#
my @tmpslots = (@slots2, @slots);
$parseresp = $nl->parse(file  => $file,
                        merge => 1);
is($parseresp,        'nlst',      "Parsing with merge=>1");
is($nl->name,         'nlst',      "name from merging");
is($nl->nslots,       @tmpslots+0, "number of slots from merging");
is_deeply($nl->slots, \@tmpslots,  "slots from merging");

#
# merging with duplicates
#
$text = TEXT;
$parseresp = $nl->parse($text);
is($parseresp,        'runpars', "Merging with duplicates -- setup");
$parseresp = $nl->parse(text    => "&nl\ny=5,z=-7\n/",
                        merge   => 1,
                        dups_ok => 1);
is($parseresp,        'runpars', "Merging with duplicates");
is($nl->nslots,       5,         "number of slots from merging with duplicates");
is_deeply($nl->slots, [qw/x y vec1 vec2 z/],  "slots from merging with duplicates");

#
# Broken namelist with broken=>0 (should fail)
#
undef $parseresp;
eval { $parseresp = $nl->parse(text => BROKEN) };
is($parseresp,      undef,      "Parsing broken namelist without net");

#
# Broken namelist with broken=>1 (should succeed)
#
$parseresp = $nl->parse(text   => BROKEN,
                        broken => 1);
is($parseresp,        'nl',           "Parsing broken namelist with net");
is($nl->name,         'nl',           "name from parsing");
is($nl->nslots,       @brokenslots+0, "number of slots from merging");
is_deeply($nl->slots, \@brokenslots,  "slots from merging");


##
## $nl->name()
##
# Getting name has been used a lot, so we now _set_ the name:
is($nl->name('new_namelist'), 'new_namelist', 'Setting name'      );
is($nl->name(),               'new_namelist', 'name after setting');


##
## $nl->nslots()
## $nl->slots()
##
# Already used extensively in other tests


##
## $nl->hash()
##
$text = TEXT;
$parseresp = $nl->parse($text);
is($parseresp,       'runpars',      "Parsing namelist for hash() method");
is($nl->name,        'runpars',      "name for hash()");
is($nl->nslots,      4,              "number of slots for hash()");
is_deeply($nl->hash, \%text_hash,    "hash() method");


##
## $nl->output()
##
$parseresp = $nl->parse("&runpars\nx=2,y=3.1\nstr1=2*'abc  ',str2=\"xy \"\n/");
is($parseresp,       'runpars',      "Parsing namelist for output() method");
is($nl->name,        'runpars',      "name for output()");
is($nl->nslots,      4,              "number of slots for output()");

#
# `f90' format
#
my $f90_nl = <<'HERE';
&runpars
  x=2,
  y=3.1,
  str1='abc  ','abc  ',
  str2='xy '
/
HERE
#
is ($nl->output(),                $f90_nl, "output()");
#
# Same with trim => 1
#
(my $f90_nl_trimmed = $f90_nl) =~ s{ +'}{'}g;
is ($nl->output(format => 'f90',
                trim   => 1), $f90_nl_trimmed, "output(format=>f90, trim=>1)");
#
# Same with double => 1
#
(my $f90_nl_double = $f90_nl) =~ s{3\.1}{3.1D0}mg;
is ($nl->output(double => 1), $f90_nl_double, "output(double=>1)");
#
# Same with oneline => 1
#
my $f90_nl_oneline = $f90_nl;
$f90_nl_oneline =~ s{\s*\n\s*}{ }mg;
$f90_nl_oneline =~ s{\s*$}{\n}; # re-instate final newline
is ($nl->output(oneline => 1), $f90_nl_oneline, "output(oneline=>1)");
#
# Same with maxslots => 2
#
my $f90_nl_maxsl2 = $f90_nl_oneline;
$f90_nl_maxsl2 =~ s{\s*(x=|str1=)}{\n  $1}g;
$f90_nl_maxsl2 =~ s{\s*/$}{\n/};   # re-instate newline before final `/'
is ($nl->output(maxslots => 2), $f90_nl_maxsl2, "output(maxslots=>2)");


#
# `idl' format
#
my $idl_nl = <<'HERE';
runpars = { $
  x: 2, $
  y: 3.1, $
  str1: ['abc  ','abc  '], $
  str2: 'xy ' $
}
HERE
#
is ($nl->output(format => 'idl'),                $idl_nl, "output(format=>idl)");
#
# Same with trim => 1
#
(my $idl_nl_trimmed = $idl_nl) =~ s{(abc|xy) +'}{$1'}g;
is ($nl->output(format => 'idl',
                trim   => 1), $idl_nl_trimmed, "output(format=>idl,trim=>1)");
#
# Same with double => 1
#
(my $idl_nl_double = $idl_nl) =~ s{3\.1}{3.1D0}mg;
is ($nl->output(format => 'idl',
                double => 1), $idl_nl_double, "output(format=>idl,double=>1)");
#
# Same with oneline => 1
#
my $idl_nl_oneline = $idl_nl;
$idl_nl_oneline =~ s{\s*\$\n\s*}{ }mg;
$idl_nl_oneline =~ s{\s*$}{\n}; # re-instate final newline
is ($nl->output(format  => 'idl',
                oneline => 1), $idl_nl_oneline, "output(format=>idl,oneline=>1)");
#
# Same with maxslots => 2
#
my $idl_nl_maxsl2 = $idl_nl_oneline;
$idl_nl_maxsl2 =~ s{\s*(x:|str1:)}{ \$\n  $1}g;
$idl_nl_maxsl2 =~ s[\s*}$][ \$\n}];   # re-instate newline before final `/'
is ($nl->output(format   => 'idl',
                maxslots => 2), $idl_nl_maxsl2, "output(format=>idl,maxslots=>2)");



# End of file methods-namelist.t

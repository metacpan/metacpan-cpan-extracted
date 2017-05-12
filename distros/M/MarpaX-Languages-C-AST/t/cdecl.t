#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use Test::Differences;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::Scan' ) || print "Bail out!\n";
}

my $filename = File::Spec->catfile('inc', 'cdecl.c');
my $c = MarpaX::Languages::C::Scan->new(asDOM => 1, filename => $filename);

eq_or_diff($c->cdecl,
           [
            'x: char ',
            'y: pointer to char ',
            'z: pointer to array[5] of char ',
            'zz: array[10] of array[11] of char ',
            'zzz: pointer to array[13] of array[14] of char ',
            'zzz2: array[13] of array[14] of pointer to char ',
            'Type definition of myStruct_t: myStruct: structure defined as {fp: pointer to function receiving (f: pointer to function receiving (arg1: char , arg2: long , arg3: array[5] of pointer to array[6] of pointer to pointer to float ) and returning pointer to char ) and returning int long long ; } ',
            'bsd_signal: function receiving (__ANON1: int , __ANON2: pointer to function receiving (__ANON3: int ) and returning void ) and returning pointer to function receiving (__ANON4: int ) and returning void ',
            'fp: pointer to function returning int ',
            'daytab: pointer to array[13] of int ',
            'f: array[10] of pointer to function receiving (__ANON5: int , __ANON6: int ) and returning void ',
            'x: function returning pointer to array[] of pointer to function returning char ',
            'x: array[3] of pointer to function returning pointer to array[5] of char ',
            'arr: array[5] of pointer to function returning pointer to function returning pointer to int ',
            'bsd_signal: function receiving (sig: int , func: pointer to function receiving (__ANON7: int ) and returning void ) and returning pointer to function receiving (__ANON8: int ) and returning void ',
            'f: pointer to function receiving (__ANON9: pointer to pointer to int , __ANON10: pointer to function receiving (__ANON11: pointer to pointer to int , __ANON12: pointer to pointer to int ) and returning pointer to pointer to int ) and returning pointer to pointer to int ',
            'fun_one: pointer to function receiving (__ANON13: pointer to char , __ANON14: double ) and returning pointer to array[9] of array[20] of int ',
            'i: int ',
            'p: pointer to int ',
            'a: array[] of int ',
            'f: function returning int ',
            'pp: pointer to pointer to int ',
            'pa: pointer to array[] of int ',
            'pf: pointer to function returning int ',
            'ap: array[] of pointer to int ',
            'aa: array[] of array[] of int ',
            'af: array[] of int ',
            'fp: function returning pointer to int ',
            'fa: function returning int ',
            'ppp: pointer to pointer to pointer to int ',
            'ppa: pointer to pointer to array[] of int ',
            'ppf: pointer to pointer to function returning int ',
            'pap: pointer to array[] of pointer to int ',
            'paa: pointer to array[] of array[] of int ',
            'pfp: pointer to function returning pointer to int ',
            'app: array[] of pointer to pointer to int ',
            'apa: array[] of pointer to array[] of int ',
            'apf: array[] of pointer to function returning int ',
            'aap: array[] of array[] of pointer to int ',
            'aaa: array[] of array[] of array[] of int ',
            'afp: array[] of pointer to int ',
            'fpp: function returning pointer to pointer to int ',
            'fpa: function returning pointer to array[] of int ',
            'fpf: function returning pointer to function returning int ',
            'fap: function returning pointer to int ',
            'ptr: pointer to function receiving (__ANON15: int ) and returning pointer to function receiving (__ANON16: pointer to pointer to double , c: char ) and returning pointer to float ',
            'ptr: pointer to array[5] of pointer to function receiving (__ANON17: pointer to read-only char , __ANON18: pointer to int ) and returning pointer to pointer to unsigned '
           ],
          'cdecl');

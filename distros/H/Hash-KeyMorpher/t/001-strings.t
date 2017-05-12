#!/usr/bin/perl -w

use Hash::KeyMorpher;
use Test::More tests => 33;

# define strings
my $s1 = 'myVar';
my $s2 = 'MyVar';
my $s3 = 'my_var';
my $s4 = 'myBad_var';
my $s5 = 'MYVAR';
my $s6 = 'myvar';

# _split_words
is_deeply([Hash::KeyMorpher::_split_words($s1)],['my','var'],"_split_words ($s1)");
is_deeply([Hash::KeyMorpher::_split_words($s2)],['my','var'],"_split_words ($s2)");
is_deeply([Hash::KeyMorpher::_split_words($s3)],['my','var'],"_split_words ($s3)");
is_deeply([Hash::KeyMorpher::_split_words($s4)],['my','bad','var'],"_split_words ($s4)");
is_deeply([Hash::KeyMorpher::_split_words($s4)],['my','bad','var'],"_split_words ($s4)");
is_deeply([Hash::KeyMorpher::_split_words($s5)],['myvar'],"_split_words ($s5)");
is_deeply([Hash::KeyMorpher::_split_words($s6)],['myvar'],"_split_words ($s6)");

# to_camel
is(to_camel($s1),'MyVar',"to_camel ($s1)");
is(to_camel($s2),'MyVar',"to_camel ($s2)");
is(to_camel($s3),'MyVar',"to_camel ($s3)");
is(to_camel($s4),'MyBadVar',"to_camel ($s4)");
is(to_camel($s5),'Myvar',"to_camel ($s5)");
is(to_camel($s6),'Myvar',"to_camel ($s6)");

# to_mixed
is(to_mixed($s1),'myVar',"to_mixed ($s1)");
is(to_mixed($s2),'myVar',"to_mixed ($s2)");
is(to_mixed($s3),'myVar',"to_mixed ($s3)");
is(to_mixed($s4),'myBadVar',"to_mixed ($s4)");
is(to_mixed($s5),'myvar',"to_mixed ($s5)");
is(to_mixed($s6),'myvar',"to_mixed ($s6)");

# to_under
is(to_under($s1,'_'),'my_var',"to_under ($s1)");
is(to_under($s2,'_'),'my_var',"to_under ($s2)");
is(to_under($s3,'_'),'my_var',"to_under ($s3)");
is(to_under($s4,'_'),'my_bad_var',"to_under ($s4)");
is(to_under($s5,'_'),'myvar',"to_under ($s4)");
is(to_under($s6,'_'),'myvar',"to_under ($s4)");

# to_delim
is(to_delim($s1,'-'),'my-var',"to_delim '-' ($s1)");
is(to_delim($s2,'-'),'my-var',"to_delim '-' ($s2)");
is(to_delim($s3,'-'),'my-var',"to_delim '-' ($s3)");
is(to_delim($s4,'-'),'my-bad-var',"to_delim '-' ($s4)");
is(to_delim($s5,'-'),'myvar',"to_delim '-' ($s4)");
is(to_delim($s6,'-'),'myvar',"to_delim '-' ($s4)");
is(to_delim($s4),'mybadvar',"to_delim '' ($s4)");
is(to_delim($s4,'^'),'my^bad^var',"to_delim '^' ($s4)");

exit 0;

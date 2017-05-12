#!/usr/bin/perl -w
$::_test = 1;
use IO::String;
use GnaData::Read::Tsv;
use Test;

BEGIN {plan tests=>3;}
$io = IO::String->new(<<EOP);
foo	bar	boom
---	---	----
foo	bar	1
eek	am	2
454	343	3432
EOP

    my ($load) = GnaData::Read::Tsv->new;
$load->open({'handle'=>$io});
my (@field_list) = $load->fields();
ok(compare_arrays(\@field_list, ["foo", "bar", "boom"]));
my (%f) = ();
$load->read(\%f);
ok($f{'foo'}, "foo");

my($ioa) = IO::String->new(<<EOP);
foo	bar	boom
foo	bar	1
eek	am	2
454	343	3432
EOP
$load->open({'handle'=>$ioa});
%f = ();
$load->read(\%f);
ok($f{'foo'}, "foo");



           sub compare_arrays {
               my ($first, $second) = @_;
               no warnings;  # silence spurious -w undef complaints
               return 0 unless @$first == @$second;
               for (my $i = 0; $i < @$first; $i++) {
                   return 0 if $first->[$i] ne $second->[$i];
               }
               return 1;
           }

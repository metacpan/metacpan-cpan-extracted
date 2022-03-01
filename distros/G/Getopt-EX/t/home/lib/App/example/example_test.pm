package App::example::example_test;
use strict;
use warnings;
no  warnings 'redefine';

our $opt_number;
our @opt_list;
our %opt_hash;
our $opt_string;

sub opt_string {
    $opt_string = $_[1];
}

1;

__DATA__

builtin set-number=i $opt_number
builtin set-list=s   @opt_list
builtin set-hash=s   %opt_hash
builtin set-str=s    &opt_string

option default --default

option --deprecated $<move(0,0)>
option --ignore-me $<ignore>
option --shift-here --shift-$<shift>
option --exch $<move(1,1)>
option --remove-next $<remove(0,1)>
option --double-next $<copy(0,1)>

define what poison
option --drink-me what

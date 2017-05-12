#!/usr/bin/perl
require './t/testlib.pl';
use strict;
use lib './lib';
use Metadata::DB;

# MEANT TO BE PROFILED


# --------------------------------
my $s = Metadata::DB::Base->new({DBH => _get_new_handle() });



# HERES WHAT WE WANT

# then get entries for each and time it using various ways.
for ( 1 .. 1000 ){   
   my $id = $_;
   my $hashref = $s->_record_entries_hashref_2($id);
}





#!/usr/bin/perl -w

use strict;

my $alias_dir = '/home/alias/aliases';

die "Alias directory '$alias_dir' does not exist\n" unless -d $alias_dir;

# uncomment this line to remove the first line of a message, if you use
# procmail to deliver to an mbox
# <>;

use Mail::SimpleList;
Mail::SimpleList->new( $alias_dir )->process();

#!/usr/bin/perl
# $Id: fork.pl,v 1.2 2012/01/14 10:33:30 dk Exp $
use strict;
use IO::Lambda qw(:lambda);
use IO::Lambda::Fork qw(forked);

lambda {
    context 0.1, forked {
          select(undef,undef,undef,0.8);
          return "hello!";
    };
    any_tail {
        if ( @_) {
            print "done: ", $_[0]-> peek, "\n";
        } else {
            print "not yet\n";
            again;
        }
    };
}-> wait;


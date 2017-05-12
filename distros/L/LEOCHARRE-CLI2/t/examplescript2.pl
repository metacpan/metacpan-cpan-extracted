#!/usr/bin/perl
use strict;
use lib './lib';
use LEOCHARRE::CLI2 'n:'; # we dont specify h, d, v, but they are inserted by force.
# use LEOCHARRE::CLI2 'hdvn:'; # this would be ok too.

our $VERSION = 1;

$opt_n or die("missing -n name arg\n");

print "Hello $opt_n\n";

exit;



sub usage {
   qq{$ENV{SCRIPT_FILENAME} [OPTION]...

   -d          debug
   -h          help
   -v          version
   -n string   your name
   
Try 'perldoc $0' for more info in called inside distro.
Try 'man $ENV{SCRIPT_FILENAME}' for more info, if installed via a Makefile.PL.
}
}


# simply call as 
# perl ./t/examplescript -h

__END__

=pod

=head1 NAME

examplescript2.pl

=head1 DESCRIPTION

Hi there.
You notice here that we say to call perldoc for more info..
If you install this via a Makefile.PL, man $ENV{SCRIPT_FILENAME} will be avaible.

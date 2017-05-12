#!/usr/bin/perl
# The hierarchy shown here is based on an example Damian Conway's book
# "Object Oriented Perl"
#
# Usage:  ./isatest.pl >isa.png
use warnings;
use strict;
use GraphViz::ISA;
sub Coder::new      { bless {}, (ref($_[0]) || $_[0]) }
sub Documenter::new { bless {}, (ref($_[0]) || $_[0]) }
@Programmer::ISA = qw(Coder Documenter);
sub Obfuscator::new { bless {}, (ref($_[0]) || $_[0]) }
@Perl::Hacker::ISA = qw(Programmer Obfuscator);
sub Writer::new           { bless {}, (ref($_[0]) || $_[0]) }
sub Humorist::new         { bless {}, (ref($_[0]) || $_[0]) }
sub One::Sick::Puppy::new { bless {}, (ref($_[0]) || $_[0]) }
@Punmeister::ISA = qw(Writer Humorist One::Sick::Puppy);
sub Language::Maestro::new { bless {}, (ref($_[0]) || $_[0]) }
sub Educator::new          { bless {}, (ref($_[0]) || $_[0]) }
@Perl::Guru::ISA = qw(Perl::Hacker Language::Maestro Educator Punmeister);
my $p = Perl::Guru->new;
my $g = GraphViz::ISA->new($p);
print $g->as_png;

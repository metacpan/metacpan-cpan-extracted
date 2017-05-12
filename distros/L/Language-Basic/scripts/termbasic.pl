#!/usr/bin/perl -w

use strict;
use Language::Basic;
use Term::ReadLine;

my $program = Language::Basic::Program->new();

my $prompt = '> ';

my $term = Term::ReadLine->new('BASIC interpreter');

my $OUT = $term->OUT || *STDOUT;

select $OUT;  # Really, there should be a way to do this without assuming
              # that Basic only prints to the selected handle

print $OUT "Language::Basic interpreter with ", $term->ReadLine(), " support\n";

while ( defined (my $line = $term->readline($prompt)) ) {
    $term->addhistory($line) if $line =~ /\S/;
    
    if ($line =~ /^\s*\d+\s+/) {
	$program->line($line);
    } elsif ($line =~ /^\s*RUN\s*$/i) {
	$program->implement;
    } elsif ($line =~ /^\s*QUIT\s*$/i) {
	print $OUT "Bye!\n";
	exit;
    } else {
	print $OUT "Invalid command; try RUN, QUIT, or defining a statement with a number.\n";
    } 
} 



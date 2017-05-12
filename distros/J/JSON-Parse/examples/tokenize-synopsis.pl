#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Tokenize ':all';
my $input = '{"tuttie":["fruity", true, 100]}';
my $token = tokenize_json ($input);
print_tokens ($token, 0);

sub print_tokens
{
    my ($token, $depth) = @_;
    while ($token) {
	my $start = tokenize_start ($token);
	my $end = tokenize_end ($token);
	my $type = tokenize_type ($token);
	print "   " x $depth;
	my $value = substr ($input, $start, $end - $start);
	print ">>$value<< has type $type\n";
	my $child = tokenize_child ($token);
	if ($child) {
	    print_tokens ($child, $depth+1);
	}
	my $next = tokenize_next ($token);
	$token = $next;
    }
}

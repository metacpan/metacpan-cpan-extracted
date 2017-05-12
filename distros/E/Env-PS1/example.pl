#!/usr/bin/perl

use Env::PS1 qw/$PS1/;

my @demo = (
	username => '\u',
	'current dir' => '\w',
	'basename current dir' => '\W',
	hostname => '\H',
	'short hostname' => '\h',
	'basename $0' => '\s',
	date => '\d',
	'terminaldevice basename' => '\l',
	'terminal device' => '\L',
	time => '\t',
	time => '\T',
	time => '\@',
	time => '\A',
);

my ($i, $l) = (0, 0);
length($_) > $l and $l = length($_) for grep {++$i % 2} @demo;
$l += 2;

print "Most escapes are one character long, like these:\n";

while (@demo) {
	my ($k, $v) = ( shift(@demo), shift(@demo) );
	$ENV{PS1} = $v;
	print $k, ' 'x($l - length($k)), "$v  =  $PS1\n";
}

print "\nAlso their are two escapes with arguments:\n";

$ENV{PS1} = '\\D{%a %b %e %H:%M:%S %Y}';
print "strftime format    \\D{\%a \%b \%e \%H:\%M:\%S \%Y}\n\t= $PS1\n";

$ENV{PS1} = q(\\C{bold,red}shiny isn't it ?\\C{reset});
print "and ANSI colours   \\C{bold,red}shiny isn't it ?\\C{reset}\n\t= $PS1\n";

$ENV{PS1} = '\\P{%u up %w users, loadavg: %L}';
print "and some proc info \\P{\%u up \%w users, loadavg: \%L}\n\t= $PS1\n";

print "\nAnd now for some real prompts:\n\n";

print Env::PS1->sprintf($_), "\n\n" for
	'\C{bold,blue}\u@\H \A \C{green}\W\$\C{reset} ',
	'\[\033[01;31m\]\h \[\033[01;34m\]\W \$ \[\033[00m\]',
	'\C{green}\D{%H:%M:%S} \W\$\C{reset} ',
	'\C{bold,black}/--( \u@\H )-( \t )-( \w )- * *\n\\\\-- * \$\C{reset} ';
	
__END__

=head1 NAME

example.pl - some prompts demonstrated

=head1 DESCRIPTION

This script demonstrates the module by
showing the supported escape sequences and some prompts.


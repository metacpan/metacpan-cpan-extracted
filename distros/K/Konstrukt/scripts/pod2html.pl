#!/usr/bin/perl

use strict;
use warnings;

#overwrite this stupid helpOptions method
package MyOpt;

use Getopt::Simple;
@MyOpt::ISA = qw/Getopt::Simple/;

sub helpOptions {
	my ($self) = @_;

	my $options = $self->{default};

	#find longest command
	my $len = 0;
	foreach my $key (keys %{$options}) {
		$len = length $key if length $key > $len;
	}
	#print out help screen
	print "$self->{helpText}\n\n";
	foreach my $key (sort { $options->{$a}->{order} <=> $options->{$b}->{order} } keys %{$options}) {
		my @lines = split /\n/, $options->{$key}->{verbose};
		push (@lines, "Defaults to $options->{$key}->{default}") if defined $options->{$key}->{default};
		print "-$key" . ' ' x ($len - length $key) . " - " . (shift @lines) . "\n";
		foreach my $line (@lines) {
			print ' ' x ($len + 1) . "   $line\n";
		}
	}
}

package Pod::Simple::CustomHTML;

use base 'Pod::Simple::HTML';
$Pod::Simple::HTML::Doctype_decl = qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n};

1;

package main;

use Pod::Simple::HTMLBatch;

my($options) = {
	help => {
		verbose => 'This help screen.',
		order   => 1,
	},
	source => {
		type    => '=s',
		default => '.',
		verbose => 'The source directory of the perl modules that should be converted.',
		order   => 2,
	},
	target => {
		type    => '=s',
		default => '../doc',
		verbose => 'The target directory where the HTML files will be stored.',
		order   => 3,
	},
	css => {
		type    => '=s',
		default => 'cpan.css',
		verbose => 'The CSS file which should be used.',
		order   => 4,
	},
	index => {
		type    => '=i',
		default => '0',
		verbose => 'Create an index.html or not.',
		order   => 5,
	},
};

my $option = MyOpt->new();

unless ($option->getOptions($options, "Usage: $0 [options]")) {
	$option->helpOptions();
	exit(-1);
}

if ($option->{help}) {
	$option->helpOptions();
	exit(0);
}

my $batchconv = Pod::Simple::HTMLBatch->new();

$batchconv->html_render_class('Pod::Simple::CustomHTML');

$batchconv->index(1);
$batchconv->css_flurry(undef);
$batchconv->javascript_flurry(undef);
$batchconv->add_css($option->{switch}->{css});
$batchconv->contents_file($option->{switch}->{index} ? 'index.html' : undef);

$batchconv->batch_convert($option->{switch}->{source} , $option->{switch}->{target});

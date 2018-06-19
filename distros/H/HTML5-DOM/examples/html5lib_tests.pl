#!/usr/bin/perl
package main;

use warnings;
use strict;

use HTML5::DOM;
use Data::Dumper;
use Getopt::Long;
use File::Slurp qw|read_file write_file read_dir|;
use List::Util qw|min max|;

my $show_help			= 0;
my $enable_diff			= 0;
my $enable_colordiff	= 0;
my $html5lib_tests_dir	= "";

GetOptions (
	"dir=s"		=> \$html5lib_tests_dir, 
	"diff"		=> \$enable_diff, 
	"colordiff"	=> \$enable_colordiff, 
	"help"		=> \$show_help
);

$enable_diff = 1 if ($enable_colordiff);

if ($show_help || !$html5lib_tests_dir) {
	print "--dir			path to html5lib-tests/tree-construction\n";
	print "--diff			enable diff between expected and result (if fail)\n";
	print "--colordiff		enable color diff between expected and result (if fail)\n";
	exit;
}

main();

sub main {
	# html5lib tests sections:
	#	data					- input data
	#	document				- expected output
	#	document-fragment		- context tag and namespace for fragments
	#	errors
	#	new-errors
	#	script-off
	#	script-on
	my @tests;
	for my $file (glob("$html5lib_tests_dir/*.dat")) {
		my $test;
		my $key;
		my $test_id = 0;
		for my $line (split(/\n/, read_file($file)."\n")) {
			if ($line eq "#data") {
				if ($test) {
					$test->{document} =~ s/\n\n$//s;
					$test->{data} =~ s/\n$//s;
					push @tests, $test;
				}
				
				$file =~ s/^\Q$html5lib_tests_dir\E\/?//g;
				$test = {
					file	=> $file, 
					test_id	=> $test_id++
				};
			}
			
			if (substr($line, 0, 1) eq '#') {
				$key = substr($line, 1);
				$test->{$key} = "";
			} else {
				$test->{$key} .= $line."\n";
			}
		}
	}
	
	my $stat = {
		success		=> 0, 
		failed		=> 0, 
		skipped		=> 0, 
		total		=> 0
	};
	my $stat_by_file = {};
	for my $test (@tests) {
		if ($test->{data}) {
			my $root;
			my $skip;
			if ($test->{"document-fragment"}) {
				my @parts = split(/\s+/, $test->{"document-fragment"});
				my $tag = scalar(@parts) > 1 ? $parts[1] : $parts[0];
				my $ns = scalar(@parts) > 1 ? $parts[0] : "html";
				
				my $tree = HTML5::DOM->new({
					scripts	=> exists $test->{'script-on'} ? 1 : 0
				})->parse('');
				
				$ns = "mathml" if ($ns eq 'math'); # fixme
				
				if ($tree->namespace2id($ns) == HTML5::DOM->NS_UNDEF) {
					$skip = "Unsupported namespace `$ns`";
				} else {
					$root = $tree->parseFragment($test->{data}, $tag, $ns);
				}
			} else {
				$root = HTML5::DOM->new({
					scripts	=> exists $test->{'script-on'} ? 1 : 0
				})->parse($test->{data})->document;
			}
			
			if (!exists $stat_by_file->{$test->{file}}) {
				$stat_by_file->{$test->{file}} = {
					success		=> 0, 
					failed		=> 0, 
					skipped		=> 0, 
					total		=> 0
				};
			}
			
			++$stat->{total};
			++$stat_by_file->{$test->{file}}->{total};
			
			if ($skip) {
				dumpTest($test, undef, "$skip");
				++$stat->{skipped};
				++$stat_by_file->{$test->{file}}->{skipped};
			} else {
				my $result = printTree($root);
				if ($result ne $test->{document}) {
					dumpTest($test, $result, "unexpected result");
					++$stat->{failed};
					++$stat_by_file->{$test->{file}}->{failed};
				} else {
					++$stat->{success};
					++$stat_by_file->{$test->{file}}->{success};
				}
			}
		}
	}
	
	my $table = [['test', 'total', 'ok', 'fail', 'skip']];
	for my $file (sort { $stat_by_file->{$b}->{failed} <=> $stat_by_file->{$a}->{failed} } keys %$stat_by_file) {
		my $stat = $stat_by_file->{$file};
		push @$table, [$file, $stat->{total}, $stat->{success}, $stat->{failed}, $stat->{skipped}];
	}
	push @$table, ['summary', $stat->{total}, $stat->{success}, $stat->{failed}, $stat->{skipped}];
	
	printTable($table);
}

# Dump test if failed
sub dumpTest {
	my ($test, $result, $reason) = @_;
	
	print "[failed] Test #".$test->{test_id}." in ".$test->{file}.": $reason\n";
	print "--------------------------------------------------------------------\n";
	
	if (exists $test->{'script-on'} || exists $test->{'script-off'} || exists $test->{'document-fragment'}) {
		print "scripts: on\n" if (exists $test->{'script-on'});
		print "scripts: off\n" if (exists $test->{'script-off'});
		print "fragment: ".$test->{'document-fragment'}."\n" if (exists $test->{'document-fragment'});
		print "--------------------------------------------------------------------\n";
	}
	
	print $test->{data}."\n";
	print "--------------------------------------------------------------------\n";
	
	if (defined $result) {
		if ($enable_diff) {
			my $tmp_result_file = "/tmp/html5lib-test-$$-".int(rand(time))."-result.diff";
			my $tmp_expected_file = "/tmp/html5lib-test-$$-".int(rand(time))."-expected.diff";
			
			write_file($tmp_result_file, $result);
			write_file($tmp_expected_file, $test->{document});
			
			my $diff;
			if ($enable_colordiff) {
				$diff = `diff --label="result" --label="expected" -Naur "$tmp_result_file" "$tmp_expected_file" | colordiff`;
			} else {
				$diff = `diff --label="result" --label="expected" -Naur "$tmp_result_file" "$tmp_expected_file"`;
			}
			
			unlink($tmp_result_file);
			unlink($tmp_expected_file);
			
			print $diff;
			print "--------------------------------------------------------------------\n";
		} else {
			print $test->{document}."\n";
			print "--------------------------------------------------------------------\n";
			
			print $result."\n";
			print "--------------------------------------------------------------------\n";
		}
	}
	
	print "\n";
}

# Serializator to strange html5tests format
sub printTree {
	my ($node, $level) = @_;
	
	$level = -1 if (!defined $level);
	
	my $out = "";
	
	# print node
	if ($node->nodeType != HTML5::DOM->DOCUMENT_NODE && $node->nodeType != HTML5::DOM->DOCUMENT_FRAGMENT_NODE) {
		$out .= "| ";
		for (my $i = 0; $i < $level; ++$i) {
			$out .= "  ";
		}
		
		if ($node->nodeType == HTML5::DOM->DOCUMENT_TYPE_NODE) {
			my $dt = "<!DOCTYPE ";
			
			if ($node->name ne "") {
				$dt .= $node->name;
				
				if ($node->systemId ne "" || $node->publicId ne "") {
					$dt .= ' "'.$node->publicId.'"';
					$dt .= ' "'.$node->systemId.'"';
				}
			}
			
			$dt .= ">";
			
			$out .= $dt;
		} elsif ($node->nodeType == HTML5::DOM->COMMENT_NODE) {
			$out .= "<!-- ".$node->text." -->";
		} elsif ($node->nodeType == HTML5::DOM->TEXT_NODE) {
			$out .= '"'.$node->text.'"';
		} elsif ($node->nodeType == HTML5::DOM->ELEMENT_NODE) {
			if ($node->namespace eq 'HTML') {
				$out .= "<".$node->tag.">";
			} elsif (lc($node->namespace) eq 'mathml') { # fixme
				$out .= "<math ".$node->tag.">";
			} else {
				$out .= "<".lc($node->namespace)." ".$node->tag.">";
			}
		}
	}
	
	$out .= "\n" if (length($out));
	
	# print attributes
	if ($node->nodeType == HTML5::DOM->ELEMENT_NODE) {
		for my $attr (sort { $a->{name} cmp $b->{name} } @{$node->attrArray}) { # todo: implement https://developer.mozilla.org/ru/docs/Web/API/Element/attributes
			$out .= "| ";
			for (my $i = 0; $i < $level + 1; ++$i) {
				$out .= "  ";
			}
			$out .= lc($attr->{namespace})." " if ($attr->{namespace} ne "HTML");
			$out .= $attr->{name}."=\"".$attr->{value}."\"";
			$out .= "\n";
		}
	}
	
	# print childrens
	if ($node->nodeType == HTML5::DOM->DOCUMENT_NODE || $node->nodeType == HTML5::DOM->DOCUMENT_FRAGMENT_NODE || $node->nodeType == HTML5::DOM->ELEMENT_NODE) {
		if ($node->namespace eq "HTML" && $node->tag eq "template") {
			$out .= "| ";
			for (my $i = 0; $i < $level + 1; ++$i) {
				$out .= "  ";
			}
			$out .= "content\n";
			++$level;
		}
		
		for my $child (@$node) {
			$out .= printTree($child, $level + 1);
		}
	}
	
	$out =~ s/\n$//g if ($level == -1);
	
	return $out;
}

sub printTable {
	my $table = shift;
	
	my $maxlength = {};
	for my $row (@$table) {
		my $i = 0;
		for my $col (@$row) {
			$maxlength->{$i} = 0 if (!exists $maxlength->{$i});
			$maxlength->{$i} = max($maxlength->{$i}, length($col));
			++$i;
		}
	}
	
	my $ii = 0;
	for my $row (@$table) {
		my $i = 0;
		for my $col (@$row) {
			print $col;
			if ($i != scalar(@$row) - 1) {
				for (my $x = 0; $x < ($maxlength->{$i} + 4) - length($col); ++$x) {
					print " ";
				}
			}
			++$i;
		}
		print "\n";
		
		if (!$ii) {
			my $i = 0;
			for my $col (@$row) {
				for (my $x = 0; $x < $maxlength->{$i} + 4; ++$x) {
					print "-";
				}
				++$i;
			}
			print "\n";
		}
		
		++$ii;
	}
}

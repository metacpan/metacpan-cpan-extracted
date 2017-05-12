#!/usr/bin/perl
use blib;
use strict;
use warnings;

use Benchmark qw(cmpthese timethese);
use HTML::Template;
use HTML::Template::JIT;

our @tests = (
	      {
	       filename => '../t/templates/cond.tmpl',
	       param => [
			 [ true => 1 ],
			 [ false => 0 ],
			 [ true_loop => [ { var => 'foo' } ] ],
			 [ false_loop => [] ],
			 [ values => [ { value => 2, even => 1 },
				       { value => 3, even => 0 },
				      { value => 10, even => 1 },
				     ] ],
			]
	      },
	      {
	       filename => '../t/templates/chunky.tmpl',
	       param => [
			 [ ai => 'ai',
			   z => 'z',
			   month => 'November',
			   year => '2001' ],
			],
	      },
	      { 
	       filename => '../t/templates/loopdeloop.tmpl',
	       global_vars => 1,
	       param => [
			 [
			  global_var1 => 'foo',
			  global_var2 => 'bar',
			  global_var3 => 'baz',
			  outer_loop => [
					 (
					  { 
					   outer_var1 => "foo" x 10,
					   outer_var2 => "bar" x 10,
					   outer_var2 => "baz" x 5,
					   inner_loop => [
							  ({
							   inner_var1 => "fooz" x 5,
							   inner_var2 => "fooz" x 20,
							   inner_var3 => "fooz" x 50,
							   }) x 5
							 ]
					  } ) x 10
					]
			 ]
			]
	      },

	     );
our @run_tests;
if (@ARGV) {
  @run_tests = @ARGV;
} else {
  @run_tests = (0 .. $#tests);
}


# prime the JIT cache

system "rm -rf benchmark_jit_path";
mkdir "benchmark_jit_path", 0700;

print STDERR "Priming caches...\n";
foreach my $test_num (@run_tests) {
  print STDERR "Compiling $tests[$test_num]->{filename}...\n";
  print STDERR " ...with HTML::Template::JIT\n";
  HTML::Template::JIT->new(filename => $tests[$test_num]->{filename},
                           jit_path => "benchmark_jit_path");
  print STDERR " ...with HTML::Template::JIT print_to_stdout => 1\n";
  HTML::Template::JIT->new(filename => $tests[$test_num]->{filename}, 
                           jit_path => "benchmark_jit_path", 
                           print_to_stdout => 1);
  print STDERR " ...with HTML::Template cache => 1\n";
  HTML::Template->new(filename => $tests[$test_num]->{filename},
                      cache => 1);
}

print STDERR "Running tests...\n";
open(OLDOUT, ">&STDOUT")  or die "Could not dup STDOUT : $!";
select(OLDOUT);
open(STDOUT, ">", "test.out") or die "Could not redirect STDOUT : $!";

my $r = timethese(-5,
	 {
	  'JIT' => sub { run_test('HTML::Template::JIT', { jit_path => "benchmark_jit_path" }) },
	  'JIT print' => sub { run_test('HTML::Template::JIT', { jit_path => "benchmark_jit_path",  print_to_stdout => 1}) },
	  'HTML::Template' => sub { run_test('HTML::Template', { cache => 1 }) },
	 }, 'none');
cmpthese($r);


sub run_test {
  my ($package, $options) = @_;
  
  foreach my $test_num (@run_tests) {
    my $template = $package->new(filename => $tests[$test_num]->{filename}, %$options);
    foreach my $set (@{$tests[$test_num]->{param}}) {
      $template->param(@$set);
    }
    if (exists $options->{print_to_stdout}) {
      $template->output();
    } else {
      print STDOUT $template->output();
    }
  }
}


package ImplicitTest;
use Test::More tests => 26;
use Devel::DumpTrace::PPI ':test';
use PPI;
use strict;
use warnings;

*preval = \&Devel::DumpTrace::PPI::preval;
*__add_implicit_elements = \&Devel::DumpTrace::PPI::__add_implicit_elements;

sub to_PPI_Statement {
  my $code = shift;
  $::doc = new PPI::Document(\$code);  # must keep document in scope
  my $s = $::doc->find('PPI::Statement');
  for my $ss (@{$s}) {
    __add_implicit_elements($ss);   # added for v0.10
    Devel::DumpTrace::PPI::__add_implicit_to_given_when_blocks($ss)
	if ref($ss) eq 'PPI::Statement::Given';
  }
  return $s->[0];
}

# implicit $_ =~ qr/regexp/
# implicit $_ in built in functions
# implicit @_ or @ARGV in shift, pop

$_ = "FOOasdfBAR";
my $doc = new PPI::Document(\'m{asdf} && print "Contains asdf\n"'); #');
my $s = $doc->find('PPI::Statement');
__add_implicit_elements($s->[0]);
my @z = preval($s->[0], 1, __PACKAGE__);
ok("@z" =~ /\$_:.*$_.*=~\s*m\{asdf\}/,
   "implicit \$_=~ inserted before regexp");

$s = to_PPI_Statement('s/hello/hey/i && print "$_ world\n"');       #');
@z = preval($s, 1, __PACKAGE__);
ok("@z" =~ m!\$_:.*$_.*=~\s*s/hello/hey/i!,
   "implicit \$_=~ inserted before substitution");


@z = preval(
	    to_PPI_Statement('my $z = log;'),
	    1, __PACKAGE__);
ok("@z" =~ m/\$_/,
   "inserted implicit \$_ for builtin function");

@z = preval(
	    to_PPI_Statement('my $z = ref'),
	    1, __PACKAGE__);
ok("@z" =~ m/\$_/,
   "inserted implicit \$_ for builtin function");

@z = preval(
	    to_PPI_Statement('my $z = shift'),
	    1, __PACKAGE__);
ok("@z" =~ m/\@ARGV/,
   "inserted implicit \@ARGV to shift/pop call");


sub naked_pop_inside_sub_test {
  my @z = preval(
	    to_PPI_Statement('$b = pop'),
	    1, __PACKAGE__);
  ok("@z" =~ m/\@_/,
     "inserted implicit \@_ after shift/pop call inside sub")
  or diag(@z);
}
&naked_pop_inside_sub_test();


@z = preval(
	    to_PPI_Statement('if (-f)'),
	    1, __PACKAGE__);
ok("@z" =~ m/-f\s+\$_/,
   "inserted implicit \$_ for file test");

@z = preval(
	    to_PPI_Statement('if (-t)'),
	    1, __PACKAGE__);
ok("@z" !~ m/\$_/,
   "no implicit \$_ for -t file test");



# implicit smart match in given/when statements
#
# if you have an old Perl (pre given-when statements) but
# a newer version of PPI, these tests will still pass

SKIP: {

    if ($PPI::VERSION < 1.205) {
	skip "no given/when statements in PPI v$PPI::VERSION", 17;
    }


# 1. when expressions that should have implicit smart match
    for my $expr ('undef', '7.5', '"foo"', '$bar', '@bar', '[@bar]',
	      '\@bar', '[1,3,5,7,9]', ) {

        @z = preval(
            to_PPI_Statement('given($foo) { when (' . $expr . ') { say } }'),
            1, __PACKAGE__);

        ok("@z" =~ m/\$_:\S+\s*~~/ || "@z" =~ m/\$foo:\S+\s*~~/,
           "implicit smart match for when ($expr) {...} expression")
            or diag("processed statement was:  ",@z,", expected smart match");


    }

# 2. when expressions that should NOT have implicit smart match
    foreach my $expr ('defined', 'exists $bar{$_}', 'eof', '-d',
		  'm{pattern}', '!$bar', '$bar..$baz',
		  '$bar < $baz', '$bar == $baz', '\&func') {

        @z = preval(
            to_PPI_Statement('given($foo) { when (' . $expr . ') { say } }'),
            1, __PACKAGE__);

        ok("@z" !~ m/\$_:\S+\s*~~/ && "@z" !~ m/\$foo:\S+\s*~~/,
           "no implicit smart match for when ($expr) {...} expression")
            or diag("processed statement was:  ", @z,
                    ", expected no smart match");
    }

}

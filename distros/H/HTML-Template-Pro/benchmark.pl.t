### HTML::Template is required for benchmark.
# Before `make install' is performed this script should be runnable with
# prove -l -b benchmark.pl. 
# After `make install' it should work as `perl benchmark.pl'
#########################

use Test;
BEGIN { plan tests => 1};
use Benchmark;
use HTML::Template;
use HTML::Template::Pro;
ok(1); # If we made it this far, we're ok.


#########################

my $tmpl;
my $output;

my @varset1=(VAR1=>VAR1,VAR2=>VAR2,VAR3=>VAR3,VAR10=>VAR10);
my @varset2=(STUFF1 => '<>"; %FA');
my @refset1=(
HASHREF0=>[],
HASHREF2=>[{},{}],
HASHREF1=>[
{LOOPVAR1=>'LOOP1-VAR1',LOOPVAR2=>'LOOP1-VAR2',LOOPVAR3=>'LOOP1-VAR3',LOOPVAR10=>'LOOP1-VAR10'},
{LOOPVAR1=>'LOOP2-VAR1',LOOPVAR2=>'LOOP2-VAR2',LOOPVAR3=>'LOOP2-VAR3',LOOPVAR10=>'LOOP2-VAR10'},
{LOOPVAR1=>'LOOP3-VAR1',LOOPVAR2=>'LOOP3-VAR2',LOOPVAR3=>'LOOP3-VAR3',LOOPVAR10=>'LOOP3-VAR10'},
{LOOPVAR1=>'LOOP4-VAR1',LOOPVAR2=>'LOOP4-VAR2',LOOPVAR3=>'LOOP4-VAR3',LOOPVAR10=>'LOOP4-VAR10'},
]);

#test_tmpl('test_loop1', @varset1, @refset1);
#test_tmpl('test_loop2', @varset1, @refset1);
#test_tmpl('test_loop3', @varset1, @refset1);

test_tmpl('test_var1', @varset1);
test_tmpl('test_var2', @varset1);
test_tmpl('test_var3', @varset1, @varset2);
test_tmpl('test_if1',  @varset1);
test_tmpl('test_if2',  @varset1);
test_tmpl('test_if3',  @refset1);
#test_tmpl('test_include1', @varset1);
#test_tmpl('test_include2', @varset1);
test_tmpl('test_loop1', @varset1, @refset1);
test_tmpl('test_loop2', @varset1, @refset1);
test_tmpl('test_loop3', @varset1, @refset1);
test_tmpl('test_loop4', @varset1, @refset1);
test_tmpl('test_loop5', @varset1, @refset1);


# -------------------------

sub test_tmpl {
    my $testname=shift;
    my @param=@_;
    &test_tmpl_complete($testname,@param);
    &test_tmpl_output($testname,@param);
}

sub test_tmpl_output {
    my $testname=shift;
    my $tmpl;
    my $output;
    chdir 'templates-Pro';
    my $file=$testname;
    open (OUTFILE, ">/dev/null");
    $tmplo=HTML::Template->new(filename=>$file.'.tmpl', die_on_bad_params=>0, strict=>0, case_sensitive=>0, loop_context_vars=>1);
    $tmpl=HTML::Template::Pro->new(filename=>$file.'.tmpl', loop_context_vars=>1, case_sensitive=>0);
    $tmplo->param(@_);
    $tmpl->param(@_);
    my $count=1000;
    $t = timeit($count, sub {$tmpl->output(print_to => *OUTFILE);});
    print "N:$testname:output only: $count loops of new code took:\n",timestr($t),"\n";
    $t = timeit($count, sub {$tmplo->output(print_to => *OUTFILE);});
    print "O:$testname:output only: $count loops of old Template.pm took:\n",timestr($t),"\n";
    $tmpl->output(print_to => *OUTFILE);
    close (OUTFILE);
    chdir '..';
}

sub test_tmpl_complete {
    my $testname=shift;
    my @param=@_;
    my $tmpl;
    my $output;
    chdir 'templates-Pro';
    my $file=$testname;
    open (OUTFILE, ">/dev/null");
    $tmplo=HTML::Template->new(filename=>$file.'.tmpl', die_on_bad_params=>0, strict=>0, case_sensitive=>0, loop_context_vars=>1);
    $tmplo->param(@_);
    my $count=1000;
    $t = timeit($count, sub {
	$tmpl=HTML::Template::Pro->new(filename=>$file.'.tmpl', loop_context_vars=>1, case_sensitive=>0, die_on_bad_params=>0);
	$tmpl->param(@param);
	$tmpl->output(print_to => *OUTFILE);
    });
    print "N:$testname:complete: $count loops of new code took:\n",timestr($t),"\n";
    $t = timeit($count, sub {
	$tmpl=HTML::Template->new(filename=>$file.'.tmpl', loop_context_vars=>1, case_sensitive=>0, die_on_bad_params=>0);
	$tmpl->param(@param);
	$tmpl->output(print_to => *OUTFILE);
    });
    print "O:$testname:complete: $count loops of old Template.pm took:\n",timestr($t),"\n";
    $tmpl->output(print_to => *OUTFILE);
    close (OUTFILE);
    chdir '..';
}


### Local Variables: 
### mode: perl
### End: 

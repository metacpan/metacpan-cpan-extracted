# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Pro.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN {
    my $test_tmpl_std = 4;
    my $test_tmpl = 2;
    plan tests => 1+$test_tmpl_std*21+$test_tmpl*5;
}
use File::Spec;
use HTML::Template::Pro;
use lib "t";
use HTML::Template::Pro::CommonTest;
ok(1); # If we made it this far, we're ok.

#########################

my @varset1=(VAR1=>'VAR1',VAR2=>'VAR2',VAR3=>'VAR3',VAR10=>'VAR10');
my @varset2=(STUFF1 => '&foo"bar\'</script>=-;+ \<>"; %FA'."hidden:\r\012end", STUFF2=>'Some"'."' Txt'");
my @refset1=(
HASHREF0=>[],
HASHREF2=>[{},{}],
HASHREF1=>[
{LOOPVAR1=>'LOOP1-VAR1',LOOPVAR2=>'LOOP1-VAR2',LOOPVAR3=>'LOOP1-VAR3',LOOPVAR10=>'LOOP1-VAR10'},
{LOOPVAR1=>'LOOP2-VAR1',LOOPVAR2=>'LOOP2-VAR2',LOOPVAR3=>'LOOP2-VAR3',LOOPVAR10=>'LOOP2-VAR10'},
{LOOPVAR1=>'LOOP3-VAR1',LOOPVAR2=>'LOOP3-VAR2',LOOPVAR3=>'LOOP3-VAR3',LOOPVAR10=>'LOOP3-VAR10'},
{LOOPVAR1=>'LOOP4-VAR1',LOOPVAR2=>'LOOP4-VAR2',LOOPVAR3=>'LOOP4-VAR3',LOOPVAR10=>'LOOP4-VAR10'},
]);
my @outer=({TEST=>'1'},{TEST=>'2'},{TEST=>'3'});
my @inner=({TST=>'A'},{TST=>'B'});
my @refset2=(INNER=>\@inner, OUTER=>\@outer);

if ($ENV{HTP_TEST_BROKEN}) {
    # manual test
    test_tmpl_std('test_broken', @varset1, @refset1);
}

test_tmpl_std('test_esc1', @varset1, @varset2);
test_tmpl_std('test_esc2', @varset1, @varset2);
test_tmpl_std('test_esc3', @varset1, @varset2);
test_tmpl_std('test_esc4', @varset1, @varset2);

test_tmpl_std('test_var1', @varset1);
test_tmpl_std('test_var2', @varset1);
test_tmpl_std('test_var3', @varset1, @varset2);
test_tmpl_std('test_if1',  @varset1);
test_tmpl_std('test_if2',  @varset1);
test_tmpl_std('test_if3',  @refset1);
test_tmpl_std('test_if4',  @varset1);
test_tmpl_std('test_if5',  @varset1);
test_tmpl_std('test_if7',  @varset1);
test_tmpl_std('test_include1', @varset1);
test_tmpl('test_include2', [max_includes=>10], @varset1);
test_tmpl_std('test_include3', @varset1);
test_tmpl('test_include4', [path=>['include/1', 'include/2']]);
test_tmpl('test_include5', [path=>['include/1', 'include/2'], search_path_on_include=>1]);
test_tmpl_std('test_loop1', @varset1, @refset1);
test_tmpl_std('test_loop2', @varset1, @refset1);
test_tmpl_std('test_loop3', @varset1, @refset1);
test_tmpl_std('test_loop4', @varset1, @refset1);
test_tmpl_std('test_loop5', @varset1, @refset1);
test_tmpl('test_loop6',[loop_context_vars=>1,global_vars=>1], @refset2);

test_tmpl_std('include/2', 'LIST', [{TEST => 1}, {TEST=>2}]);

# todo: use config.h and grep defines from here
# if IMITATE==1 (-DCOMPAT_ALLOW_NAME_IN_CLOSING_TAG)
#test_tmpl_std('test_if6',  @varset1);

my $devnull=File::Spec->devnull();
if (defined $devnull) {
    close (STDERR);
    #open(STDERR, '>>', $devnull); # is better, but seems not for perl 5.005
    open (STDERR, '>/dev/null') || print STDERR "devnull: $!\n";
}
test_tmpl('test_broken1',[debug=>-1], @varset1, @refset1);
# not a test -- to see warnings on broken tmpl
# test_tmpl_std('test_broken', @varset1, @refset1);

### Local Variables: 
### mode: perl
### End: 

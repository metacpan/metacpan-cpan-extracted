if($] < 5.00393) {
    print "1..0\n";
    warn "skipping loops tests for Perl version $]\n";
    exit();
}

$Is_Win32 = ($^O eq "MSWin32");
$tests = 18;
--$tests if $Is_Win32;

print "1..$tests\n";

chdir "t" if -d "t";
$p = "./loop";

sub test {
    my($num, $code) = @_;
    $pat = "ok $num.*" x 10;
    $s = `$p -e "$code; print qq{ok $num}"`;
    print "ok $num\n" if $s =~ /$pat/;
}

@n = split //, `$p -e "print qq{.}"`;
$n = 10;
for (1..scalar @n) {
    print "ok $_\n";
}

test ++$n, 'use FileHandle (); FileHandle->new;'; 

test ++$n, <<'EOF' unless $Is_Win32; #command shell can't deal
package Scotch;
@ISA = qw(Drink);
package Drink;
sub drink {1}

package main;
drink Scotch or die;

EOF

#syntax error, currently leaks
test ++$n, 'eval q($oops =;)';

for (qw{strict English}) {
    test ++$n, "use $_";
}

#reset rs ok?
test ++$n, 'die unless $/ eq qq{\\n}; $/=undef;';

test ++$n, 'die if ' . 
    join(' || ', 
    'defined $scalar',
    'defined @array',
    'defined %hash ;')    .
    '@array = (1..3); %hash = (a=>1);';

printf "ok %d\n", ++$n if(`$p eval.test` =~ /ok 16\n1\.\.16/);


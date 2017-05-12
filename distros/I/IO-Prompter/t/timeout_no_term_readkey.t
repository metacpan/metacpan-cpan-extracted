
use lib qw< slib >;

use 5.010;
use warnings;
use Test::More;

use IO::Prompter;

if (!-t *STDIN || !-t *STDERR) {
    plan('skip_all' => 'Non-interactive test environment');
}
else {
    plan('no_plan');
}

my $output;
open my $out_fh, '>', \$output;

my $start_time;

# Long form, non-zero delay fail...
if (prompt q{}, -timeout=>1.5, -out=>$out_fh) {
    fail 'Time-out of -timeout=>1.5'; 
}
else {
    pass 'Time-out of -timeout=>1.5'; 
}

# Long form, instantaneous fail...
if (prompt q{}, -timeout=>0, -out=>$out_fh) {
    fail 'Time-out of -timeout=>0'; 
}
else {
    pass 'Time-out of -timeout=>0'; 
}

# Short form, non-zero delay fail...
if (prompt q{}, -t1, -out=>$out_fh) {
    fail 'Time-out of -t1'; 
}
else {
    pass 'Time-out of -t1'; 
}

# Short form, instantaneous fail...
if (prompt q{}, -t0, -out=>$out_fh) {
    fail 'Time-out of -t0'; 
}
else {
    pass 'Time-out of -t0'; 
}

# Short form, instantaneous success...
if (prompt q{}, -t0, -in=>*DATA, -out=>$out_fh) {
    pass 'Non-time-out of -t0'; 
    is $_, 'Data line 1' => 'Correct input';
}
else {
    fail 'Non-time-out of -t0'; 
}

# Short form, instantaneous success, non-file...
my $pseudofile = "Pseudofile line 1\n";
open my $fh, '<', \$pseudofile
    or die $!;
if (prompt q{}, -t0, -in=>$fh, -out=>$out_fh) {
    pass 'Non-time-out of -t0'; 
    is $_, 'Pseudofile line 1' => 'Correct input';
}
else {
    fail 'Non-time-out of -t0'; 
}

__DATA__
Data line 1
Data line 2

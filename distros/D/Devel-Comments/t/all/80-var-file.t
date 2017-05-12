
BEGIN { 
    $::log_filename		= 'devel-comments-test.log';
    
}


use Devel::Comments ({ -file => $::log_filename });
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $scalar = 'scalar value';
my @array = (1..3);
my %hash  = ('a'..'d');

### $scalar
### @array;
### %hash

my $expected = <<"END_MESSAGES";

#\## \$scalar: 'scalar value'
#\## \@array: [
#\##           1,
#\##           2,
#\##           3
#\##         ]
#\## \%hash: {
#\##          a => 'b',
#\##          c => 'd'
#\##        }
END_MESSAGES


#~ close $::log_filename;
open my $log_fh, '<', $::log_filename;

my $prev_fh         = select $log_fh;
local $/            = undef;            # slurp
select $prev_fh;

my $log_slurp   = <$log_fh>;

is $log_slurp, $expected      => 'Simple variables to filename work';

close $log_fh;

is $STDERR, ''              => 'No output to STDERR';

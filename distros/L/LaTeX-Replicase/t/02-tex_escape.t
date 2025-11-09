# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 13;
use Test::More::UTF8;
# use Test::NoWarnings;

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(:all);

##### Test replication() #####

### Test 2-10
my $t = 2;
my @arr = (
	['&','\&'],
	['%','\%'],
	['$','\$'],
	['#','\#'],
	['_','\_'],
	['{','\{'],
	['}','\}'],
	['^','\^{}'],
	['\\','\textbackslash'],
);

for( @arr ) {
	my( $v, $r ) = @$_;
	tex_escape($v);
	is( $v, $r, 'Test #'. $t .": '$_->[0]' to '$r'");
	++$t;
}

###Test 11
$_ = '~';
tex_escape( $_, '~');
is( $_, '\texttt{\~{}}', "Test #11: '~'");

###Test 12
my $r = $_ = 'qwertyuiopasdfghjklzxcvbnm1234567890';
tex_escape($_);
is( $_, $r, 'Test #12');

###Test 13
$_ = '%%%:~\frac{12345}{67890}';
tex_escape($_);
is( $_, '~\frac{12345}{67890}', "Test #13: '%%%:'");


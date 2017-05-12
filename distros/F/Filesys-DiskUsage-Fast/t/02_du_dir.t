use strict;
use warnings;
use ExtUtils::testlib;
use Test::More;
use Scalar::Util qw(looks_like_number);

use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

if( not -r "/bin" or not -r "/etc" ){
	plan skip_all => "seems not unix os";
}

my $list = [
	[ "undef", undef => 0 ],
	[ "empty", "" => 0 ],
	[ "no existent", "/no/existent" => 0 ],
	[ "du /etc", "/etc" => 1 ],
	[ "du /bin /etc", ["/bin", "/etc"] => 1 ],
];

for( 1 .. 10 ){
	for my $pair( @{ $list } ){
		my ($name, $input, $expected) = @{ $pair };
		
		my $total = Filesys::DiskUsage::Fast::du( ref $input ? @{ $input } : $input );
		ok( looks_like_number $total, "test '$name' looks like a number" );
		if( $expected ){
			ok( $total > 0, "test '$name' result > 0" );
			ok( $total < 1_100_000_000, "test '$name' result < 1_100_000_000" );
		}
		else{
			ok( $total == 0, "test '$name' results 0" );
		}
	}
}

done_testing;

__END__

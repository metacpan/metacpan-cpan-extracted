package Testophile;

use v5.40;
use lib;

use Test::More;
use Symbol      qw( qualify_to_ref );

my $madness = 'FindBin::Bin';
my @importz = qw( $Bin &Bin );

note "INC is:\n" => explain \@INC;

require_ok $madness;

eval { $madness->import( @importz ) };
$@ and fail "Import fails: $@";

my $ref     = qualify_to_ref 'Bin';

my $expect  = eval{ ${ *$ref }  };
my $found   = eval{ &{ *$ref }  };

if( $found && $expect )
{
    is $found, $expect, "Bin returns '$expect' ($found)";
}
elsif( $expect )
{
    fail '$Bin not exported';
}
elsif( $found )
{
    fail 'Bin returns undef';
}
else
{
    fail 'Bin and $Bin not exported';
}

done_testing;

__END__

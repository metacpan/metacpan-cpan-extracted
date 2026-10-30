package Testophile;

use v5.40;
use lib;

use Test::More;
use Symbol      qw( qualify_to_ref );

my $madness = 'FindBin::Bin';
my @importz = qw( $Bin &Bin $Bin_l &Bin_l );

note "INC is:\n" => explain \@INC;

require_ok $madness;

eval { $madness->import( @importz ) };
$@ and fail "Import fails: $@";

for my $name ( qw( Bin Bin_l ) )
{
    my $ref     = qualify_to_ref $name;

    my $expect  = eval{ ${ *$ref }  };
    my $found   = eval{ &{ *$ref }  };

    if( $found && $expect )
    {
        is $found, $expect, "\$$name matches ${name}() ('$expect')";
    }
    elsif( $expect )
    {
        fail "\$$name not exported";
    }
    elsif( $found )
    {
        fail "${name}() returns undef";
    }
    else
    {
        fail "${name}() and \$$name not exported";
    }
}

done_testing;

__END__

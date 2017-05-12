use warnings;
use strict;
use Test::More;

#use Your::Module;

my @exports
#    = qw( func1 func2 )
    ;
my @not_exports
#    = qw( func3 func4 )
    ;

plan +(@exports + @not_exports)
    ? ( tests       => @exports + @not_exports                  )
    : ( skip_all    => q{This module doesn't export anything}   )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( ! __PACKAGE__->can($not_export) );
}

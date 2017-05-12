use strict;
use warnings;

use Fennec class => 'Data::Dumper';

ok( $INC{'Data/Dumper.pm'}, "Loaded \$CLASS" );
can_ok( __PACKAGE__, 'class' );
lives_ok { is( $CLASS, 'Data::Dumper', "Imported \$CLASS" ) };

tests method => sub {
    my $self = shift;
    is( $self->class, 'Data::Dumper', "Injected 'class' method" );
};

done_testing;


use strict;
use warnings;

use Test::More;
use Term::ANSIColor 2.01 qw( colorstrip );

BEGIN {
    if ( __FILE__ =~ qr{\A(.*?)\bclan\.t\z} ) {
        my $dir = $1;
        require lib;
        lib->import("$dir/../../examples/clan/lib");
    }
}

my @warners;
{
    local $SIG{__WARN__} = sub {
        push @warners, $_[0];
    };
    local $ENV{MY_PROJECT_UPTO} = 'trace';
    require My::Project;
    My::Project->import();
    My::Project->run();
}

sub grep_level {
    my ( $level, ) = @_;
    return grep { colorstrip($_) =~ qr/\Q$level\E/ } @warners;
}

is( scalar @warners,             3, "3 events seen" );
is( scalar grep_level('[trace'), 2, "2 trace level events" );
is( scalar grep_level('[warn'),  1, "1 warn level events" );

done_testing;


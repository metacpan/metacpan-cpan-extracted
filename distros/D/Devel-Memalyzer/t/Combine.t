#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use IO qw/Handle File Pipe/;

my $CLASS = 'Devel::Memalyzer::Combine';

# A newer Test::More would give us done_testing()
eval { tests(); 1 } || ok( 0, $@ );
cleanup();

sub cleanup {
    unlink( 't/merge' ); #Do not care about errors.
    unlink( 't/merge.head' ); #Do not care about errors.
    unlink( 't/merge.raw' ); #Do not care about errors.
}

sub tests {
    use_ok( $CLASS, 'combine' );
    can_ok( __PACKAGE__, 'combine' );
    cleanup();
    link( 't/res/merge.head', 't/merge.head' );
    link( 't/res/merge.raw', 't/merge.raw' );
    combine( 't/merge' );

    local $/ = '';
    open( my $merge, '<', 't/merge' );
    my $data = <$merge>;
    is(
        $data,
        <<EOT,
z,y,x,d,c,b,a
,,,4,3,2,1
,,,4,3,2,1
,,,4,3,2,1
9,8,,,,2,1
9,8,,,,2,1
9,8,,,,2,1
9,8,,,,2,1
9,8,7,,,,
9,8,7,,,,
9,8,7,,,,
9,8,7,,,,
9,8,7,,,,
EOT
        "Merged headers and data"
    );
}


__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation


#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use IO qw/Handle File Pipe/;

my $CLASS = 'Devel::Memalyzer::Runner';

# A newer Test::More would give us done_testing()
eval { tests(); 1 } || ok( 0, $@ );

sub tests {
    use_ok( $CLASS );
    can_ok( $CLASS, qw/command interval / );

    my $one = $CLASS->new( command => "$^X -e 'sleep(2)'" );
    ok( my $pid = $one->_run, "_run (got pid)" );
    waitpid( $pid, 0 );

    throws_ok { $one->_run  }
        qr/already ran/,
        "Don't execute twice";

    my $record;
    {
        no strict 'refs';
        no warnings 'redefine';
        no warnings 'once';
        # This will trick runner to call record on itself, and we define that
        # next.
        *Devel::Memalyzer::singleton = sub { shift };
        *Devel::Memalyzer::record = sub { $record++ };
    }

    $one = $CLASS->new( command => "$^X -e 'sleep(5)'" );
    $one->run;
    # Don't rely on sleep in our command to be exact here.
    ok( $record > 3, "Iterated at least 3 times" );
    ok( $record < 8, "Iterated less than 8 times" );

    $record = 0;
    $one = $CLASS->new( command => "$^X -e 'sleep(5)'", interval => 0.2 );
    $one->run;
    # Don't rely on sleep in our command to be exact here.
    ok( $record > (3/0.2), "Iterated at least: " . (3/0.2));
    ok( $record < (8/0.2), "Iterated less than: " . (8/0.2));
}

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation


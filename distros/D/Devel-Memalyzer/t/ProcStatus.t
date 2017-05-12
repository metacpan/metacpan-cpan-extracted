#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

my $CLASS = 'Devel::Memalyzer::Plugin::ProcStatus';

# A newer Test::More would give us done_testing()
eval { tests(); 1 } || ok( 0, $@ );

sub tests {
    return missing_tests() unless -e '/proc';
    use_ok( $CLASS );

    my $one = $CLASS->new;
    is( $one->status(1234), "/proc/1234/status", "Proper status file" );

    no warnings qw/redefine once/;
    local *Devel::Memalyzer::Plugin::ProcStatus::status = sub {
        return "t/res/status";
    };

    is_deeply(
        { $one->collect },
        {
            'VmLib'  => '3710',
            'VmData' => '1924',
            'VmLck'  => '0',
            'VmStk'  => '792',
            'VmExe'  => '706',
            'VmRSS'  => '3596',
            'VmSize' => '9424'
        },
        "Got proper columns"
    );
}

sub missing_tests {
    my $ret = eval "require $CLASS; 1";
    ok( !$ret, "Cannot load without /proc" );
    like( $@, qr{$CLASS cannot be used without a proc filesystem}, "Useful message" );
}

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation


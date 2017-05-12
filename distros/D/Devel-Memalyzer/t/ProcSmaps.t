#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

my $CLASS = 'Devel::Memalyzer::Plugin::ProcSmaps';

# A newer Test::More would give us done_testing()
eval { tests(); 1 } || ok( 0, $@ );

sub tests {
    return missing_tests() unless -e '/proc';
    use_ok( $CLASS );

    my $one = $CLASS->new;
    is( $one->smaps(1234), "/proc/1234/smaps", "Proper smaps file" );

    no warnings qw/redefine once/;
    local *Devel::Memalyzer::Plugin::ProcSmaps::smaps = sub {
        return "t/res/smaps";
    };

    is_deeply(
        { $one->collect },
        {
            '/lib/perl5/site_perl/5.6.1/i686-linux-multi/auto/DBD/Pg/Pg.so'      => '92',
            '/lib/perl5/5.6.1/i686-linux-multi/auto/Data/Dumper/Dumper.so'       => '24',
            '/lib/perl5/site_perl/5.6.1/i686-linux-multi/auto/DBI/DBI.so'        => '108',
            '/lib/perl5/site_perl/5.6.1/i686-linux-multi/auto/List/Util/Util.so' => '32',
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


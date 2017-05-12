use Test::More;
my $tests;
BEGIN { $tests = 0 }
use lib "lib";
use File::Rsync::Mirror::Recentfile;
use File::Rsync::Mirror::Recentfile::FakeBigFloat qw(_increase_a_bit _bigfloatlt);

{
    BEGIN { $tests += 5 }
    my $rf = File::Rsync::Mirror::Recentfile->new;
    for my $x ([-12, undef],
               [0, 0],
               [undef, undef],
               [(12)x2],
               [(12000000000000)x2],
              ) {
        my $ret = eval { $rf->interval_secs(defined $x->[0] ? $x->[0] . "s" : ()); };
        is $ret, $x->[1];
    }
}

{
    BEGIN { $tests += 5 }
    my $rf = File::Rsync::Mirror::Recentfile->new;
    for my $x (["12s" => 12],
               ["12m" => 720],
               ["2h"  => 7200],
               ["1d"  => 86400],
               ["4Q"  => 31104000],
              ) {
        my $ret = $rf->interval_secs ( $x->[0] );
        is $ret, $x->[1];
    }
}

{
    my @x;
    BEGIN {
        @x = (
              ["1" => "2"],
              ["1" => undef],
              ["0.99999999900000080543804870103485882282257080078125",
               "0.9999999990000010274826536260661669075489044189453125"],

# the following is an interesting example because I saw this in the debugger:
#   DB<104> x "123456789123456789.2" <=> "123456789123456790"
# 0  1

              ["123456789123456789","123456789123456790"],
             );
        for (@x) {
            if (defined $_->[1]) {
                $tests += 2;
            } else {
                $tests++;
            }
        }
    }
    for my $x (@x) {
        my $ret = _increase_a_bit ( $x->[0], $x->[1] );
        ok _bigfloatlt($x->[0], $ret), "L: $x->[0] < $ret";
        if (defined $x->[1]) {
            ok _bigfloatlt($ret, $x->[1]), "R: $ret < $x->[1]";
        }
    }
}

{
    my @x;
    BEGIN {
        @x = split /\n/, <<EOT;
ge 1195248431   997872011
ge 1195248431.1 997872011
ge 1195248431   997872011.1
ge 1195248431.1 997872011.1
gt 1195248431   997872011
gt 1195248431.1 997872011
gt 1195248431   997872011.1
gt 1195248431.1 997872011.1
ge 1234567891195248431   123456789997872011
ge 1234567891195248431.1 123456789997872011
ge 1234567891195248431   123456789997872011.1
ge 1234567891195248431.1 123456789997872011.1
gt 1234567891195248431   123456789997872011
gt 1234567891195248431.1 123456789997872011
gt 1234567891195248431   123456789997872011.1
gt 1234567891195248431.1 123456789997872011.1
EOT
        $tests += @x;
    }
    for my $line (@x) {
        my($func,@arg) = split " ", $line;
        $func = \&{"File::Rsync::Mirror::Recentfile::FakeBigFloat::_bigfloat$func"};
        ok $func->(@arg), "$line";
    }
}

BEGIN { plan tests => $tests }

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:

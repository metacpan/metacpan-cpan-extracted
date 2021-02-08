use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

check_skip();

my $d = 't/data/work';
my $f = 't/data/orig/Copyright.pm';
my @files = (
    "$d/One.pm",
    "$d/Copyright.pm",
);

copy_module_files();

# bad params
{
    is eval{copyright_info('not-exist-dir_blah'); 1}, undef, "bad directory croaks ok";

}
# copyright_bump()
{
    my $i = copyright_info($d);

    is ref $i, 'HASH', "copyright_info() returns a hash ref ok";
    is keys %$i, scalar @files, "Proper info key count";

    for (0..$#files) {
        is exists $i->{$files[$_]}, 1, "$files[$_] exists in hash";
        is $i->{$files[$_]}, 1999, "$files[$_] has correct initial copyright (1999) ok";
    }

    my $u = copyright_bump($d);
    my ($year) = (localtime)[5];
    $year += 1900;

    for (0..$#files) {
        is exists $u->{$files[$_]}, 1, "$files[$_] exists in hash";
        is $u->{$files[$_]}, 2021, "$files[$_] has correct copyright ($year) ok";

        open my $fh, '<', $files[$_] or die "Can't open $files[$_]: $!";
        while (my $line = <$fh>) {
            next if $line !~ /^Copyright/;
            like $line, qr/^Copyright\s+$year\s+Steve\s+Bertrand/, "$files[$_] has $year as copyright line in file ok";
        }
    }
}

unlink_module_files();
verify_clean();

done_testing();


use warnings;
use strict;
use Test::More;

use Data::Dumper;
use File::Temp qw(tempdir);
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

my ($year) = (localtime)[5];
$year += 1900;

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
        is $u->{$files[$_]}, $year, "$files[$_] has correct copyright ($year) ok";

        open my $fh, '<', $files[$_] or die "Can't open $files[$_]: $!";
        while (my $line = <$fh>) {
            next if $line !~ /^Copyright/;
            like $line, qr/^Copyright\s+$year\s+Steve\s+Bertrand/, "$files[$_] has $year as copyright line in file ok";
        }
    }
}
# copyright_bump() - range and comma forms
{
    my $dir = tempdir(CLEANUP => 1);

    my %copyright = (
        "$dir/Dash.pm"   => 'Copyright 2016-2019 Steve Bertrand.',
        "$dir/Comma.pm"  => 'Copyright 2016,2019 Steve Bertrand.',
        "$dir/Single.pm" => 'Copyright 2016 Steve Bertrand.',
    );

    for my $file (sort keys %copyright) {
        open my $fh, '>', $file or die "Can't write $file: $!";
        print $fh "package Foo;\n\n=head1 LICENSE AND COPYRIGHT\n\n$copyright{$file}\n\n=cut\n";
        close $fh;
    }

    # Read side: a range reports the latter (most recent) year
    my $info = copyright_info($dir);

    is $info->{"$dir/Dash.pm"}, 2019, "dash range reports latter year ok";
    is $info->{"$dir/Comma.pm"}, 2019, "comma range reports latter year ok";
    is $info->{"$dir/Single.pm"}, 2016, "single year reports its year ok";

    # Write side: ranges keep the first year and bump the latter to the
    # current year, commas are normalized to a dash, single years replaced
    copyright_bump($dir);

    my %expect = (
        "$dir/Dash.pm"   => "Copyright 2016-$year Steve Bertrand.",
        "$dir/Comma.pm"  => "Copyright 2016-$year Steve Bertrand.",
        "$dir/Single.pm" => "Copyright $year Steve Bertrand.",
    );

    for my $file (sort keys %expect) {
        open my $fh, '<', $file or die "Can't read $file: $!";
        my ($got) = grep { /^Copyright/ } <$fh>;
        close $fh;
        chomp $got;
        is $got, $expect{$file}, "$file bumped to '$expect{$file}' ok";
    }
}

unlink_module_files();
verify_clean();

done_testing();


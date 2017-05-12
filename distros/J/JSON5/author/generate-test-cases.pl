use strict;
use warnings;
use utf8;

use Path::Tiny;
use List::UtilsBy qw/partition_by/;

MAIN: {
    my @base_dirs = grep $_->is_dir, path('json5-tests')->children();
    for my $base_dir (@base_dirs) {
        next if $base_dir->basename eq 'todo';

        my %files = partition_by { $_->basename =~ s/\..+$//r } $base_dir->children;
        for my $case (keys %files) {
            my $test_case = $base_dir->basename.' - '.$case;
            my $files = $files{$case};
            if (@$files == 1) {
                my $file = $files->[0];

                if ($file->basename =~ /\.json5$/) {
                    my $src  = $file->slurp_raw({ chomp => 1 });
                    my $dest = parse_valid_json5($src);
                    print <<EOD;
===
--- name: $test_case
--- input
$src
--- expected
$dest
EOD
                }
            }
        }
    }

    exit;
};

sub parse_valid_json5 {
    my $json5 = shift;

    local $ENV{JSON5_SRC} = $json5;
    chomp(my $out = `node -e 'console.log(JSON.stringify(require("json5").parse(process.env.JSON5_SRC)))'`);
    return $out;
}

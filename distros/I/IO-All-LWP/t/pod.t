use Test::More;
my @files = (glob("lib/*/*/*.pm"));

eval 'use Test::Pod';
if ($@) {
    plan skip_all => "You don't have Test::Pod installed";
} else {
    plan tests => scalar @files;
}

for my $file (@files) {
    pod_file_ok($file, "POD for '$file'");
}


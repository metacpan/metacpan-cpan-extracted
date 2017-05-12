use Test::More;
BEGIN
{
    eval "use Test::Pod::Coverage";
    if ($@) {
        plan(skip_all => "Test::Pod::Coverage is required to test POD coverage") if $@;
    }
}

plan(tests => 9);

foreach my $pkg qw(File::Extract File::Extract::Base File::Extract::Result) {
    pod_coverage_ok($pkg);
}

foreach my $pkg qw(HTML RTF MP3 PDF Excel Plain) {
    my $fqpkg = "File::Extract::${pkg}";
    pod_coverage_ok($fqpkg, { trustme => [ qw(extract mime_type) ] });
}
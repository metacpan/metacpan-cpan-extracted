use Test::More;
eval "use Test::Pod::Coverage 0.02";
plan skip_all => "Test::Pod::Coverage 0.02 required for testing POD
coverage" if $@;

plan tests => 5;

my $params = { trustme => [qr/^(?:new|parse|compile)$/] };

pod_coverage_ok('Mail::SRS');
pod_coverage_ok('Mail::SRS::Guarded', $params);
pod_coverage_ok('Mail::SRS::DB', $params);
pod_coverage_ok('Mail::SRS::Reversible', $params);
pod_coverage_ok('Mail::SRS::Shortcut', $params);

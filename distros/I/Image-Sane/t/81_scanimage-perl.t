use warnings;
use strict;
use Test::More tests => 7;

#########################

my $scanimage_perl =
  'PERL5LIB="blib:blib/arch:lib:\$PERL5LIB" perl examples/scanimage-perl';

#########################

my @tests = (
    '--device=test > out.pnm; identify out.pnm; rm out.pnm',
    '--device=test --test 2>&1',
    '--device=test --mode Color --test 2>&1',
    '--device=test --depth 1 --test 2>&1',
'--device=test --batch-count=2 2>&1; identify out1.pnm out2.pnm; rm out*.pnm',
'--verbose --device=test --batch-count=2 2>&1; identify out1.pnm out2.pnm; rm out*.pnm',
'--verbose --device=test --source="Automatic Document Feeder" --batch 2>&1; identify out*.pnm; rm out*.pnm',
);

for my $test (@tests) {
    my $output = `$scanimage_perl $test`;
    $output =~ s/scanimage-perl/scanimage/g;
    my $example = `scanimage $test`;
    is_deeply( $output, $example, $test );
}

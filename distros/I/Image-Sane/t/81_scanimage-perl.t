use warnings;
use strict;
use English;
use Test::More;

#########################

if ( system("which scanimage > /dev/null 2> /dev/null") == 0 ) {
    plan tests => 6;
}
else {
    plan skip_all => 'scanimage not installed';
    exit;
}

my $scanimage_perl =
    'PERL5LIB="blib:blib/arch:lib:\$PERL5LIB" '
  . "$EXECUTABLE_NAME examples/scanimage-perl";
my $identify = "; identify -format '%m %G %g %z-bit %r' out*.pnm; rm out*.pnm";

#########################

my @tests = (
    '--device=test > out.pnm' . $identify,
    '--device=test --test 2>&1',

    # Segfaults. Doesn't seem to be caused by Sane.xs
    # '--device=test --mode Color --test 2>&1',
    '--device=test --depth 1 --test 2>&1',
    '--device=test --batch-count=2 2>&1' . $identify,
    '--verbose --device=test --batch-count=2 2>&1' . $identify,
    '--verbose --device=test --source="Automatic Document Feeder" --batch 2>&1'
      . $identify,
);

for my $test (@tests) {
    my $output = `$scanimage_perl $test`;
    $output =~ s/scanimage-perl/scanimage/g;
    my $example = `scanimage $test`;
    is_deeply( $output, $example, $test );
}

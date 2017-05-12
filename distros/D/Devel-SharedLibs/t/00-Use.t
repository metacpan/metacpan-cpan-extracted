use FindBin::libs;

use Test::More;

my $madness = 'Devel::SharedLibs';

use_ok $madness;
ok $madness->can( 'import' );

done_testing
__END__

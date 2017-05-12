use Test::More;
BEGIN
{
    if ($ENV{TEST_KWALITEE}) {
        eval { require Test::Kwalitee; Test::Kwalitee->import() };
        plan( skip_all => 'Install Test::Kwalitee to enable these tests' ) if $@;
    } else {
        plan( skip_all => 'Enable TEST_KWALITEE to enable these tests' );
    }
}

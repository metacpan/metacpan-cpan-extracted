#!perl
BEGIN
{
    use lib './lib';
    use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		plan(skip_all => 'These tests are for author or release candidate testing');
	}
};

eval "use Test::Prereq 2.003";
plan( skip_all => "Test::Prereq 2.003 required for testing prerequisites" ) if( $@ );
prereq_ok();

__END__

#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode' ) || BAIL_OUT( 'Unable to load Locale::Unicode' );
    use_ok( 'DateTime::Locale' ) || BAIL_OUT( "Cannot load DateTime::Locale" );
};

use strict;
use warnings;

my $loc = eval
{
    # no warnings 'Locale::Unicode';
    local $SIG{__DIE__} = sub{};
    Locale::Unicode->new( 'x', fatal => 1 );
};
ok( !defined( $loc ), "Locale::Unicode returned undef upon bad locale" );
ok( $@, "\$\@ is set." );
isa_ok( $@ => 'Locale::Unicode::Exception', '$@ is a Locale::Unicode::Exception object' );

done_testing();

__END__


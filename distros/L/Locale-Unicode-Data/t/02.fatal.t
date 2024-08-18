#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;

my $str = eval
{
    # no warnings 'Locale::Unicode::Data';
    local $SIG{__DIE__} = sub{};
    my $cldr = Locale::Unicode::Data->new( fatal => 1 );
    $cldr->timezone_names( timezone => 'Asia/Tokyo', locale => 'en' );
};
ok( !defined( $str ), "Locale::Unicode::Data->timezone_names returned undef upon missing argument" );
ok( $@, "\$\@ is set." );
isa_ok( $@ => 'Locale::Unicode::Data::Exception', '$@ is a Locale::Unicode::Data::Exception object' );

done_testing();

__END__


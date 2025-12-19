#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( 'Cannot load JSON::Schema::Validate' );
};

my $have_idn = eval{ require Net::IDN::Encode; 1 } ? 1 : 0;

SKIP:
{
    if( !$have_idn )
    {
        skip( 'Net::IDN::Encode not installed; skipping IDN format tests', 4 );
    }

    my $schema_host = 
    {
        type   => 'string',
        format => 'idn-hostname',
    };
    
    my $schema_mail = 
    {
        type   => 'string',
        format => 'idn-email',
    };
    
    my $js = JSON::Schema::Validate->new( $schema_host )->register_builtin_formats;
    my $jm = JSON::Schema::Validate->new( $schema_mail )->register_builtin_formats;
    
    # Valid IDN hostname: bücher.example → xn--bcher-kva.example
    ok( $js->validate( "bücher.example" ), 'idn-hostname: bücher.example is valid' ) or diag( $js->error );
    
    # Invalid: label starts with hyphen
    ok( !$js->validate( "-bücher.example" ), 'idn-hostname: leading hyphen is invalid' );
    
    # Valid IDN email with ASCII local-part
    ok( $jm->validate( q{info@bücher.example} ), 'idn-email: info@bücher.example is valid' ) or diag( $jm->error );
    
    # Invalid IDN email (bad domain label)
    ok( !$jm->validate( q{info@-bücher.example} ), 'idn-email: bad domain label rejected' );
};

done_testing();

__END__

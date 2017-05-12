use strict;
use warnings;

use Test::More;

BEGIN
{
    unless ( -f '/etc/passwd' )
    {
        plan skip_all => 'This test requires that /etc/passwd exist.';
    }
}

plan tests => 1;

use HTML::Mason::Resolver::File;


my $resolver = HTML::Mason::Resolver::File->new();

my $source = $resolver->get_info( '/../../../../../../etc/passwd', 'MAIN', '/var/cache' );

ok( ! $source, 'Cannot get at /etc/passwd with bogus comp path' );


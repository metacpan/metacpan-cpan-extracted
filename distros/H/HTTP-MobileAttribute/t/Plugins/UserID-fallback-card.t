use strict;
use warnings;
use Test::Base;

use HTTP::MobileAttribute plugins => [
    'Core',
    +{
        module => 'UserID',
        config => { fallback => 1, fallback_with_cardid => 1 },
    }
];

plan tests => 1*blocks;

filters {
    input    => [qw/yaml get_display/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub get_display {
    my $env = shift;
    local *ENV = $env;

    my $hma   = HTTP::MobileAttribute->new;
    my $param;
    if ($env->{param}) {
        $param = bless { %{ $env->{param} } }, __PACKAGE__;
    }
    +{
        id => $hma->user_id($param) || '',
    };
}


sub param { # for docomo uid
    my($self, $name) = @_;
    $self->{$name};
}

__END__

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
HTTP_X_DCMGUID: 0000000
--- expected
id: 0000000

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
HTTP_X_DCMGUID: aaaaaaa
--- expected
id: aaaaaaa

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
HTTP_X_DCMGUID: aaaaaaa
HTTP_X_DOCOMO_UID: 0123456789ab
--- expected
id: 0123456789ab

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
HTTP_X_DCMGUID: aaaaaaa
param:
  uid: 0123456789ab
--- expected
id: 0123456789ab

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
--- expected
id: 0123456789abcde,01234567890123456789

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/P503i/c10/serNMABH200331
--- expected
id: NMABH200331

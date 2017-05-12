package TestSetup;

use Test::Mock::Cmd 'qr' => {
    'git ls-remote --get-url' => sub { return 'git@github.com:abc/xzy.git' },
    'git symbolic-ref --short HEAD' => sub { return 'masterxx'; }
};

1;

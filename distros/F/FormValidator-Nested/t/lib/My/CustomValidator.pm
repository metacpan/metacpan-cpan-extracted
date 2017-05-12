package My::CustomValidator;
use strict;
use warnings;
use utf8;

our $MESSAGES = {
    __PACKAGE__ . '#mycustom' => '${name}はhogeと入力しないでください',
};

sub mycustom {
    my ( $value, $options, $req ) = @_;

    if ( $value eq 'hoge' ) {
        return 0;
    }
    return 1;
}

1;

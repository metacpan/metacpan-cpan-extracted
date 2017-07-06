package # hidden from PAUSE indexer
Var::Your;
our $VERSION = '0.000001';

use 5.012; use warnings; use autodie;
use Carp;
use Data::Dump 'dump';

use Keyword::Declare;

sub import {

    keyword your (ScalarVar $var) {{{
        my <{$var}>; Var::Your::setup(<{$var}>, '<{$var}>')
    }}}
}

sub setup : lvalue {
    my (undef, $name) = @_;

    use Variable::Magic qw< wizard cast >;
    cast $_[0], wizard set => sub { carp "$name = ", dump ${$_[0]} };

    $_[0];
}



1; # Magic true value required at end of module

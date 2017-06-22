package Perl6::SameWith;

use 5.020; use warnings; use autodie;

our $VERSION = '0.000001';

use Keyword::Declare;

sub import {
    keyword samewith (Expr $args) {{{
        @_ = (<{$args}>);
        goto __SUB__;
    }}}
}


1; # Magic true value required at end of module
__END__

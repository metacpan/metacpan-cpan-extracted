#line 1
package methods;
use 5.008;
our $VERSION = '0.02';

use true;
use namespace::autoclean;
use Method::Signatures::Simple;
our @ISA = 'Method::Signatures::Simple';

method import {
    true->import;
    namespace::autoclean->import( -cleanee => scalar(caller) );

    unshift @_, 'Method::Signatures::Simple';
    goto &Method::Signatures::Simple::import;
}

__END__

=encoding utf8

#line 72

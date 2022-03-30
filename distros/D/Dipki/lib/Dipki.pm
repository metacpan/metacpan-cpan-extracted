package Dipki;
use 5.006000;
use strict;
use warnings;
use Exporter qw(import);
#TODO: remove this in final distribution
#BEGIN { unshift @INC, '.'; }
require Dipki::Err;
require Dipki::Gen;
require Dipki::Asn1;
require Dipki::Cipher;
require Dipki::Rng;
require Dipki::X509;
require Dipki::Cnv;
require Dipki::Sig;
require Dipki::Rsa;
require Dipki::Ecc;
require Dipki::Compr;
require Dipki::Hash;
require Dipki::Hmac;


our $VERSION = '0.01';
1;
__END__

=head1 NAME

Dipki - Perl extension for CryptoSys PKI

=head1 SYNOPSIS

  use Dipki;
  blah blah blah

=head1 DESCRIPTION

An interface to the most common functions in the CryptoSys PKI library.


=head1 SEE ALSO

Requires CryptoSys PKI to be installed on your system, available
from L<https://www.cryptosys.net/pki/>. Windows only.

=head1 AUTHOR

David Ireland, L<https://www.cryptosys.net/contact/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 David Ireland, DI Management Services Pty Limited,
L<https://www.di-mgt.com.au> L<https://www.cryptosys.net>.
The code in this module is licensed under the terms of the MIT license.  
For a copy, see L<http://opensource.org/licenses/MIT>

=cut

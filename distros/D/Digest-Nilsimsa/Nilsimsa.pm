package Digest::Nilsimsa;

require DynaLoader;

$VERSION = 0.06;
@ISA = qw/DynaLoader/;

bootstrap Digest::Nilsimsa $VERSION;

=head1 NAME

Digest::Nilsimsa - Perl version of Nilsimsa code

=head1 SYNOPSIS

 use Digest::Nilsimsa;

 my $nilsimsa = Digest::Nilsimsa;

 my $digest = $nilsimsa->text2digest($text);


=head1 DESCRIPTION

A nilsimsa signature is a statistic of n-gram occurance in a piece of
text. It is a 256 bit value usually represented in hex. This module is a
wrapper around nilsimsa implementation in C by cmeclax.

=head1 METHODS

=over 4

=cut

=item $nilsimsa->text2digest($text);

Pass in any text, any size, and get back a digest string composed 64
hex chars.

=back

=head1 SEE ALSO

http://ixazon.dynip.com/~cmeclax/nilsimsa.html

=head1 AUTHOR

Chad Norwood <chad@455scott.com>, cmeclax 
 
=cut

1;


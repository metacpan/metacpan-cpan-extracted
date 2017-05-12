package Egg::Plugin::Filter::Plugin::Japanese::Shift_JIS;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Shift_JIS.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Plugin::Filter::Plugin::Japanese /;
use Jcode;

our $VERSION= '3.00';

$Egg::Plugin::Filter::Plugin::Japanese::Zspace  = '\x81\x40';
$Egg::Plugin::Filter::Plugin::Japanese::RZspace = Jcode->new('@', 'euc')->sjis;

1;

__END__

=head1 NAME

Egg::Plugin::Filter::Plugin::Japanese::Shift_JIS - The filter for the Shift_JIS character is set up.

=head1 DESCRIPTION

It sets it up so that the Shift_JIS character is treated with L<Egg::Plugin::Filter::Plugin::Japanese>.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::Filter::Plugin::Japanese>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


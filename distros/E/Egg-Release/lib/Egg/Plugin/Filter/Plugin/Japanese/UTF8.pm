package Egg::Plugin::Filter::Plugin::Japanese::UTF8;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UTF8.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use utf8;
use base qw/ Egg::Plugin::Filter::Plugin::Japanese /;

our $VERSION= '3.00';

$Egg::Plugin::Filter::Plugin::Japanese::Zspace  = '　';
$Egg::Plugin::Filter::Plugin::Japanese::RZspace = '　';

1;

__END__

=head1 NAME

Egg::Plugin::Filter::Plugin::Japanese::UTF8 - The filter for the UTF8 character is set up.

=head1 DESCRIPTION

It sets it up so that the UTF8 character is treated with L<Egg::Plugin::Filter::Plugin::Japanese>.

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


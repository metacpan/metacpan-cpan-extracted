package Geo::Direction::Name::Spec::Dizhi;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use base qw(Geo::Direction::Name::Spec);

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

sub devide_num { 24 }

sub allowed_dev { qw(12 24) }

sub default_dev { 12 }

sub default_locale { "zh_CN" }


1;
__END__

=encoding utf-8

=head1 NAME

Geo::Direction::Name::Spec::Bagua - Used by Geo::Direction::Name::Spec::Chinese: Real specification class of Dizhi


=head1 OVERRIDE / INTERNAL METHOD

=over 4

=item * devide_num

=item * allowed_dev

=item * default_dev

=item * default_locale

=back


=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
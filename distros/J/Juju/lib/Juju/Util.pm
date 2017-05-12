package Juju::Util;
BEGIN {
  $Juju::Util::AUTHORITY = 'cpan:ADAMJS';
}
$Juju::Util::VERSION = '2.002';
# ABSTRACT: helper methods for Juju


use Moose;
use HTTP::Tiny;
use JSON::PP;
use Function::Parameters;
use namespace::autoclean;


method query_cs(Str $charm, Str $series = "trusty") {
    my $cs_url = 'https://manage.jujucharms.com/api/3/charm';

    my $composed_url = sprintf("%s/%s/%s", $cs_url, $series, $charm);
    my $res = HTTP::Tiny->new->get($composed_url);
    die "Unable to query charm store: ".$res->{reason} unless $res->{success};
    return decode_json($res->{content});
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juju::Util - helper methods for Juju

=head1 VERSION

version 2.002

=head1 SYNOPSIS

  use Juju::Util;
  my $util = Juju::Util->new;
  my $charm = $util->query_cs('wordpress', 'precise');

=head1 METHODS

=head2 query_cs

helper for querying charm store for charm details

B<Params>

=over 4

=item *

C<charm>

name of charm to query

=item *

C<series>

(optional) series to limit to (defaults: trusty)

=back

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Adam Stokes.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Juju|Juju>

=back

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

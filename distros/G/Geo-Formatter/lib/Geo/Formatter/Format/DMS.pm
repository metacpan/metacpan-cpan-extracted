package Geo::Formatter::Format::DMS;

use strict;
use warnings;
use Carp;
use Geo::Formatter::CalcurateDMS;
use base qw(Geo::Formatter::FormatBase::Double);

use version; our $VERSION = qv('0.0.1');

sub encode {
    my ($class,$lat,$lng,$opt) = @_;

    $opt ||= {};

    my $under_decimal = defined($opt->{under_decimal}) ? $opt->{under_decimal} : 3;
    my $sign          = $opt->{sign}          || 0;
    my $zerofill      = $opt->{zerofill}      || 0;
    my $devider       = defined($opt->{devider})       ? $opt->{devider}       : ".";

    croak "Cannot use number character as devider" if ($devider =~ /\d/);
    $devider         =~ s/%/%%/g;

    # %+d.%02d.%06.3f
    my $form = sprintf(
        "%%%sd%s%%%sd%s%%%s.%df",
        $sign ? "+" : "", 
        $devider,
        $zerofill ? "02" : "",
        $devider,
        $zerofill ? "0" . ($under_decimal + 3) : "",
        $under_decimal
    );

    map {
        my ($minus,$d,$m,$s) = __degree2dms($_);

        $d *= -1 if ($minus);
        sprintf($form,$d,$m,$s); 
    } ($lat,$lng);
}

sub decode {
    my ($class,$lat,$lng,$opt) = @_;

    $opt ||= {};

    my $devider       = $opt->{devider}       || ".";

    croak "Cannot use number character as devider" if ($devider =~ /\d/);
    $devider         =~ s/([\.\^\$\[\]\*\+\?\|\(\)\\\/])/\\$1/g;

    # ([\+\-]?)(\d+)\.(\d+)\.(\d+(?:\.\d*))
    my $form = qr(([\+\-]?)(\d+)$devider(\d+)$devider(\d+(?:\.\d*)?));

    map {
        my ($minus,$d,$m,$s) = /$form/ or croak "Arguments are not DMS format";
        $minus = $minus && $minus eq "-" ? 1 : 0;

        __dms2degree($minus,$d,$m,$s);
    } ($lat,$lng);
}

1;

__END__

=head1 NAME

Geo::Formatter::Format::DMS - Add dms format to Geo::Formatter


=head1 DESCRIPTION

This module add dms format to Geo::Formatter.


=head1 METHOD

=over

=item * encode

=item * decode

=back


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


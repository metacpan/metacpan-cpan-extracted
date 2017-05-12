package HTML::QRCode;

use strict;
use warnings;
our $VERSION = '0.01';

use Text::QRCode;
use Carp;

sub new {
    my ( $class, %args ) = @_;

    bless {
        text_qrcode => Text::QRCode->new,
        white => 'white',
        black => 'black',
        %args
    }, $class;
}

sub plot {
    my ( $self, $text ) = @_;
    croak 'Not enough arguments for plot()' unless $text;

    my $arref = $self->{text_qrcode}->plot($text);

    my ($white, $black) = ($self->{white}, $self->{black});
    my $w = "<td style=\"border:0;margin:0;padding:0;width:3px;height:3px;background-color: $white;\">";
    my $b = "<td style=\"border:0;margin:0;padding:0;width:3px;height:3px;background-color: $black;\">";

    my $html
        .= '<table style="margin:0;padding:0;border-width:0;border-spacing:0;">';
    $html
        .= '<tr style="border:0;margin:0;padding:0;">'
        . join( '', map { $_ eq '*' ? $b : $w } @$_ ) . '</tr>'
        for (@$arref);
    $html .= '</table>';

    return $html;
}

1;
__END__

=encoding utf8

=head1 NAME

HTML::QRCode - Generate HTML based QR Code

=head1 SYNOPSIS

  #!/usr/bin/env perl

  use HTML::QRCode;
  use CGI

  my $q = CGI->new;
  my $text = $q->param('text') || 'http://example.com/';
  my $qrcode = HTML::QRCode->new->plot($text);
  print $q->header;
  print <<"HTML";
  <html>
  <head></head>
  <body>
  $qrcode
  </body>
  </html>
  HTML

=head1 DESCRIPTION

HTML::QRCode is HTML based QRCode generator, using Text::QRCode

=head1 METHODS

=over 4

=item new

    $qrcode = HTML::QRCode->new(%params);

The C<new()> constructor method instantiates a new Term::QRCode object.

=item plot($text)

    $arrayref = $qrcode->plot("blah blah");

Return HTML based QR Code.

=back

=head1 AUTHOR

Hideo Kimura E<lt>hide <at> hide-k.netE<gt>

Yoshiki Kurihara

Yappo

nipotan

=head1 SEE ALSO

C<Text::QRCode>, C<Imager::QRCode>, C<Term::QRCode>, C<HTML::QRCode>, C<http://www.qrcode.com/>, C<http://megaui.net/fukuchi/works/qrencode/index.en.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

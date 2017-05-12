package HTML::ReplacePictogramMobileJp;
use strict;
use warnings;
our $VERSION = '0.07';
use Params::Validate ':all';
use HTML::ReplacePictogramMobileJp::DoCoMo;
use HTML::ReplacePictogramMobileJp::EZweb;
use HTML::ReplacePictogramMobileJp::Vodafone;
use HTML::ReplacePictogramMobileJp::AirHPhone;

my $long_name_for = +{
    I => 'DoCoMo',
    E => 'EZweb',
    V => 'Vodafone',
    H => 'AirHPhone',
};

sub replace {
    my $class = shift;
    validate(
        @_,
        +{
            carrier  => qr{^[IEVH]$},
            charset  => qr{^(?:utf-?8|sjis)$}i,
            callback => +{ type => CODEREF },
            html     => +{ type => SCALAR },
        }
    );
    my %args = @_;

    my $klass = join "::", __PACKAGE__, $long_name_for->{$args{carrier}};
    my $method = $args{charset} =~ /^utf-?8$/i ? 'utf8' : 'sjis';
    $klass->$method(html => $args{html}, callback => $args{callback});
}

1;
__END__

=encoding utf8

=for stopwords au

=head1 NAME

HTML::ReplacePictogramMobileJp - HTML に含まれる絵文字を置換する

=head1 SYNOPSIS

    use HTML::ReplacePictogramMobileJp;

    HTML::ReplacePictogramMobileJp->replace(
        carrier  => 'I',
        html     => "foo",
        charset  => 'sjis', # or utf8
        callback => sub {
            my ( $unicode, $carrier ) = @_;
            # なにかする
        },
    );

=head1 DESCRIPTION

HTML::ReplacePictogramMobileJp は HTML に含まれる絵文字を置換するライブラリです。
どのように置換するかは、コールバック関数で指定します。

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 THANKS TO

Kazuhiro Osawa

=head1 SEE ALSO

L<Encode::JP::Mobile>, L<Moxy>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

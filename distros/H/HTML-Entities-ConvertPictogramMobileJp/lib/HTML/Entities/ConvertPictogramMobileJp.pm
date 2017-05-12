package HTML::Entities::ConvertPictogramMobileJp;
use strict;
use warnings;
our $VERSION = '0.09';
use Encode;
use Encode::JP::Mobile;
use Params::Validate;
use HTML::Entities::ConvertPictogramMobileJp::KDDITABLE;
use File::ShareDir qw/dist_file/;
use base 'Exporter';
our @EXPORT = qw/convert_pictogram_entities/;
use 5.008001;

sub convert_pictogram_entities {
    validate(@_ => +{
        mobile_agent => +{
            callbacks => {
                'HTTP::MobileAgent or HTTP::MobileAttribute' => sub {
                    my $pkg = ref $_[0];
                    $pkg && (
                        $_[0]->isa('HTTP::MobileAgent') ||
                        $_[0]->isa('HTTP::MobileAttribute') ||
                        $pkg =~ /^HTTP::MobileAttribute::Agent::/
                    )
                },
            },
        },
        html  => 1,
    });
    my %args = @_;

    my $content = $args{html};
    my $agent = $args{mobile_agent};
    $content =~ s{(&\#x([A-Z0-9]+);)}{
        if ($agent->is_softbank) {
            _convert_unicode('softbank', $2)
        } elsif ($agent->is_ezweb) {
            join '', map { _ezuni2tag($_) }
              map { unpack 'U*', $_ }
              split //, decode "x-utf8-kddi",
              encode( "x-utf8-kddi", chr( hex $2 ) );
        } elsif ($agent->is_docomo) {
            if ($agent->is_foma) {
                _convert_unicode('docomo', $2);
            } else {
                _convert_sjis('docomo', $2);
            }
        } elsif ($agent->is_airh_phone) {
            _convert_sjis('docomo', $2);
        } else {
            $1;
        }
    }ge;
    $content;
}

sub _ezuni2tag {
    my $unicode = shift;
    if (my $number = _ezuni2number($unicode)) {
        sprintf '<img localsrc="%d" />', $number;
    } else {
        sprintf '&#x%X;', $unicode;
    }
}

sub _ezuni2number {
    my $unicode = shift;
    $HTML::Entities::ConvertPictogramMobileJp::KDDITABLE::TABLE->{$unicode};
}

sub _convert_unicode {
    my ($carrier, $unihex) = @_;
    join '', map { sprintf '&#x%X;', unpack 'U*', $_ } split //,
      decode "x-utf8-$carrier", encode( "x-utf8-$carrier", chr( hex $unihex ) );
}

sub _convert_sjis {
    my ($carrier, $unihex) = @_;

    sprintf '&#x%s;', uc unpack 'H*', encode("x-sjis-$carrier", chr(hex $unihex));
}

1;
__END__

=encoding utf8

=for stopwords utf8 pictogram DoCoMo KDDI SJIS SoftBank Unicode KDDI-Auto au

=head1 NAME

HTML::Entities::ConvertPictogramMobileJp - convert pictogram entities

=head1 SYNOPSIS

    use HTTP::MobileAgent;
    use HTML::Entities::ConvertPictogramMobileJp;
    convert_pictogram_entities(
        mobile_agent => HTTP::MobileAgent->new,
        html  => "&#xE001",
    );

=head1 DESCRIPTION

HTML::Entities::ConvertPictogramMobileJp is Japanese mobile phone's pictogram converter.

HTML 中にふくまれる絵文字の Unicode 16進数値文字参照の DoCoMo 絵文字を、SoftBank/KDDI の絵文字に変換します。

DoCoMo Mova/AirHPhone の場合には、 Unicode 数値文字参照ではなく SJIS の数値文字参照に変換して出力
することに注意してください。これは、該当機種が、 SJIS の数値文字参照でないと表示できないためです。

au の一部端末(W41CA, W32H など) では Unicode 数値文字参照が表示できないため、<img localsrc="" /> 形式を採用しています。

=head1 METHODS

=over 4

=item convert_pictogram_entities

絵文字変換します。

=back

=head1 CODE COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...nvertPictogramMobileJp.pm  100.0  100.0    n/a  100.0  100.0   97.3  100.0
    ...gramMobileJp/KDDITABLE.pm  100.0    n/a    n/a  100.0    n/a    2.7  100.0
    Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Encode::JP::Mobile>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

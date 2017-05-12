package HTML::ReplacePictogramMobileJp::Base;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/unicode_property unicode_hex_cref filter img_localsrc/;
use Params::Validate ':all';
use Encode;
use Encode::JP::Mobile ':props';
use File::ShareDir 'dist_file';

my $property_for = +{
    E => 'InKDDIPictograms',
    I => 'InDoCoMoPictograms',
    V => 'InSoftBankPictograms',
};
sub unicode_property {
    my $carrier = shift;
    $_ =~ s/(\p{$property_for->{$carrier}})/callback(ord $1, $carrier)/ge;
}

sub unicode_hex_cref {
    my $carrier = shift;
    $_ =~ s/&#x([A-F0-9]{4});/callback(hex $1, $carrier)/ge;
}

sub _kddi_number2unicode_auto {
    my $number = shift;

    my $fname =
      File::ShareDir::dist_file( 'Encode-JP-Mobile', 'kddi-table.pl' );
    my $dat = do $fname;
    for my $row (@$dat) {
        if ( $row->{number} == $number ) {
            return hex $row->{unicode_auto};
        }
    }
    return;    # invalid number
}

sub img_localsrc {
    $_ =~ s{<img[^<>]+localsrc=["'](\d+)[^<>]+>}{
        callback(_kddi_number2unicode_auto($1), 'E');
    }ge;
}

sub filter {
    my ($charset, $decode_by, $code) = @_;
    my $pkg = caller(0);
    no strict 'refs';
    *{"$pkg\::$charset"} = sub {
        my $class = shift;
        validate(
            @_,
            +{
                callback => { type => CODEREF },
                html     => { type => SCALAR },
            }
        );
        my %args = @_;

        local $_ = decode($decode_by, $args{html}, Encode::FB_XMLCREF);
        local *HTML::ReplacePictogramMobileJp::Base::callback = $args{callback};
        local *{"$pkg\::callback"} = $args{callback};

        $code->();

        $_ = encode($decode_by, $_);

        $_;
    };
}

1;

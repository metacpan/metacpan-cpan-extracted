package FormValidator::Simple::Plugin::Japanese;
use strict;
use base qw/
    FormValidator::Simple::Plugin::Number::Phone::JP
/;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;
use Unicode::RecursiveDowngrade;
use Mail::Address::MobileJp;
use Jcode;

our $VERSION = '0.05';

# plugin specific method
sub __japanese_check_charset {
    my ($self, $charset) = @_;
    my @charsets = (
        [qw/UTF-8     utf8     utf8/],
        [qw/EUC-JP    euc      euc /],
        [qw/Shift_JIS shiftjis sjis/],
    );
    foreach my $set ( @charsets ) {
        foreach my $name ( @$set ) {
            if( $charset eq $name ) {
                return $set->[2];
            }
        }
    }
    FormValidator::Simple::Exception->throw(
        qq/wrong charset "$charset"./
    );
}

# plugin specific method
sub __japanese_encode2euc {
    my ($self, $value) = @_;
    my $charset = $self->options->{charset} || 'utf8';
    $charset    = $self->__japanese_check_charset($charset);

    my $rd = Unicode::RecursiveDowngrade->new;
    $rd->filter( sub { Jcode->new($value, $charset)->euc } );
    return $rd->downgrade($value);
}

# plugin specific method
sub __japanese_delete_sp {
    my ($self, $value) = @_;
    $value          = $self->__japanese_encode2euc($value);
    $value          =~ s/ //g;
    my $ascii       = '[\x00-\x7F]';
    my $two_bytes   = '[\x8E\xA1-\xFE][\xA1-\xFE]';
    my $three_bytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';
    $value =~ s/\G((?:$ascii|$two_bytes|$three_bytes)*?)(?:\xA1\xA1)/$1/g;
    return $value;
}

sub HIRAGANA {
    my ($self, $params, $args) = @_;
    my $value = $self->__japanese_delete_sp( $params->[0] );
    return $value =~ /^(?:\xA4[\x00-\xFF]|\xA1\xBC)+$/ ? TRUE : FALSE;
}

sub KATAKANA {
    my ($self, $params, $args) = @_;
    my $value = $self->__japanese_delete_sp( $params->[0] );
    return $value =~ /^(?:\xA5[\x00-\xFF]|\xA1\xBC)+$/ ? TRUE : FALSE;
}

sub JLENGTH {
    my ($self, $params, $args) = @_;
    my $min = $args->[0] || 0;
    my $max = $args->[1] || 0;
    my $value = $self->__japanese_encode2euc( $params->[0] );
    my $length = Jcode->new($value, 'euc')->jlength;
    $min += 0; $max += 0; $max ||= $min;
    return ($min <= $length and $length <= $max) ? TRUE : FALSE;
}

sub ZIP_JP {
    my ($self, $params, $args) = @_;
    if ( scalar(@$params) == 1 ) {
        return $params->[0] =~ /^\d{3}\-{0,1}\d{4}$/ ? TRUE : FALSE;
    }
    elsif ( scalar(@$params) == 2 ) {
        return ( $params->[0] =~ /^\d{3}$/ && $params->[1] =~ /^\d{4}$/ ) ? TRUE : FALSE;
    }
    else {
        FormValidator::Simple::Exception->throw(
            qq/wrong format for 'ZIP_JP'./
        );
    }
}

sub EMAIL_MOBILE_JP {
    my ($self, $params, $args) = @_;
    if ( @$args == 0 ) {
        return Mail::Address::MobileJp::is_mobile_jp( $params->[0] )
            ? TRUE : FALSE;
    }
    else {
        my $ok = 0;
        foreach my $career ( @$args ) {
            if ( lc($career) eq 'imode' ) {
                if ( Mail::Address::MobileJp::is_imode( $params->[0] ) ) {
                    $ok = 1;
                    last;
                }
            }
            elsif ( lc($career) eq 'ezweb' ) {
                if ( Mail::Address::MobileJp::is_ezweb( $params->[0] ) ) {
                    $ok = 1;
                    last;
                }
            }
            elsif ( lc($career) eq 'vodafone' ) {
                if ( Mail::Address::MobileJp::is_vodafone( $params->[0] ) ) {
                    $ok = 1;
                    last;
                }
            }
            elsif ( lc($career) eq 'softbank' ) {
                if ( Mail::Address::MobileJp::is_softbank( $params->[0] ) ) {
                    $ok = 1;
                    last;
                }
            }
            else {
                FormValidator::Simple::Exception->throw(
                    qq/Unknown type of mail address./
                );
            }
        }
        return $ok ? TRUE : FALSE;
    }
}

1;
__END__

=head1 NAME

FormValidator::Simple::Plugin::Japanese - Japanese specific validation.

=head1 SYNOPSIS

    use FormValidator::Simple qw/Japanese/;

    my $result = FormValidator::Simple->check( $req => [
        zip       => [ 'NOT_BLANK', 'ZIP_JP' ],
        name      => [ 'NOT_BLANK', [ 'JLENGTH', 5 10 ] ],
        kana_name => [ 'NOT_BLANK', 'KATAKANA', [ 'JLENGTH', 5, 10 ] ],
        email     => [ [ 'EMAIL_MOBILE_JP', 'IMODE' ] ],
    ] );

=head1 DESCRIPTION

This modules adds some Japanese specific validation commands to L<FormValidator::Simple>.
Most of validation code is borrowed from Sledge::Plugin::Validator::japanese.

( Sledge is a MVC web application framework: http://sl.edge.jp/ [Japanese] )

=head1 VALIDATION COMMANDS

=over 4

=item HIRAGANA

check if the data is Hiragana or not.

=item KATAKANA

check if the data is Katakana or not.

=item JLENGTH

check the length of the data (behaves like 'LENGTH').
but this counts multibyte character as 1.

=item ZIP_JP

check Japanese zip code.
[ seven digit ( and - ) for example 1111111, 111-1111 ]

    my $result = FormValidator::Simple->check( $req => [
        zip => [ 'ZIP_JP' ],
    ] );

or you can validate with two params,
[ one is three digit, another is four. ]

    my $result = FormValidator::Simple->check( $req => [
        { zip => [qw/zip1 zip2/] } => [ 'ZIP_JP' ]
    ] );

=item EMAIL_MOBILE_JP

check with L<Mail::Address::MobileJp>.

    my $result = FormValidator::Simple->check( $req => [
        email => [ 'EMAIL_MOBILE_JP' ]
    ] );

you can also check if it's 'IMODE', 'EZWEB', 'VODAFONE', or 'SOFTBANK'.

    my $result = FormValidator::Simple->check( $req => [
        email => [ ['EMAIL_MOBILE_JP', 'VODAFONE' ] ]
    ] );

=back

=head1 LOADING OTHER PLUGINS

This module loads other plugins that has essential japanese specific validation.

See follow listed modules.

L<FormValidator::Simple::Plugin::Number::Phone::JP>,

=head1 SEE ALSO

L<FormValidator::Simple>

L<Mail::Address::MobileJp>

L<Jcode>

L<Unicode::RecursiveDowngrade>

L<FormValidator::Simple::Plugin::Number::Phone::JP>

http://sl.edge.jp/ (Japanese)

http://sourceforge.jp/projects/sledge

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


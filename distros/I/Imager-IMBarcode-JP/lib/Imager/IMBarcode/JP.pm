package Imager::IMBarcode::JP;

use strict;
use warnings;
use utf8;
use Imager;
use Mouse;

our $VERSION = '0.01';

has zipcode => (
    is      => 'rw',
    isa     => 'Int',
    default => '00000000',
);

has address => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has _pos => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has _base => (
    is         => 'ro',
    isa        => 'Imager',
    lazy_build => 1,
);

has _char_code => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my %code = (
            STC => +{
                bar   => 13,
            },
            SPC => +{
                bar   => 31,
            },
            1   => +{
                check => 1,
                bar   => 114,
            },
            2   => +{
                check => 2,
                bar   => 132,
            },
            3   => +{
                check => 3,
                bar   => 312,
            },
            4   => +{
                check => 4,
                bar   => 123,
            },
            5   => +{
                check => 5,
                bar   => 141,
            },
            6   => +{
                check => 6,
                bar   => 321,
            },
            7   => +{
                check => 7,
                bar   => 213,
            },
            8   => +{
                check => 8,
                bar   => 231,
            },
            9   => +{
                check => 9,
                bar   => 411,
            },
            0   => +{
                check => 0,
                bar   => 144,
            },
            '-' => +{
                check => 10,
                bar   => 414,
            },
            CC1 => +{
                check => 11,
                bar   => 324,
            },
            CC2 => +{
                check => 12,
                bar   => 342,
            },
            CC3 => => +{
                check => 13,
                bar   => 234,
            },
            CC4 => +{
                check => 14,
                bar   => 432,
            },
            CC5 => +{
                check => 15,
                bar   => 243,
            },
            CC6 => +{
                check => 16,
                bar   => 423,
            },
            CC7 => +{
                check => 17,
                bar   => 441,
            },
            CC8 => +{
                check => 18,
                bar   => 111,
            },
        );
        my @cc = @code{qw(CC1 CC2 CC3)};
        for my $i (0 .. $#cc) {
            for my $num (0 .. 9) {
                my $k = chr(65 + (10 * $i) + $num);
                my $v = [ $cc[$i], $code{$num} ];
                $code{$k} = +{
                    check => [ $cc[$i]->{check}, $code{$num}->{check} ],
                    bar   => [ $cc[$i]->{bar},   $code{$num}->{bar}   ],
                };
                last if $k ge 'Z';
            }
        }
        return \%code;
    },
);

no Mouse;

__PACKAGE__->meta->make_immutable;

sub _to_code {
    my($self, $char) = @_;
    return $self->_char_code->{uc($char)};
}

sub _find_bar_by_check {
    my($self, $check) = @_;
    my $code = $self->_char_code;
    for my $v (values %$code) {
        next unless exists $v->{check};
        my $val = $v->{check};
        next if ref($val) eq 'ARRAY';
        next if $val != $check;
        return $v->{bar};
    }
}

sub draw {
    my $self = shift;
    my $bars = $self->make_bars;
    for my $bar (@$bars) {
        $self->_draw_num(split //, $bar);
    }
    return $self->_base;
}

sub make_bars {
    my $self = shift;
    unless ($self->zipcode =~ /^\d{7}$/) {
        croak('Invalid zipcode(): ' . $self->zipcode);
    }
    unless ($self->address =~ /^[-0-9A-Z]*$/i) {
        croak('Invalid address(): ' . $self->zipcode);
    }
    my @bars = ();
    my $checksum = 0;

    my $start = $self->_to_code('STC');
    push @bars, $start->{bar};

    for my $chr (split //, $self->zipcode) {
        my $code = $self->_to_code($chr);
        $checksum += $code->{check};
        push @bars, $code->{bar};
    }

    for my $chr (split //, $self->address) {
        my $code = $self->_to_code($chr);
        my $check = $code->{check};
        if (ref($check) eq 'ARRAY') {
            my $bar = $code->{bar};
            for my $i (0 .. $#{$check}) {
                my $c = $check->[$i];
                my $b = $bar->[$i];
                $checksum += $c;
                push @bars, $b;
                last if @bars >= 21;
            }
        }
        else {
            $checksum += $code->{check};
            push @bars, $code->{bar};
        }
        last if @bars >= 21;
    }

    while (scalar(@bars) < 21) {
        my $code = $self->_to_code('CC4');
        $checksum += $code->{check};
        push @bars, $code->{bar};
    }

    my $checkdigit = 19 - ($checksum % 19);
    my $bar = $self->_find_bar_by_check($checkdigit);
    push @bars, $bar;

    my $stop = $self->_to_code('SPC');
    push @bars, $stop->{bar};
    return \@bars;
}

sub _build__base {
    my $self = shift;
    my $img = Imager->new(
        xsize => 979,
        ysize => 90,
    );
    $img->settag(name => 'i_xres', value => 300);
    $img->settag(name => 'i_xres', value => 300);
    $img->box(filled => 1, color => '#ffffff');
    return $img;
}

sub _draw_num {
    my $self = shift;
    my @nums = @_;
    for my $num (@nums) {
        my $pos = $self->_pos;
        my $x = 24 + $pos * 14;
        my $ymin = $num =~ m{^[12]$} ? 24 : 37;
        my $ymax = +{
            1 => $ymin + 41,
            2 => $ymin + 27,
            3 => $ymin + 27,
            4 => $ymin + 13,
        }->{$num};
        $self->_base->box(
            xmin   => $x,
            ymin   => $ymin,
            xmax   => $x + 6,
            ymax   => $ymax,
            color  => '#000000',
            filled => 1,
        );
        $self->_pos($self->_pos + 1);
    }
}

1;
__END__

=head1 NAME

Imager::IMBarcode::JP - Japan's Intelligent Mail Barcode Generator

=head1 SYNOPSIS

 use Imager::IMBarcode::JP;
 
 my $imbjp = Imager::IMBarcode::JP->new(
     zipcode => '1234567',
     address => '1-23-45-B709',
 );
 
 my $imager = $imbjp->draw;
 $imager->write(file => '/path/to/barcode.png') or die $imager->errstr;

=head1 DESCRIPTION

This is a generator of intelligent mail barcode in Japan
(called "Customer Barcode") which is consisted by Japan Post.

=head1 METHODS

=over 4

=item zipcode

allows only 7 digit numbers.

=item address

allows some numbers, hyphens and alphabets.

=item draw

generates IM barcode and returns L<Imager> object. the generated image has 300 dpi.

=back

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
=over 4
 
=item * Customer Barcode Manual
L<https://www.post.japanpost.jp/zipcode/zipmanual/>
 
=item * Imager
L<Imager>
 
=back
 
=cut

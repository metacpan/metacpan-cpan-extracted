# NAME

Imager::IMBarcode::JP - Japan's Intelligent Mail Barcode Generator

# SYNOPSIS

    use Imager::IMBarcode::JP;
    
    my $imbjp = Imager::IMBarcode::JP->new(
        zipcode => '1234567',
        address => '1-23-45-B709',
    );
    
    my $imager = $imbjp->draw;
    $imager->write(file => '/path/to/barcode.png') or die $imager->errstr;

# DESCRIPTION

This is a generator of intelligent mail barcode in Japan
(called "Customer Barcode") which is consisted by Japan Post.

# METHODS

- zipcode

    allows only 7 digit numbers.

- address

    allows some numbers, hyphens and alphabets.

- draw

    generates IM barcode and returns [Imager](https://metacpan.org/pod/Imager) object. the generated image has 300 dpi.

# AUTHOR

Koichi Taniguchi (a.k.a. nipotan) <taniguchi@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- Customer Barcode Manual
[https://www.post.japanpost.jp/zipcode/zipmanual/](https://www.post.japanpost.jp/zipcode/zipmanual/)
- Imager
[Imager](https://metacpan.org/pod/Imager)

# NAME

Lingua::JA::Gal - "ギャル文字" converter

# SYNOPSIS

    use utf8;
    use Lingua::JA::Gal;

    $text = Lingua::JA::Gal->gal("こんにちは"); # => "⊇ｗ丨ﾆちﾚ￡"

# DESCRIPTION

"ギャル文字" (gal's alphabet) is a Japanese writing style
that was popular with Japanese teenage girls in the early 2000s.

[https://ja.wikipedia.org/wiki/%E3%82%AE%E3%83%A3%E3%83%AB%E6%96%87%E5%AD%97](https://ja.wikipedia.org/wiki/%E3%82%AE%E3%83%A3%E3%83%AB%E6%96%87%E5%AD%97)

# METHOD

## gal( $text, \[ \\%options \] )

    Lingua::JA::Gal->gal("ギャルもじ"); # => "(ｷ〃ャlﾚ€Ｕ〃"

### OPTIONS

- `rate`

    for converting rate. default is 100 (full).

        Lingua::JA::Gal->gal($text, { rate => 100 }); # full(default)
        Lingua::JA::Gal->gal($text, { rate =>  50 }); # half
        Lingua::JA::Gal->gal($text, { rate =>   0 }); # nothing

- `callback`

    if you want to do your own gal way.

        Lingua::JA::Gal->gal($text, { callback => sub {
            my ($char, $suggestions, $options) = @_;
             

            # 漢字のみ変換する
            if ($char =~ /p{Han}/) {
                return $suggestions->[ int(rand @$suggestions) ];
            } else {
                return $char;
            }
        });

# EXPORT

no exports by default.

## gal

    use Lingua::JA::Gal qw/gal/;

    print gal("...");

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

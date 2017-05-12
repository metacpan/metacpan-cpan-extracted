# NAME

Math::CheckDigits - Perl Module to generate and test check digits

# SYNOPSIS

    use Math::CheckDigits;
    my $cd = Math::CheckDigits->new(
      modulus => 11,
      weight  => [2..7],
    );
    print $cd->checkdigit('12345678'); #5
    print $cd->complete('12345678'); #123456785
    print 'ok' if $cd->is_valid('123456785');

set options

    use Math::CheckDigits;
    my $cd = Math::CheckDigits->new(
      modulus => 10,
      weight  => [1, 2],
    )->options(
      runes => 1,
    );

    print $cd->complete('348764') #3487649

advanced

    # modulus 16
    use Math::CheckDigits;
    $cd = Math::CheckDigits->new(
      modulus => 16,
      weight  => [1],
    )->trans_table(
      10  => '-',
      11  => '$',
      12  => ':',
      13  => '.',
      14  => '/',
      15  => '+',
      16  => 'a',
      17  => 'b',
      18  => 'c',
      19  => 'd',
    );
    print $cd->checkdigit('a16329aa') # $;



# DESCRIPTION

Math::CheckDigits is the Module for generating and testing check digits.

This module is similar to [Algorithm::CheckDigits](http://search.cpan.org/perldoc?Algorithm::CheckDigits). But, in this module, check digits can be computed from not format names (ex. JAN ISBN..), but two arguments, Modulus and Weight. This is the difference between [Algorithm::CheckDigits](http://search.cpan.org/perldoc?Algorithm::CheckDigits) and this module.

This module is effective to any check digits format using Modulus and Weight, and can't support the format that are generated from complicated algorithm.

# AUTHOR

Songmu <y.songmu@gmail.com>

# SEE ALSO

[Algorithm::CheckDigits](http://search.cpan.org/perldoc?Algorithm::CheckDigits)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

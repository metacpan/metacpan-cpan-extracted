use Test::More tests => 7;
use Test::More::UTF8;
use Test::Exception;
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';

use utf8;

use_ok "Lingua::RU::Num2Word", "num2rus_cardinal";

subtest masculine => sub {

    my $data = {
        'сто двадцать три'                   => [ 123 ],
        'пятьдесят четыре'                  => [ 54 ],
        'семьдесят два'                        => [ 72, 'MASCULINE' ],
        'шестьсот шестьдесят шесть' => [ 666 ],
    };

    for my $expected_result ( keys %$data ) {
        my $arguments = $data->{$expected_result};
        my $result    = num2rus_cardinal( @$arguments );
        is $result, $expected_result, "$expected_result == $result for data (@$arguments)";
    }
};

subtest 'counting to hundred' => sub {

    my $translated_numbers = [
        'ноль',
        'один',
        'два',
        'три',
        'четыре',
        'пять',
        'шесть',
        'семь',
        'восемь',
        'девять',
        'десять',
        'одинадцать',
        'двенадцать',
        'тринадцать',
        'четырнадцать',
        'пятнадцать',
        'шестнадцать',
        'семнадцать',
        'восемнадцать',
        'девятнадцать',
        'двадцать',
        'двадцать один',
        'двадцать два',
        'двадцать три',
        'двадцать четыре',
        'двадцать пять',
        'двадцать шесть',
        'двадцать семь',
        'двадцать восемь',
        'двадцать девять',
        'тридцать',
        'тридцать один',
        'тридцать два',
        'тридцать три',
        'тридцать четыре',
        'тридцать пять',
        'тридцать шесть',
        'тридцать семь',
        'тридцать восемь',
        'тридцать девять',
        'сорок',
        'сорок один',
        'сорок два',
        'сорок три',
        'сорок четыре',
        'сорок пять',
        'сорок шесть',
        'сорок семь',
        'сорок восемь',
        'сорок девять',
        'пятьдесят',
        'пятьдесят один',
        'пятьдесят два',
        'пятьдесят три',
        'пятьдесят четыре',
        'пятьдесят пять',
        'пятьдесят шесть',
        'пятьдесят семь',
        'пятьдесят восемь',
        'пятьдесят девять',
        'шестьдесят',
        'шестьдесят один',
        'шестьдесят два',
        'шестьдесят три',
        'шестьдесят четыре',
        'шестьдесят пять',
        'шестьдесят шесть',
        'шестьдесят семь',
        'шестьдесят восемь',
        'шестьдесят девять',
        'семьдесят',
        'семьдесят один',
        'семьдесят два',
        'семьдесят три',
        'семьдесят четыре',
        'семьдесят пять',
        'семьдесят шесть',
        'семьдесят семь',
        'семьдесят восемь',
        'семьдесят девять',
        'восемьдесят',
        'восемьдесят один',
        'восемьдесят два',
        'восемьдесят три',
        'восемьдесят четыре',
        'восемьдесят пять',
        'восемьдесят шесть',
        'восемьдесят семь',
        'восемьдесят восемь',
        'восемьдесят девять',
        'девяносто',
        'девяносто один',
        'девяносто два',
        'девяносто три',
        'девяносто четыре',
        'девяносто пять',
        'девяносто шесть',
        'девяносто семь',
        'девяносто восемь',
        'девяносто девять',
        'сто'
    ];


    for my $number ( 0 .. 100 ) {
        my $expected = $translated_numbers->[$number];
        my $string = num2rus_cardinal($number);
        is $string, $expected, "number $number: got $string, expected $expected";
    }
};

subtest feminine => sub {

    my $data = {
        121 => 'сто двадцать одна',
        2 => 'две',
        343 => 'триста сорок три',
        152 => 'сто пятьдесят две',
    };

    for my $number ( keys %$data ) {
        my $result    = num2rus_cardinal( $number, 'feminine' );
        my $expected_result = $data->{$number};
        is $result, $expected_result, "$expected_result == $result for data ($number, 'feminine')";
    }

    is num2rus_cardinal(1, "FEMININE" ), 'одна', 'Capitalized gender is also ok';
};

subtest neuter => sub {
    my $data = {
        'сто двадцать одно' => [ 121, 'neuter' ],
        'тридцать два'          => [ 32,  'neuter' ],
    };

    for my $expected_result ( keys %$data ) {
        my $arguments = $data->{$expected_result};
        my $result    = num2rus_cardinal( @$arguments );
        is $result, $expected_result, "$expected_result == $result for data (@$arguments)";
    }
};

subtest 'some numbers' => sub {
    is num2rus_cardinal( 1_121_343 ),
      "один миллион сто двадцать одна тысяча триста сорок три",
      "Translates big number ok";

    is num2rus_cardinal( 999_999_999_999_999_999 ), "", "Cannot translate very big number";
    is num2rus_cardinal( 999_888 ), "девятьсот девяносто девять тысяч восемьсот восемьдесят восемь", "Another big number translation ok";

    is num2rus_cardinal( 0 ), "ноль", "Undef becomes zero";
};

# some errors...

subtest 'some errors' => sub {
    throws_ok { num2rus_cardinal( 123, 1 ) } qr/Wrong gender/, 'Throws error if gender specified incorrectly';
};


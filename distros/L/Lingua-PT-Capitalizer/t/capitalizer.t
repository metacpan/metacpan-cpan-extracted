#/usr/bin/env perl

use common::sense;
use warnings FATAL => q(all);
use Test::More;

my @name_or_title = (
    q(Carolina Josefa Leopoldina Francisca Fernanda de Habsburgo-Lorena),
    q(Teresa Cristina Maria Giuseppa Gasparre Baltassarre Melchiore Gennara Rosalia Lucia Francesca d'Assisi Elisabetta Francesca di Padova Donata Bonosa Andrea d'Avelino Rita Liutgarda Geltruda Venancia Taddea Spiridione Rocca Matilde),
    q(Pedro de Alcântara Francisco António João Carlos Xavier de Paula Miguel Rafael Joaquim José Gonzaga Pascoal Cipriano Serafim de Bragança e Bourbon),
    q(Isabel Cristina Leopoldina Augusta Micaela Gabriela Rafaela Gonzaga de Bragança e Bourbon),
    q(Av. Brig. Luís Antônio),
    q(D'Ouro),
    q(Escritor, Jornalista, Contista e Poeta Joaquim Maria Machado de Assis),
);

my @test;
foreach my $expected (@name_or_title) {
    my $input_uc = uc $expected;
    push @test, [ $input_uc, $expected ];

    my $input_lc = lc $expected;
    push @test, [ $input_lc, $expected ];

    my $input_rand = join q(),
        map { rand(time) % 3 ? uc : lc } split //, $expected;
    push @test, [ $input_rand, $expected ];
}

use Lingua::PT::Capitalizer ();
my $capitalizer = Lingua::PT::Capitalizer->new();

foreach my $test (@test) {
    my ( $input, $expected ) = @$test;
    my $output = $capitalizer->capitalize($input);
    ok( $output eq $expected, $input ) or die;
}

ok( $capitalizer->capitalize( q(notebook com 30GB de RAM), 1 ) eq
        q(Notebook Com 30GB de RAM),
    q(preserve_caps mode)
);

done_testing();

# Local Variables:
# mode: perl
# coding: utf-8-unix
# End:

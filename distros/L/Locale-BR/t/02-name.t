use strict;
use warnings;

use Test::More tests => 114;

use Locale::BR ':all';

sub permute_name {
    my $name = shift;
    return ( $name, lc $name, uc $name );
}

foreach (permute_name('Acre')) {
    is( state2code($_), 'AC', 'checking ac' );
}

foreach (permute_name('Alagoas')) {
    is( state2code($_), 'AL', 'checking al' );
}

foreach (permute_name('Amapá'), permute_name('Amapa') ) {
    is( state2code($_), 'AP', 'checking ap' );
}

foreach (permute_name('Amazonas')) {
    is( state2code($_), 'AM', 'checking am' );
}

foreach (permute_name('Bahia')) {
    is( state2code($_), 'BA', 'checking ba' );
}

foreach (permute_name('Ceará'), permute_name('Ceara')) {
    is( state2code($_), 'CE', 'checking ce' );
}

foreach (permute_name('Distrito Federal')) {
    is( state2code($_), 'DF', 'checking df' );
}

foreach (permute_name('Espírito Santo'), permute_name('Espirito Santo')) {
    is( state2code($_), 'ES', 'checking es' );
}

foreach (permute_name('Goiás'), permute_name('Goias')) {
    is( state2code($_), 'GO', 'checking go' );
}

foreach (permute_name('Maranhão'), permute_name('Maranhao')) {
    is( state2code($_), 'MA', 'checking ma' );
}

foreach (permute_name('Mato Grosso')) {
    is( state2code($_), 'MT', 'checking mt' );
}

foreach (permute_name('Mato Grosso do Sul')) {
    is( state2code($_), 'MS', 'checking ms' );
}

foreach (permute_name('Minas Gerais')) {
    is( state2code($_), 'MG', 'checking mg' );
}

foreach (permute_name('Pará'), permute_name('Para')) {
    is( state2code($_), 'PA', 'checking pa' );
}

foreach (permute_name('Paraíba'), permute_name('Paraiba')) {
    is( state2code($_), 'PB', 'checking pb' );
}

foreach (permute_name('Paraná'), permute_name('Parana')) {
    is( state2code($_), 'PR', 'checking pr' );
}

foreach (permute_name('Pernambuco')) {
    is( state2code($_), 'PE', 'checking pe' );
}

foreach (permute_name('Piauí'), permute_name('Piaui')) {
    is( state2code($_), 'PI', 'checking pi' );
}

foreach (permute_name('Rio de Janeiro')) {
    is( state2code($_), 'RJ', 'checking rj' );
}

foreach (permute_name('Rio Grande do Norte')) {
    is( state2code($_), 'RN', 'checking rn' );
}

foreach (permute_name('Rio Grande do Sul')) {
    is( state2code($_), 'RS', 'checking rs' );
}

foreach (permute_name('Rondônia'), permute_name('Rondonia')) {
    is( state2code($_), 'RO', 'checking ro' );
}

foreach (permute_name('Roraima')) {
    is( state2code($_), 'RR', 'checking rr' );
}

foreach (permute_name('Santa Catarina')) {
    is( state2code($_), 'SC', 'checking sc' );
}

foreach (permute_name('São Paulo'), permute_name('Sao Paulo')) {
    is( state2code($_), 'SP', 'checking sp' );
}

foreach (permute_name('Sergipe')) {
    is( state2code($_), 'SE', 'checking se' );
}

foreach (permute_name('Tocantins')) {
    is( state2code($_), 'TO', 'checking to' );
}

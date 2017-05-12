package Geo::CEP;
# ABSTRACT: Resolve Brazilian city data for a given CEP


use strict;
use utf8;
use warnings qw(all);

use integer;

use Carp qw(carp confess croak);
use File::ShareDir qw(dist_file);
use IO::File;
use Memoize;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Scalar::Util qw(looks_like_number);
use Text::CSV;

our $VERSION = '1.0'; # VERSION

has csv     => (is => 'ro', isa => InstanceOf['Text::CSV'], default => sub { Text::CSV->new }, lazy => 1);


has data    => (is => 'rwp', isa => FileHandle);
has index   => (is => 'rwp', isa => FileHandle);


has length  => (is => 'rwp', isa => Int, default => sub { 0 });


my %states = (
    AC  => 'Acre',
    AL  => 'Alagoas',
    AM  => 'Amazonas',
    AP  => 'Amapá',
    BA  => 'Bahia',
    CE  => 'Ceará',
    DF  => 'Distrito Federal',
    ES  => 'Espírito Santo',
    GO  => 'Goiás',
    MA  => 'Maranhão',
    MG  => 'Minas Gerais',
    MS  => 'Mato Grosso do Sul',
    MT  => 'Mato Grosso',
    PA  => 'Pará',
    PB  => 'Paraíba',
    PE  => 'Pernambuco',
    PI  => 'Piauí',
    PR  => 'Paraná',
    RJ  => 'Rio de Janeiro',
    RN  => 'Rio Grande do Norte',
    RO  => 'Rondônia',
    RR  => 'Roraima',
    RS  => 'Rio Grande do Sul',
    SC  => 'Santa Catarina',
    SE  => 'Sergipe',
    SP  => 'São Paulo',
    TO  => 'Tocantins',
);

has states  => (
    is      => 'ro',
    isa     => HashRef[Str],
    default => sub { \%states }
);


my $idx_len = length(pack('N*', 1 .. 2));

has idx_len => (is => 'ro', isa => Int, default => sub { $idx_len });


sub BUILD {
    my ($self) = @_;

    $self->csv->column_names([qw(cep_initial cep_final state city ddd lat lon)]);

    my $data = IO::File->new(dist_file('Geo-CEP', 'cep.csv'), '<:encoding(latin1)');
    confess "Error opening CSV: $!" unless defined $data;
    $self->_set_data($data);

    my $index = IO::File->new(dist_file('Geo-CEP', 'cep.idx'), O_RDONLY);
    confess "Error opening index: $!" unless defined $index;
    $self->_set_index($index);

    my $size = $index->sysseek(0, SEEK_END)
        or confess "Can't tell(): $!";

    confess 'Inconsistent index size'
        if not $size
        or $size % $idx_len;
    $self->_set_length($size / $idx_len);

    return;
}

sub import {
    my (undef, @args) = @_;

    if (grep { $_ eq 'memoize' } @args) {
        memoize $_
            for qw(_bsearch _fetch_row _find _get_idx);
    }

    return;
}
# Retorna o registro no arquivo CSV; uso interno.
sub _get_idx {
    my ($self, $n, $want_offset) = @_;

    my $buf = '';
    $self->index->sysseek($n * $idx_len, SEEK_SET)
        or confess "Can't seek(): $!";

    $self->index->sysread($buf, $idx_len)
        or confess "Can't read(): $!";

    my ($cep, $offset) = unpack 'N*' => $buf;
    return defined $want_offset
        ? $offset
        : $cep;
}

# Efetua a busca binária (implementação não-recursiva); uso interno.
sub _bsearch {
    my ($self, $hi, $val) = @_;
    my ($lo, $cep, $mid) = qw(0 0 0);

    return
        if ($self->_get_idx($lo) > $val)
        or ($self->_get_idx($hi) < $val);

    while ($lo <= $hi) {
        $mid = ($lo + $hi) / 2;
        $cep = $self->_get_idx($mid);
        if ($val < $cep) {
            $hi = $mid - 1;
        } elsif ($val > $cep) {
            $lo = $mid + 1;
        } else {
            last;
        }
    }

    --$mid if $cep > $val;
    return $self->_get_idx($mid, 1);
}


# Lê e formata o registro a partir do cep.csv; uso interno.
sub _fetch_row {
    my ($self, $offset) = @_;

    no integer;

    $self->data->seek($offset, SEEK_SET)
        or confess "Can't seek(): $!";

    my $row = $self->csv->getline_hr($self->data);
    return
        if 'HASH' ne ref $row
        or not defined $row->{state};

    my %res = map {
        $_ =>
            looks_like_number($row->{$_})
                ? 0 + sprintf('%.7f', $row->{$_})
                : $row->{$_}
    } qw(state city ddd lat lon cep_initial cep_final);
    $res{state_long}= $states{$res{state}};

    return \%res;
}


sub _find {
    my ($self, $cep) = @_;
    my $offset = $self->_bsearch($self->length - 1, $cep);
    if (defined $offset) {
        return $self->_fetch_row($offset);
    } else {
        return;
    }
}

sub find {
    my ($self, $cep) = @_;
    $cep =~ s/\D//gsx;
    return $self->_find(substr($cep, 0, 8));
}


sub list {
    my ($self) = @_;

    $self->index->sysseek(0, SEEK_SET)
        or confess "Can't seek(): $!";

    my %list;
    my $buf;
    while ($self->index->sysread($buf, $idx_len)) {
        my (undef, $offset) = unpack 'N*' => $buf;
        my $row = $self->_fetch_row($offset);
        $list{$row->{city} . '/' . $row->{state}} = $row
            if defined $row;
    }
    $self->csv->eof
        or croak $self->csv->error_diag;

    return \%list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::CEP - Resolve Brazilian city data for a given CEP

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use common::sense;
    use utf8::all;

    use Data::Printer;

    # 'memoize' é extremamente vantajoso em casos aonde a mesma
    # instância é utilizada para resolver lotes grandes de CEPs
    use Geo::CEP qw(memoize);

    my $gc = Geo::CEP->new;
    p $gc->find("12420-010");

    # Saída:
    # \ {
    #     cep_final    12449999
    #     cep_initial  12400000
    #     city         "Pindamonhangaba",
    #     ddd          12,
    #     lat          -22.9166667,
    #     lon          -45.4666667,
    #     state        "SP",
    #     state_long   "São Paulo"
    # }

=head1 DESCRIPTION

Obtém os dados como: nome da cidade, do estado, número DDD e latitude/longitude (da cidade) para um número CEP (Código de Endereçamento Postal) brasileiro.

Diferentemente do L<WWW::Correios::CEP>, consulta os dados armazenados localmente.
Por um lado, isso faz L<Geo::CEP> ser extremamente rápido (5 mil consultas por segundo); por outro, somente as informações à nível de cidade são retornadas.

=head1 ATTRIBUTES

=head2 data, index

I<FileHandle> para os respectivos arquivos.

=head2 length

Tamanho do índice.

=head2 states

Mapeamento de código de estado para o nome do estado (C<AC =E<gt> 'Acre'>).

=head2 idx_len

Tamanho do registro de índice.

=head1 METHODS

=head2 find($cep)

Busca por C<$cep> (no formato I<12345678> ou I<"12345-678">) e retorna I<HashRef> com:

=over 4

=item *

I<cep_initial>: o início da faixa de CEPs da cidade;

=item *

I<cep_final>: o término da faixa de CEP da cidade;

=item *

I<state>: sigla da Unidade Federativa (SP, RJ, MG);

=item *

I<state_long>: nome da Unidade Federativa (São Paulo, Rio de Janeiro, Minas Gerais);

=item *

I<city>: nome da cidade;

=item *

I<ddd>: código DDD (pode estar vazio);

=item *

I<lat>/I<lon>: coordenadas geográficas da cidade (podem estar vazias).

=back

Retorna C<undef> quando não foi possível encontrar.

=head2 list()

Retorna I<HashRef> com os dados de todas as cidades.

=begin test_synopsis




=end test_synopsis

=for Pod::Coverage BUILD
import

=head1 SEE ALSO

=over 4

=item *

L<cep2city>

=item *

L<Business::BR::CEP>

=item *

L<WWW::Correios::CEP>

=item *

L<WWW::Correios::PrecoPrazo>

=item *

L<WWW::Correios::SRO>

=back

=head1 CONTRIBUTORS

=over 4

=item *

L<Blabos de Blebe|https://metacpan.org/author/BLABOS>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

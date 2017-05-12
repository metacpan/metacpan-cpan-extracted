package Geography::JapaneseMunicipals;

use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use Encode;
use Geography::JapanesePrefectures;
use Geography::JapaneseMunicipals::Data;

sub _prefecture_id {
    my($self, $prefecture) = @_;

    my $prefecture_id;
    if ($prefecture =~ /^\d+$/) {
        $prefecture_id = $prefecture;
    } else {
        my $name = Encode::encode('utf8', $prefecture);
        $prefecture_id = Geography::JapanesePrefectures->prefectures_id($name);
        return undef
            unless $prefecture_id;
    }

    return $prefecture_id;
}

sub _prefecture_name {
    my($self, $prefecture) = @_;

    my $prefecture_name;
    if ($prefecture =~ /^\d+$/) {
        foreach my $prefectures_info (@{Geography::JapanesePrefectures->prefectures_infos}) {
            if ($prefectures_info->{id} ne $prefecture) {
                next;
            }
            $prefecture_name = Encode::decode('utf8', $prefectures_info->{name});
            last;
        }
        return undef
            unless $prefecture_name;
    } else {
        $prefecture_name = $prefecture;
    }

    return $prefecture_name;
}

sub _divide_prefecture_municipal {
    my($self, $prefecture_municipal) = @_;

    foreach my $pref (Geography::JapanesePrefectures->prefectures) {
        my $name = Encode::decode('utf8', $pref);
        return { prefecture => $1, municipal => $2 }
            if ($prefecture_municipal =~ /^($name)(.*)$/);
    }

    undef;
}

sub municipals {
    my $self = shift;

    my $names = [ ];
    push @{$names}, map { $_->{name} } @{$Geography::JapaneseMunicipals::Data::MUNICIPALS->{$_}->{municipals}}
        foreach (keys %{$Geography::JapaneseMunicipals::Data::MUNICIPALS});
    $names;
}

sub municipal_infos {
    my($self, $prefecture, $municipal) = @_;

    if (defined $prefecture) {
        if ($prefecture =~ /^(\d{1,2})(\d*)$/) {
            $municipal = $self->municipal_name($prefecture)
                if defined $2;
            $prefecture = $self->_prefecture_name($1);

        } elsif (!defined $municipal) {
            my $data = $self->_divide_prefecture_municipal($prefecture);
            return undef
                unless $data;

            $prefecture = $data->{prefecture};
            $municipal = $data->{municipal};
        }
    }

    my $infos = [ ];
    foreach my $prefectures_info (@{Geography::JapanesePrefectures->prefectures_infos}) {
        my $prefectures_name = Encode::decode('utf8', $prefectures_info->{name});
        next
            if defined $prefecture
                && $prefectures_name ne $prefecture;

        foreach my $municipal_info (@{$Geography::JapaneseMunicipals::Data::MUNICIPALS->{$prefectures_info->{id}}->{municipals}}) {
            next
                if $municipal
                    && $municipal_info->{name} ne $municipal;

            push @{$infos},  {
                region => { name => Encode::decode('utf8', $prefectures_info->{region}) },
                prefecture => { id => $prefectures_info->{id}, name => $prefectures_name },
                id => $municipal_info->{id},
                name => $municipal_info->{name} };
        }
    }

    $infos;
}

sub municipals_in {
    my($self, $prefecture) = @_;

    my $prefecture_id = $self->_prefecture_id($prefecture);
    my @municipals = map { $_->{name} } @{$Geography::JapaneseMunicipals::Data::MUNICIPALS->{$prefecture_id}->{municipals}};
    \@municipals;
}

sub municipal_id {
    my($self, $prefecture, $municipal) = @_;

    if (!defined $municipal) {
        my $info = $self->_divide_prefecture_municipal($prefecture);
        return undef
            unless $info || $info->{municipal};

        $prefecture = $info->{prefecture};
        $municipal = $info->{municipal};
    }

    my $prefecture_id = $self->_prefecture_id($prefecture);
    return undef
        unless $prefecture_id;

    foreach (@{$Geography::JapaneseMunicipals::Data::MUNICIPALS->{$prefecture_id}->{municipals}}) {
        return $_->{id}
            if $municipal eq $_->{name};
    }

    undef;
}

sub municipal_name {
    my($self, $municipal_id) = @_;

    return undef
        unless $municipal_id =~ /^(\d{2})\d{3}$/;

    my $id = int $1;
    foreach (@{$Geography::JapaneseMunicipals::Data::MUNICIPALS->{$id}->{municipals}}) {
        return $_->{name}
            if $municipal_id eq $_->{id};
    }

    undef;
}

1;

__END__

=encoding utf8

=head1 NAME

Geography::JapaneseMunicipals - Japanese Municipals Data.

=head1 SYNOPSIS

    use utf8;
    use Geography::JapaneseMunicipals;

    my $names = Geography::JapaneseMunicipals->municipals_in('北海道');
    my $name = Geography::JapaneseMunicipals->municipal_name('01202');
    my $id = Geography::JapaneseMunicipals->municipal_id('東京都渋谷区');
    my $infos = Geography::JapaneseMunicipals->municipal_infos('13113');

=head1 DESCRIPTION

This module allows you to get information on Japanese Municipals names.

=head1 Class Methods

=head2 municipals

    my $municipals = Geography::JapaneseMunicipals->municipals();
    # => ['岡山市', '倉敷市', ..., '東成瀬村']

get the municipal names in all prefecture.

=head2 municipals_in

    my $municipals = Geography::JapaneseMunicipals->municipals_in('北海道');
    # => ['札幌市', '札幌市中央区', ..., '羅臼町']

get the municipal names in the prefecture.

=head2 municipal_infos

    my $infos = Geography::JapaneseMunicipals->municipal_infos('東京都渋谷区');
    # => [{ id => '13113', name => '渋谷区', prefecture => { id => '13', name => '東京都' }, region => { name => '関東' } }]

    $infos = Geography::JapaneseMunicipals->municipal_infos('13113');
    # => [{ id => '13113', name => '渋谷区', prefecture => { id => '13', name => '東京都' }, region => { name => '関東' } }]

    $infos = Geography::JapaneseMunicipals->municipal_infos('東京都');
    # => [{ id => '13101', name => '千代田区', prefecture => { id => '13', name => '東京都' }, region => { name => '関東' } }, ...]

    $infos = Geography::JapaneseMunicipals->municipal_infos('13');
    # => [{ id => '13101', name => '千代田区', prefecture => { id => '13', name => '東京都' }, region => { name => '関東' } }, ...]

    $infos = Geography::JapaneseMunicipals->municipal_infos();
    # => [{ id => '01100', name => '札幌市', prefecture => { id => '1', name => '北海道' }, region => { name => '北海道' } }, ...]

get the informations of the municipal.

=head2 municipal_id

    my $id = Geography::JapaneseMunicipals->municipal_id('沖縄県那覇市');
    # => '47201'

get the municipal id.

=head2 municipal_name

    my $name = Geography::JapaneseMunicipals->municipal_name('47201');
    # => '那覇市'

get the municipal name.

=head1 SEE ALSO

L<Geography::JapanesePrefectures>

=head1 AUTHOR

Yukio Suzuki E<lt>yukio at cpan.orgE<gt>

=head1 REPOSITORY

    svn co http://svn.coderepos.org/share/lang/perl/Geography-JapaneseMunicipals/trunk Geography-JapaneseMunicipals

Geography::JapaneseMunicipals is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

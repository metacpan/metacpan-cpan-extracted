#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode;
use LWP::Simple;
use YAML;

my $text = decode("shift_jis", get("http://miyagawa.googlepages.com/convert.txt"));
   $text =~ tr/\r//d;

my $from_number = {};
setup_table($from_number);

my @table;
my %conv;
for (split /\n/, $text) {
    next unless /^\d/;
    chomp;

    # 89468 = 8 95 68
    # 169102 = 169 102
    s/^(\d)(\d{2})(\d{2})$/$1 $2 $3/;
    s/(\d{3})(\d{3})/$1 $2/;

    # 拡02 => 拡2
    s/拡0(\d)/拡$1/;

    my %map;
    @map{qw( softbank kddi docomo )} = split / (?:\- )?/, $_, 3;

    for my $c ( qw( softbank kddi docomo )) {
        warn "[$c] $_" unless defined $map{$c};
        my $key = $c eq 'kddi' ? 'unicode_auto' : 'unicode';
        if ($map{$c} =~ m!/!) {
            my @code = split '/', $map{$c};
            $map{$c} = join "", map $from_number->{$c}{$_}{$key}, @code;
        } else {
            my $info = $from_number->{$c}{$map{$c}};
            if ($info) {
                $map{$c} = $info->{$key};
            } elsif ($map{$c} ne '〓' && $map{$c} !~ /^\[/) {
                warn "$c: $map{$c}";
            }
        }
    }

    push @table, \%map;
    $conv{$map{softbank}} = {
        kddi => $map{kddi},
        docomo => $map{docomo},
    };
}

binmode STDOUT, ":utf8";
#print Dump \@table;
print Dump \%conv;

sub setup_table {
    my $from_number = shift;
    for my $c ( qw( docomo kddi softbank ) ) {
        my $dat = YAML::LoadFile("dat/$c-table.yaml");
        for my $row (@$dat) {
            $from_number->{$c}{ decode_utf8($row->{number}) } = $row;
        }
    }
}

use warnings;
use strict;
use 5.10.0;
use Encode::JP::H2Z;
use Encode;
use Data::Dumper;

my @d = split /\n/, do "unicore/Name.pl";
my %n2h;
my %h2n;
for my $l (@d) {
    if ($l =~ /^(\S+)\s+(.+)$/) {
        my ($hex, $name) = ($1, $2);
        $h2n{$hex} = $name;
        $n2h{$name} = $hex;
    }
}

sub alnum_z2h {
    my @alnum_z2h_z;
    my @alnum_z2h_h;
    while (my ($name, $hex) = each %n2h) {
        if ($name =~ /^FULLWIDTH (.+)/) {
            push @alnum_z2h_z, "\\x{$hex}";
            push @alnum_z2h_h, "\\x{$n2h{$1}}";
        }
    }
    return "tr/", join('', @alnum_z2h_z), "/", join('', @alnum_z2h_h), "/";
}

sub hiragana2katakana {
    my @hiragana2katakana_h;
    my @hiragana2katakana_k;
    while (my ($name, $hex) = each %n2h) {
        next if $name eq 'HIRAGANA DIGRAPH YORI'; # HIRAGANA DIGRAPH YORI doesn't exists in katakana form
        if ($name =~ /^HIRAGANA (.+)/) {
            push @hiragana2katakana_h, "\\x{$hex}";
            my $katakananame = "KATAKANA $1";
            warn "$katakananame" unless $n2h{$katakananame};
            push @hiragana2katakana_k, "\\x{$n2h{$katakananame}}";
        }
    }
    return "tr/", join('', @hiragana2katakana_h), "/", join('', @hiragana2katakana_k), "/";
}

sub katakana2hiragana {
    my @katakana2hiragana_h;
    my @katakana2hiragana_k;
    while (my ($name, $hex) = each %n2h) {
        next if $name eq 'KATAKANA LETTER VA';
        next if $name eq 'KATAKANA LETTER SMALL RE';
        next if $name eq 'KATAKANA LETTER SMALL HU';
        next if $name eq 'KATAKANA LETTER SMALL HI';
        next if $name eq 'KATAKANA LETTER SMALL HE';
        next if $name eq 'KATAKANA DIGRAPH KOTO';
        next if $name eq 'KATAKANA LETTER SMALL SU';
        next if $name eq 'KATAKANA LETTER SMALL HO';
        next if $name eq 'KATAKANA LETTER SMALL SI';
        next if $name eq 'KATAKANA LETTER SMALL RI';
        next if $name eq 'KATAKANA LETTER VE';
        next if $name eq 'KATAKANA LETTER SMALL TO';
        next if $name eq 'KATAKANA LETTER SMALL KU';
        next if $name eq 'KATAKANA LETTER VO';
        next if $name eq 'KATAKANA LETTER SMALL RO';
        next if $name eq 'KATAKANA LETTER SMALL RA';
        next if $name eq 'KATAKANA LETTER SMALL MU';
        next if $name eq 'KATAKANA LETTER SMALL HA';
        next if $name eq 'KATAKANA LETTER VI';
        next if $name eq 'KATAKANA LETTER SMALL RU';
        next if $name eq 'KATAKANA LETTER SMALL NU';
        next if $name eq 'KATAKANA MIDDLE DOT';
        next if $name eq 'HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK';
        next if $name eq 'HALFWIDTH KATAKANA VOICED SOUND MARK';
        next if $name eq 'HALFWIDTH KATAKANA MIDDLE DOT';
        if ($name =~ /^(?:HALFWIDTH )?KATAKANA (.+)/) {
            push @katakana2hiragana_k, "\\x{$hex}";
            my $hiragananame = "HIRAGANA $1";
            unless ($n2h{$hiragananame}) {
                warn "$hiragananame\n";
                next;
            }
            push @katakana2hiragana_h, "\\x{$n2h{$hiragananame}}";
        }
    }
    return "tr/", join('', @katakana2hiragana_k), "/", join('', @katakana2hiragana_h), "/";
}

sub katakana_h2z {
    my $c = sub { sprintf "\\x{%X}", unpack 'U*', decode('euc-jp', shift) };

    my @res;

    push @res, sub {
        # dakuten
        my (@h, %h2z);
        while (my ($h, $z) = each %Encode::JP::H2Z::_D2Z) {
            my $hhex = join('', map { sprintf '\x{%X}', unpack 'U*', $_ } split //, decode('euc-jp', $h));
            push @h, $hhex;
            $h2z{$hhex} = $c->($z);
        }
        return join("\n",
            Dumper(\%h2z),
            join('', "s/(", join('|', @h), ')/$h2z{$1}/ge;'),
        );
    }->();

    push @res, sub {
        # normal
        my (@h, @z);
        while (my ($h, $z) = each %Encode::JP::H2Z::_H2Z) {
            push @h, $c->($h);
            push @z, $c->($z);
        }
        return join('', "tr/", join('', @h), "/", join('', @z), "/;");
    }->();

    return join "\n", @res;
}

sub katakana_z2h {
    my $c = sub { sprintf "\\x{%X}", unpack 'U*', decode('euc-jp', shift) };

    my @res;

    push @res, sub {
        # dakuten
        my (@z, %z2h);
        while (my ($h, $z) = each %Encode::JP::H2Z::_D2Z) {
            my $hhex = join('', map { sprintf '\x{%X}', unpack 'U*', $_ } split //, decode('euc-jp', $h));
            push @z, $c->($z);
            $z2h{$c->($z)} = $hhex;
        }
        return join("\n",
            Dumper(\%z2h),
            join('', "s/([", join('', @z), '])/$katakana_z2h_map{$1}/ge;'),
        );
    }->();

    push @res, sub {
        # normal
        my (@h, @z);
        while (my ($h, $z) = each %Encode::JP::H2Z::_H2Z) {
            push @z, $c->($z);
            push @h, $c->($h);
        }
        return join('', "tr/", join('', @z), "/", join('', @h), "/;");
    }->();

    return join "\n", @res;
}

for my $meth (qw/alnum_z2h hiragana2katakana katakana2hiragana katakana_h2z katakana_z2h/) {
    say "-- $meth";
    say sub { goto &{$meth} }->();
}


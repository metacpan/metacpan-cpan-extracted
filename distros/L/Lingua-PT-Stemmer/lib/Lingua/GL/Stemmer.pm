package Lingua::GL::Stemmer;
$Lingua::GL::Stemmer::VERSION = '0.02';
use 5.006;
use strict;
use warnings;
my $aa = "\xe1";
my $ea = "\xe9";
my $ia = "\xed";
my $oa = "\xf3";
my $ua = "\xfa";
my $at = "\xe3";
my $ot = "\xf5";
my $nt = "\xf1";
my $ac = "\xe2";
my $ec = "\xea";
my $cc = "\xe7";
my %rule;

$rule{plural} = {
    "ns"  => [ 1, "n" ],
    "${ot}es" => [ 3, "${ot}n" ],
    "${at}es" => [ 1, "${at}o" ],
    "ais" => [ 1, "al" ],
    "${ea}is" => [ 2, "el" ],
    "eis" => [ 2, "el" ],
    "${oa}is" => [ 2, "ol" ],
    "ois" => [ 2, "ol" ],
    "${ia}s"  => [ 2, "il" ],
    "les" => [ 2, "l" ],
    "res" => [ 3, "r" ],
    "s"   => [ 2, "" ],
};

$rule{femin} = {
    "ona" => [ 3, "${oa}n" ],
    "oa" => [ 3, "${oa}n" ],
    "ora" => [ 3, "or" ],
    "na" => [ 4, "no" ],
    "inha" => [ 3, "inho" ],
    "i${nt}a" => [ 3, "i${nt}o" ],
    "esa" => [ 3, "${ea}s" ],
    "osa" => [ 3, "oso" ],
    "${ia}aca" => [ 3, "${ia}aco" ],
    "ica" => [ 3, "ico" ],
    "ada" => [ 3, "ado" ],
    "ida" => [ 3, "ido" ],
    "${ia}da" => [ 3, "ido" ],
    "ana" => [ 2, "${aa}n" ],
    "${aa}ria" => [ 3, "${aa}rio" ],
    "ima" => [ 3, "imo" ],
    "iva" => [ 3, "ivo" ],
    "eira" => [ 3, "eiro" ],
    "${at}" => [ 2, "${at}o" ],
    "${aa}" => [ 2, "${at}n" ],
};

$rule{augment} = {
    "d${ia}ssimo" => [ 5, '' ],
    "d${ia}simo" => [ 5, '' ],
    "abil${ia}ssimo" => [ 5,'' ],
    "abil${ia}simo" => [ 5,'' ],
    "${ia}ssimo" => [ 3,'' ],
    "${ia}simo" => [ 3,'' ],
    "${ea}simo" => [ 3,'' ],
    "${ea}sima" => [ 3,'' ],
    "${ea}rrimo" => [ 4,'' ],
    "${ea}rrima" => [ 4,'' ],
    "zinho" => [ 2,'' ],
    "ci${nt}o" => [ 2,'' ],
    "a${cc}o" => [ 4, '' ],
    "a${cc}a" => [ 4, '' ],
    "azo" => [ 4, '' ],
    "aza" => [ 4, '' ],
    "ad${at}o" => [ 4, '' ],
    "acho" => [ 2, '' ],
    "acha" => [ 2, '' ],
    "adinho" => [ 3, '' ],
    "adi${nt}o" => [ 3, '' ],
    "alh${aa}m" => [ 4, '' ],
    "alh${at}o" => [ 4, '' ],
    "all${aa}n" => [ 4, '' ],
    "allo" => [ 4, '' ],
    "alla" => [ 4, '' ],
    "z${at}o" => [ 2,'' ],
    "z${oa}n" => [ 2,'' ],
    "zom" => [ 2,'' ],
    "${aa}n" => [ 4, '' ],
    "${oa}n" => [ 3, '' ],
    "${at}o" => [ 3, '' ],
    "arra" => [ 3,'' ],
    "astro" => [ 3,'' ],
    "${aa}zio" => [ 3,'' ],
    "echo" => [ 3,'' ],
    "echa" => [ 3,'' ],
    "edela" => [ 3,'' ],
    "ela" => [ 4,'' ],
    "elo" => [ 4,'' ],
    "eta" => [ 3,'' ],
    "ete" => [ 3,'' ],
    "ica" => [ 3,'' ],
    "id${at}o" => [ 3,'' ],
    "quinho" => [ 4, "c" ],
    "qui${nt}o" => [ 4, "c" ],
    "uinho" => [ 4,'' ],
    "ui${nt}o" => [ 4,'' ],
    "inho" => [ 3,'' ],
    "i${nt}o" => [ 3,'' ],
    "ito" => [ 3, '' ],
    "ocho" => [ 4, '' ],
    "ocha" => [ 4, '' ],
    "oide" => [ 3, '' ],
    "ola" => [ 3, '' ],
    "olo" => [ 3, '' ],
    "ote" => [ 3, '' ],
    "ota" => [ 3, '' ],
    "u${cc}a" => [ 4,'' ],
    "ucha" => [ 3,'' ],
    "ucho" => [ 3,'' ],
    "uco" => [ 4,'' ],
    "uza" => [ 4,'' ],
    "uxa" => [ 3,'' ],
};


$rule{noun} = {
    "abilidade" => [ 5, "" ],
    "${aa}bel" => [ 2, "" ],
    "able" => [ 2, "" ],
    "aci" => [ 3, "" ],
    "a${cc}" => [ 3, "" ],
    "adeiro" => [ 3, "" ],
    "ador" => [ 3, "" ],
    "ado" => [ 2, "" ],
    "agem" => [ 3, "" ],
    "age" => [ 3, "" ],
    "alismo" => [ 4, "" ],
    "al${ia}stico" => [ 3, "" ],
    "alista" => [ 5, "" ],
    "alizado" => [ 4, "" ],
    "alizaci" => [ 5, "" ],
    "aliza${cc}" => [ 5, "" ],
    "alizaz" => [ 5, "" ],
    "al" => [ 4, "" ],
    "ancia" => [ 4, "" ],
    "${aa}ncia" => [ 4, "" ],
    "${ac}ncia" => [ 4, "" ],
    "ano" => [ 4, "" ],
    "ante" => [ 2, "" ],
    "ario" => [ 3, "" ],
    "${aa}rio" => [ 3, "" ],
    "${aa}stico" => [ 4, "" ],
    "ativo" => [ 4, "" ],
    "atizado" => [ 4, "" ],
    "atizaci" => [ 4, "" ],
    "atiza${cc}" => [ 4, "" ],
    "atizaz" => [ 4, "" ],
    "atoria" => [ 5, "" ],
    "at${oa}ria" => [ 5, "" ],
    "atorio" => [ 3, "" ],
    "at${oa}rio" => [ 3, "" ],
    "${aa}utico" => [ 4, "" ],
    "ico" => [ 4, "" ],
    "auta" => [ 5, "" ],
    "${aa}vel" => [ 2, "" ],
    "axe" => [ 3, "" ],
    "az" => [ 3, "" ],
    "bel" => [ 5, "" ],
    "bil" => [ 0, "vel" ],
    "ble" => [ 5, "" ],
    "cionista" => [ 5, "" ],
    "edeiro" => [ 3, "" ],
    "eiro" => [ 3, "" ],
    "edouro" => [ 3, "" ],
    "edor" => [ 3, "" ],
    "dor" => [ 2, "" ],
    "encialista" => [ 4, "" ],
    "encial" => [ 5, "" ],
    "${ec}ncia" => [ 3, "" ],
    "encia" => [ 3, "" ],
    "${ea}ncia" => [ 3, "" ],
    "ense" => [ 3, "" ],
    "ente" => [ 4, "" ],
    "erio" => [ 6, "" ],
    "${ea}rio" => [ 6, "" ],
    "esco" => [ 4, "" ],
    "${ec}utico" => [ 4, "" ],
    "${ea}utico" => [ 4, "" ],
    "eza" => [ 3, "" ],
    "ez" => [ 4, "" ],
    "${ia}aco" => [ 3, "" ],
    "ial" => [ 3, "" ],
    "iamento" => [ 4, "" ],
    "amento" => [ 3, "" ],
    "imento" => [ 3, "" ],
    "emento" => [ 3, "" ],
    "mento" => [ 6, "" ],
    "${ia}bel" => [ 5, "" ],
    "ible" => [ 5, "" ],
    "icionista" => [ 4, "" ],
    "iza${cc}" => [ 5, "" ],
    "izaci" => [ 5, "" ],
    "izaz" => [ 5, "" ],
    "ice" => [ 4, "" ],
    "ici" => [ 3, "" ],
    "i${cc}" => [ 3, "" ],
    "iz" => [ 3, "" ],
    "idade" => [ 4, "" ],
    "ideiro" => [ 3, "" ],
    "ideira" => [ 3, "" ],
    "ido" => [ 3, "" ],
    "idor" => [ 4, "" ],
    "inal" => [ 3, "" ],
    "ional" => [ 4, "" ],
    "ionar" => [ 5, "" ],
    "ionista" => [ 5, "" ],
    "ismo" => [ 3, "" ],
    "ista" => [ 3, "" ],
    "${ia}vel" => [ 5, "" ],
    "ividade" => [ 5, "" ],
    "ivo" => [ 4, "" ],
    "izado" => [ 5, "" ],
    "or" => [ 3, "" ],
    "oria" => [ 3, "" ],
    "or${ia}a" => [ 4, "" ],
    "oso" => [ 3, "" ],
    "queiro" => [ 3, "c" ],
    "quice" => [ 4, "c" ],
    "rio" => [ 5, "" ],
    "sor" => [ 2, "" ],
    "tico" => [ 3, "" ],
    "tivo" => [ 4, "" ],
    "tizado" => [ 4, "" ],
    "tiza${cc}" => [ 5, "" ],
    "tizaci" => [ 5, "" ],
    "tizaz" => [ 5, "" ],
    "tor" => [ 5, "" ],
    "ual" => [ 3, "" ],
    "uoso" => [ 3, "" ],
    "ura" => [ 4, "" ],
    "vel" => [ 5, "" ],
};


$rule{verb} = {
    "aba"  => [ 2, "" ],
    "abade" => [ 2, "" ],
    "${aa}bade" => [ 2, "" ],
    "abamo" => [ 2, "" ],
    "${aa}bamo" => [ 2, "" ],
    "aban" => [ 2, "" ],
    "ache" => [ 2, "" ],
    "ade" => [ 2, "" ],
    "ai" => [ 2, "" ],
    "am" => [ 2, "" ],
    "amo" => [ 2, "" ],
    "an" => [ 2, "" ],
    "ando" => [ 2, "" ],
    "ar" => [ 2, "" ],
    "ara" => [ 2, "" ],
    "ar${aa}" => [ 2, "" ],
    "arade" => [ 2, "" ],
    "${aa}rade" => [ 2, "" ],
    "aram" => [ 2, "" ],
    "ar${aa}m" => [ 2, "" ],
    "aramo" => [ 2, "" ],
    "${aa}ramo" => [ 2, "" ],
    "ar${aa}n" => [ 2, "" ],
    "ar${at}o" => [ 2, "" ],
    "arde" => [ 2, "" ],
    "are" => [ 2, "" ],
    "arei" => [ 2, "" ],
    "${aa}rei" => [ 2, "" ],
    "arem" => [ 2, "" ],
    "aremo" => [ 2, "" ],
    "aria" => [ 2, "" ],
    "ar${ia}a" => [ 2, "" ],
    "ariade" => [ 2, "" ],
    "ar${ia}ade" => [ 2, "" ],
    "ariam" => [ 2, "" ],
    "ariamo" => [ 2, "" ],
    "ar${ia}amo" => [ 2, "" ],
    "ar${ia}ei" => [ 2, "" ],
    "armo" => [ 2, "" ],
    "${aa}rom" => [ 2, "" ],
    "aron" => [ 2, "" ],
    "ase" => [ 2, "" ],
    "asede" => [ 2, "" ],
    "${aa}sede" => [ 2, "" ],
    "asemo" => [ 2, "" ],
    "${aa}semo" => [ 2, "" ],
    "asen" => [ 2, "" ],
    "asse" => [ 2, "" ],
    "${aa}ssei" => [ 2, "" ],
    "assem" => [ 2, "" ],
    "${aa}ssemo" => [ 2, "" ],
    "aste" => [ 2, "" ],
    "ava" => [ 2, "" ],
    "avam" => [ 2, "" ],
    "${aa}vamo" => [ 2, "" ],
    "avan" => [ 2, "" ],
    "${aa}vei" => [ 2, "" ],
    "ear" => [ 4, "" ],
    "ede" => [ 1, "" ],
    "ei" => [ 3, "" ],
    "em" => [ 2, "" ],
    "emo" => [ 2, "" ],
    "en" => [ 2, "" ],
    "endo" => [ 1, "" ],
    "eou" => [ 5, "" ],
    "er" => [ 1, "" ],
    "era" => [ 1, "" ],
    "er${aa}" => [ 1, "" ],
    "erade" => [ 1, "" ],
    "${ea}rade" => [ 1, "" ],
    "eram" => [ 1, "" ],
    "er${aa}m" => [ 1, "" ],
    "eramo" => [ 1, "" ],
    "${ea}ramo" => [ 1, "" ],
    "${ec}ramo" => [ 1, "" ],
    "er${aa}n" => [ 1, "" ],
    "er${at}o" => [ 1, "" ],
    "erde" => [ 1, "" ],
    "ere" => [ 1, "" ],
    "erei" => [ 1, "" ],
    "${ec}rei" => [ 1, "" ],
    "erem" => [ 1, "" ],
    "eremo" => [ 1, "" ],
    "eria" => [ 1, "" ],
    "er${ia}a" => [ 1, "" ],
    "eriade" => [ 1, "" ],
    "er${ia}ade" => [ 1, "" ],
    "eriam" => [ 1, "" ],
    "eriamo" => [ 1, "" ],
    "er${ia}amo" => [ 1, "" ],
    "erian" => [ 1, "" ],
    "er${ia}an" => [ 1, "" ],
    "er${ia}ei" => [ 1, "" ],
    "ermo" => [ 1, "" ],
    "${ec}rom" => [ 1, "" ],
    "eron" => [ 1, "" ],
    "ese" => [ 1, "" ],
    "esedes" => [ 1, "" ],
    "${ea}sedes" => [ 1, "" ],
    "esemo" => [ 1, "" ],
    "${ea}semo" => [ 1, "" ],
    "esen" => [ 1, "" ],
    "esse" => [ 1, "" ],
    "${ec}ssede" => [ 1, "" ],
    "${ec}ssei" => [ 1, "" ],
    "essem" => [ 1, "" ],
    "${ec}ssemo" => [ 1, "" ],
    "este" => [ 1, "" ],
    "eu" => [ 1, "" ],
    "guem" => [ 1, "g" ],
    "i" => [ 1, "" ],
    "ia" => [ 1, "" ],
    "${ia}a" => [ 1, "" ],
    "iade" => [ 1, "" ],
    "${ia}ade" => [ 1, "" ],
    "iam" => [ 1, "" ],
    "iamo" => [ 1, "" ],
    "${ia}amo" => [ 1, "" ],
    "ian" => [ 1, "" ],
    "${ia}an" => [ 1, "" ],
    "iava" => [ 1, "" ],
    "iche" => [ 1, "" ],
    "ide" => [ 1, "" ],
    "${ia}do" => [ 3, "" ],
    "${ia}ei" => [ 1, "" ],
    "im" => [ 1, "" ],
    "imo" => [ 3, "" ],
    "imo" => [ 3, "" ],
    "in" => [ 3, "" ],
    "indo" => [ 3, "" ],
    "iona" => [ 3, "" ],
    "ir" => [ 3, "" ],
    "ira" => [ 3, "" ],
    "ir${aa}" => [ 3, "" ],
    "irade" => [ 3, "" ],
    "${ia}rade" => [ 3, "" ],
    "iram" => [ 3, "" ],
    "ir${aa}m" => [ 3, "" ],
    "${ia}ram" => [ 3, "" ],
    "iramo" => [ 3, "" ],
    "${ia}ramo" => [ 3, "" ],
    "ir${aa}n" => [ 3, "" ],
    "ir${at}o" => [ 2, "" ],
    "irde" => [ 2, "" ],
    "ire" => [ 3, "" ],
    "irei" => [ 3, "" ],
    "irem" => [ 3, "" ],
    "iremo" => [ 3, "" ],
    "iria" => [ 3, "" ],
    "ir${ia}a" => [ 3, "" ],
    "iriade" => [ 3, "" ],
    "ir${ia}ade" => [ 3, "" ],
    "iriam" => [ 3, "" ],
    "iriamo" => [ 3, "" ],
    "ir${ia}amo" => [ 3, "" ],
    "irian" => [ 3, "" ],
    "ir${ia}an" => [ 3, "" ],
    "ir${ia}ei" => [ 3, "" ],
    "irmo" => [ 3, "" ],
    "${ia}rom" => [ 3, "" ],
    "iron" => [ 3, "" ],
    "ise" => [ 3, "" ],
    "isede" => [ 3, "" ],
    "${ia}sede" => [ 3, "" ],
    "isemo" => [ 3, "" ],
    "${ia}semo" => [ 3, "" ],
    "isen" => [ 3, "" ],
    "isse" => [ 3, "" ],
    "${ia}ssede" => [ 3, "" ],
    "${ia}ssei" => [ 3, "" ],
    "issem" => [ 3, "" ],
    "${ia}ssemo" => [ 3, "" ],
    "iste" => [ 4, "" ],
    "itar" => [ 5, "" ],
    "iu" => [ 3, "" ],
    "izar" => [ 3, "" ],
    "omo" => [ 3, "" ],
    "ondo" => [ 3, "" ],
    "ou" => [ 3, "" ],
    "tizar" => [ 4, "" ],
    "uei" => [ 3, "" ],
    "u${ia}a" => [ 5, "u" ],
};

$rule{accent} = {
    $aa => 'a',
    $ea => 'e',
    $ia => 'i',
    $oa => 'o',
    $ua => 'u',
    $at => 'a',
    $ot => 'o',
    $ec => 'e',
    $cc => 'c',
    $nt => 'n',
};

$rule{vowel} = {
    "bil" => [ 2, "vel" ],
    "gue" => [ 2, "g" ],
    "a" => [ 3, "" ],
    "e" => [ 3, "" ],
    "o" => [ 3, "" ],
};

sub strip($$) {
    my $cmd = shift;
    my $word = shift;
    if($cmd eq 'accent'){
        foreach my $a (keys %{$rule{accent}}){
            $word =~ s/$a/$rule{accent}->{$a}/eg;
        }
    }
    elsif($cmd eq 'adv'){       $word =~ s/(.{4,})mente/$1/o;    }
    else{
        my $cmdref = $rule{$cmd};
        for my $key (sort { length $b <=> length $a } keys %{$cmdref}){
            my $patt = join q//, "^(.{", $cmdref->{$key}->[0], ",})", $key, '$';
            if($word =~ /$patt/){
              $word =~ s/$patt/$1.($cmdref->{$key}->[1])/e;
              last;
            }
        }
    }
    return $word;
}


sub stem {
    my @stems;
    foreach ( ref($_[0]) ? @{$_[0]} : @_ ){
        my $word = $_;
        $word = strip('plural', $word) if $word =~ /s$/o;
        $word = strip('femin', $word) if $word =~ /a$/o;
        foreach my $op (qw/augment adv noun verb vowel accent/){
            $word = strip($op, $word);
        }
        push @stems, $word;
    }
    wantarray ? @stems : \@stems;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::GL::Stemmer - Galician Stemmer

=head1 SYNOPSIS

  use Lingua::GL::Stemmer;

  Lingua::GL::Stemmer::stem(\@words);

  # or

  Lingua::GL::Stemmer::stem(@words);

=head1 DESCRIPTION

Galician is an endangered language spoken in northwest region of Spain. Galician is morphologically similar to Portuguese but phonetics differs greatly. Due to the morphological similarity between Portuguese and Galician, Portuguese stemming algorithm can be adopted to stem Galician texts.

See L<Lingua::PT::Stemmer> for a sketch of the stemming algorithm, and L<http://bvg.udc.es/recursos_lingua/stemming.html> for stemming rules.

=head1 SEE ALSO

L<Lingua::PT::Stemmer>

Stemming rules
L<http://bvg.udc.es/recursos_lingua/stemming.html>

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut

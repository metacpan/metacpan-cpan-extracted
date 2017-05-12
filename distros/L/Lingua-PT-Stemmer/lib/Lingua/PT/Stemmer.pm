package Lingua::PT::Stemmer;
$Lingua::PT::Stemmer::VERSION = '0.02';
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
my $ac = "\xe2";
my $ec = "\xea";
my $cc = "\xe7";
my %rule;

$rule{plural} = {
    "ns"  => [ 1, "m" ],
    "${ot}es" => [ 3, "${at}o" ],
    "${at}es" => [ 1, "${at}o" ],
    "ais" => [ 1, "al" ],
    "${ea}is" => [ 2, "el" ],
    "eis" => [ 2, "el" ],
    "${oa}is" => [ 2, "ol" ],
    "is"  => [ 2, "il" ],
    "les" => [ 2, "l" ],
    "res" => [ 3, "r" ],
    "s"   => [ 2, "" ],
};

$rule{femin} = {
    "ona" => [ 3, "${at}o" ],
    "${at}" => [ 2, "${at}o" ],
    "ora" => [ 3, "or" ],
    "na" => [ 4, "no" ],
    "inha" => [ 3, "inho" ],
    "esa" => [ 3, "${ec}s" ],
    "osa" => [ 3, "oso" ],
    "${ia}aca" => [ 3, "${ia}aco" ],
    "ica" => [ 3, "ico" ],
    "ada" => [ 3, "ado" ],
    "ida" => [ 3, "ido" ],
    "${ia}da" => [ 3, "ido" ],
    "ima" => [ 3, "imo" ],
    "iva" => [ 3, "ivo" ],
    "eira" => [ 3, "eiro" ],
};

$rule{augment} = {
    "d${ia}ssimo" => [ 5, '' ],
    "abil${ia}ssimo" => [ 5,'' ],
    "${ia}ssimo" => [ 3,'' ],
    "${ea}simo" => [ 3,'' ],
    "${ea}rrimo" => [ 4,'' ],
    "zinho" => [ 2,'' ],
    "quinho" => [ 4, "c" ],
    "uinho" => [ 4,'' ],
    "adinho" => [ 3,'' ],
    "inho" => [ 3,'' ],
    "alh${at}o" => [ 4,'' ],
    "u${cc}a" => [ 4,'' ],
    "a${cc}o" => [ 4,'' ],
    "ad${at}o" => [ 4,'' ],
    "${aa}zio" => [ 3,'' ],
    "arraz" => [ 4,'' ],
    "arra" => [ 3,'' ],
    "z${at}o" => [ 2,'' ],
    "${at}o" => [ 3,'' ],
};


$rule{noun} = {
    "encialista" => [ 4, '' ],
    "alista" => [ 5, '' ],
    "agem" => [ 3, '' ],
    "iamento" => [ 4, '' ],
    "amento" => [ 3, '' ],
    "imento" => [ 3, '' ],
    "alizado" => [ 4, '' ],
    "atizado" => [ 4, '' ],
    "izado" => [ 5, '' ],
    "ativo" => [ 4, '' ],
    "tivo" => [ 4, '' ],
    "ivo" => [ 4, '' ],
    "ado" => [ 2, '' ],
    "ido" => [ 3, '' ],
    "ador" => [ 3,'' ],
    "edor" => [ 3, '' ],
    "idor" => [ 4, '' ],
    "at${oa}ria" => [ 5, '' ],
    "or" => [ 2, '' ],
    "abilidade" => [ 5,'' ],
    "icionista" => [ 4, '' ],
    "cionista" => [ 5, '' ],
    "ional" => [ 4, '' ],
    "${ec}ncia" => [ 3, '' ],
    "${ac}ncia" => [ 4, '' ],
    "edouro" => [ 3, '' ],
    "queiro" => [ 3, 'c' ],
    "eiro" => [ 3, '' ],
    "oso" => [ 3, '' ],
    "aliza${cc}" => [ 5, '' ],
    "ismo" => [ 3, '' ],
    "iza${cc}" => [ 5, '' ],
    "a${cc}" => [ 3, '' ],
    "i${cc}" => [ 3, '' ],
    "${aa}rio" => [ 3, '' ],
    "${ea}rio" => [ 6, '' ],
    "${ec}s" => [ 4, '' ],
    "eza" => [ 3, '' ],
    "ez" => [ 4, '' ],
    "esco" => [ 4, '' ],
    "ante" => [ 2, '' ],
    "${aa}stico" => [ 4, '' ],
    "${aa}tico" => [ 3, '' ],
    "ico" => [ 4, '' ],
    "ividade" => [ 5, '' ],
    "idade" => [ 5, '' ],
    "oria" => [ 4, '' ],
    "encial" => [ 5, '' ],
    "ista" => [ 4, '' ],
    "quice" => [ 4, 'c' ],
    "ice" => [ 4, '' ],
    "${ia}aco" => [ 3, '' ],
    "ente" => [ 4, '' ],
    "inal" => [ 3, '' ],
    "ano" => [ 4, '' ],
    "${aa}vel" => [ 2, '' ],
    "${ia}vel" => [ 5, '' ],
    "ura" => [ 4, '' ],
    "ual" => [ 3, '' ],
    "ial" => [ 3, '' ],
    "al" => [ 4, '' ],
};


$rule{verb} = {
    "ar${ia}amo" => [ 2, ''],
    "eria" => [ 3, '' ],
    "${aa}ssemo" => [ 2, '' ],
    "ermo" => [ 3, '' ],
    "er${ia}amo" => [ 2, '' ],
    "esse" => [ 3, '' ],
    "${ec}ssemo" => [ 2, '' ],
    "este" => [ 3, '' ],
    "ir${ia}amo" => [ 3, '' ],
    "${ia}amo" => [ 3, '' ],
    "${ia}ssemo" => [ 3, '' ],
    "iram" => [ 3, '' ],
    "${aa}ramo" => [ 2, '' ],
    "${ia}ram" => [ 3, '' ],
    "${aa}rei" => [ 2, '' ],
    "irde" => [ 2, '' ],
    "aremo" => [ 2, '' ],
    "irei" => [ 3, '' ],
    "ariam" => [ 2, '' ],
    "irem" => [ 3, '' ],
    "ar${ia}ei" => [ 2, '' ],
    "iria" => [ 3, '' ],
    "${aa}ssei" => [ 2, '' ],
    "irmo" => [ 3, '' ],
    "assem" => [ 2, '' ],
    "isse" => [ 3, '' ],
    "${aa}vamo" => [ 2, '' ],
    "iste" => [ 4, '' ],
    "${ec}ramo" => [ 3, '' ],
    "amo" => [ 2, '' ],
    "eremo" => [ 3, '' ],
    "ara" => [ 2, '' ],
    "eriam" => [ 3, '' ],
    "ar${aa}" => [ 2, '' ],
    "er${ia}ei" => [ 3, '' ],
    "are" => [ 2, '' ],
    "${ec}ssei" => [ 3, '' ],
    "ava" => [ 2, '' ],
    "essem" => [ 3, '' ],
    "emo" => [ 2, '' ],
    "${ia}ramo" => [ 3, '' ],
    "era" => [ 3, '' ],
    "iremo" => [ 3, '' ],
    "er${aa}" => [ 3, '' ],
    "iriam" => [ 3, '' ],
    "ere" => [ 3, '' ],
    "ir${ia}ei" => [ 3, '' ],
    "iam" => [ 3, '' ],
    "${ia}ssei" => [ 3, '' ],
    "${ia}ei" => [ 3, '' ],
    "issem" => [ 3, '' ],
    "imo" => [ 3, '' ],
    "ando" => [ 2, '' ],
    "ira" => [ 3, '' ],
    "endo" => [ 3, '' ],
    "ir${aa}" => [ 3, '' ],
    "indo" => [ 3, '' ],
    "ire" => [ 3, '' ],
    "ondo" => [ 3, '' ],
    "omo" => [ 3, '' ],
    "aram" => [ 2, '' ],
    "ai" => [ 2, '' ],
    "arde" => [ 2, '' ],
    "am" => [ 2, '' ],
    "arei" => [ 2, '' ],
    "ear" => [ 4, '' ],
    "arem" => [ 2, '' ],
    "ar" => [ 2, '' ],
    "aria" => [ 2, '' ],
    "uei" => [ 3, '' ],
    "armo" => [ 2, '' ],
    "ei" => [ 3, '' ],
    "asse" => [ 2, '' ],
    "em" => [ 2, '' ],
    "aste" => [ 2, '' ],
    "er" => [ 2, '' ],
    "avam" => [ 2, '' ],
    "eu" => [ 3, '' ],
    "${aa}vei" => [ 2, '' ],
    "ia" => [ 3, '' ],
    "eram" => [ 3, '' ],
    "ir" => [ 3, '' ],
    "erde" => [ 3, '' ],
    "iu" => [ 3, '' ],
    "erei" => [ 3, '' ],
    "ou" => [ 3, '' ],
    "${ec}rei" => [ 3, '' ],
    "i" => [ 3, '' ],
    "erem" => [ 3, '' ],
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
};

sub strip($$) {
    my $cmd = shift;
    my $word = shift;
    if($cmd eq 'accent'){
	foreach my $a (keys %{$rule{accent}}){
	    $word =~ s/$a/$rule{accent}->{$a}/eg;
	}
    }
    elsif($cmd eq 'adv'){	$word =~ s/(.{4,})mente/$1/o;    }
    elsif($cmd eq 'vowel'){	$word =~ s/(.{3,})$_$/$1/ for qw/a e o/;   }
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

Lingua::PT::Stemmer - Portuguese language stemming

=head1 SYNOPSIS

  use Lingua::PT::Stemmer;

  Lingua::PT::Stemmer::stem(\@words);

  # or

  Lingua::PT::Stemmer::stem(@words);

=head1 DESCRIPTION

This module implements a Portuguese stemming algorithm proposed in the paper B<A Stemming Algorithm for the Portuguese Language> by B<Moreira, V.> and B<Huyck, C.>

The eight steps of stemming algorithm are listed as follows:

=over 8

=item * Plural Reduction

=item * Feminine Reduction

=item * Adverb Reduction

=item * Augmentative/Diminutive Reduction

=item * Noun Suffix Reduction

=item * Verb Suffix Reduction

=item * Vowel Reduction

=item * Accents Removal

=back

=head1 SEE ALSO

L<Lingua::GL::Stemmer>

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut

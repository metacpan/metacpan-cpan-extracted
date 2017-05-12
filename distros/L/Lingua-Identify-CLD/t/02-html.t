#!perl -T

use utf8;

use Test::More;

use Lingua::Identify::CLD;

my %langs = (
             PORTUGUESE => q{<poem><line>As <word type="other">armas</word> e os <word>barões</word> assinalados,</line><line> que da <word comment="means occidental">ocidental</word> <word class="something">praia</word> lusitana,</line><line>por mares <div note="This is the same as never">nunca</div> de antes navegados</line><line> passaram ainda além da traprobana</line></poem>},
            );

plan tests => scalar(keys %langs);

my $cld = Lingua::Identify::CLD->new();
for my $lang (keys %langs) {
    is $cld->identify($langs{$lang}, isPlainText => 0), $lang, "Identifying $lang";
}

use strict;
use warnings;
use Test::More;

use HTTP::AcceptLanguage;

plan skip_all => '$ENV{HTTP_ACCEPT_LANGUAGE_IANA} is undefine' unless $ENV{HTTP_ACCEPT_LANGUAGE_IANA};

require HTTP::Tiny;

my $res = HTTP::Tiny->new->get('http://www.iana.org/assignments/language-subtag-registry');
die 'Failed!' unless $res->{success};
die 'Failed!' unless $res->{content};

ok 1;
for my $line (split /\n/, $res->{content}) {
    chomp $line;
    next unless $line =~ /\A(?:Subtag|Tag): (.+)\z/;
    my $tag = $1;
    next if $tag =~ /\.\./; # skip to range registry

    my $parser    = HTTP::AcceptLanguage->new($tag);
    my @languages = $parser->languages;
    unless (scalar(@languages) == 1 && $languages[0] eq $tag) {
        ok 0, $tag;
    }
}

done_testing;

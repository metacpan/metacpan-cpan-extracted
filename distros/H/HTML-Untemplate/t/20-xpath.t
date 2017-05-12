#!perl
use strict;
use utf8;
use warnings qw(all);

use Set::CrossProduct;
use FindBin qw($Bin);
use HTML::TreeBuilder::XPath;
use Path::Class;
use Test::More;

use_ok(q(HTML::Linear));

my $iterator = Set::CrossProduct->new([
    [qw[test.html cpan.html perl.html]],
    [qw[set_strict unset_strict]],
    [qw[set_shrink unset_shrink]],
]);

my $m = 1;
for my $tuple ($iterator->combinations) {
    my $file = q...file($Bin, shift @{$tuple});

    #next if $tuple->[0] eq q(unset_strict);
    subtest $file => sub {
        my $xpath = HTML::TreeBuilder::XPath->new;
        isa_ok($xpath, q(HTML::TreeBuilder::XPath));
        can_ok($xpath, qw(parse_file findvalue));
        ok($xpath->parse_file($file), q(HTML::TreeBuilder::XPath::parse_file));

        my $n = 3;

        my $hl = HTML::Linear->new;
        for my $opt (@{$tuple}) {
            diag($opt . q(()));
            $hl->$opt();
        }

        ok($hl->parse_file($file), q(HTML::Linear::parse_file));
        ++$n;

        my %hash;
        for my $el ($hl->as_list) {
            my $hash = $el->as_hash;
            for (keys %{$hash}) {
                if (m{/text\(\)$}sx) {
                    $hash{$_} .= $hash->{$_};
                } else {
                    $hash{$_} = $hash->{$_};
                }
            }
        }

        for my $expr (keys %hash) {
            my $content = $hash{$expr};
            $content =~ s/^\s+|\s+$//gsx;
            $content =~ s/\s+/ /gsx;

            my $value = $xpath->findvalue($expr);
            $value =~ s/^\s+|\s+$//gsx;
            $value =~ s/\s+/ /gsx;

            ok(
                $value eq $content,
                qq(\n$expr\n"$value"\n"$content"),
            );

            ++$n;
        }

        done_testing($n);
    };
    ++$m;
}

done_testing($m);

use strict;
use warnings;
use utf8;
use Benchmark;
use Encode     qw(_utf8_off);
use URI::Fast  ();

=pod
Check which way we can convert utf8 chars to hex encoding fastest, for
absolute_url.
=cut

my $str = '2021年07月12日' x 5;   # not too many weird chars in a url

my %to_hex = map +(chr($_) => sprintf("%%%02X", $_)), 0..255;

timethese(
    10_000_000,
    +{
        # mimimal time it takes to get to the character to be modified
        BARE => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b); $b!ge;
        },
        BARE2 => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; _utf8_off($b); $b!ge;
        },
        BARE3 => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!_utf8_off($1); $1!ge;
        },
        UNPACK => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b); unpack('H*', $b) =~ s/(..)/%\U$1/gr!ge;
        },
        SPRINTF => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b);
                 join '', map sprintf("%%%02X", ord), split //, $b!ge;
        },
        URIFAST => sub {
            URI::Fast::encode($str);
        },
        MIX => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b);
                 join '%', '', map pack('H2', $_), split //, $b!ge;
        },
        TABLE => sub {
            my $b;
            $str =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b);
                 join '', map $to_hex{$_}, split //, $b!ge;
        }
     }
);


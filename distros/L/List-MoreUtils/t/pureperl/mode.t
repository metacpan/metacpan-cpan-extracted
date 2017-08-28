#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my $lorem =
      "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.";
    my @lorem = grep { $_ } split /(?:\b|\s)/, $lorem;
    my $fl = freeze(\@lorem);

    my $n_comma = scalar(split /,/, $lorem) - 1;

    my @m = mode @lorem;
    is($fl, freeze(\@lorem), "mode:G_ARRAY lorem untouched");
    is_deeply([$n_comma, ','], \@m, "lorem mode as list");
    my $m = mode @lorem;
    is($fl, freeze(\@lorem), "mode:G_SCALAR lorem untouched");
    is($n_comma, $m, "lorem mode as scalar");
}

SCOPE:
{
    my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
    my $fp     = freeze(\@probes);
    my @m      = mode @probes;
    is($fp, freeze(\@probes), "mode:G_ARRAY probes untouched");
    is_deeply([7, 4], \@m, "unimodal result in list context");
    my $m = mode @probes;
    is($fp, freeze(\@probes), "mode:G_SCALAR probes untouched");
    is(7, $m, "unimodal result in scalar context");
}

SCOPE:
{
    my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4, (7) x 3, (8) x 7);
    my $fp     = freeze(\@probes);
    my @m      = mode @probes;
    is($fp, freeze(\@probes), "bimodal mode:G_ARRAY probes untouched");
    my $m = shift @m;
    @m = sort @m;
    unshift @m, $m;
    is_deeply([7, 4, 8], \@m, "bimodal result in list context");
    $m = mode @probes;
    is($fp, freeze(\@probes), "bimodal mode:G_SCALAR probes untouched");
    is(7, $m, "bimodal result in scalar context");
}

SCOPE:
{
    my %radio_ukw_nrw = (
        "87,6"  => "WDR Eins Live",
        "87,7"  => "WDR 5",
        "87,7"  => "Welle Niederrhein",
        "87,7"  => "WDR 5",
        "87,8"  => "Welle West",
        "87,8"  => "WDR 4",
        "87,8"  => "WDR 2 Dortmund",
        "87,9"  => "Radio HERTZ",
        "88,0"  => "WDR 5",
        "88,1"  => "Radio Hochstift",
        "88,2"  => "Radio Kiepenkerl",
        "88,2"  => "Radio Siegen",
        "88,3"  => "WDR 5",
        "88,3"  => "Radio MK",
        "88,4"  => "WDR 2 Köln",
        "88,4"  => "Radio WMW",
        "88,4"  => "WDR 5",
        "88,5"  => "WDR 5",
        "88,5"  => "Werrepark Radio",
        "88,5"  => "WDR 5",
        "88,6"  => "WDR 5",
        "88,7"  => "WDR 3",
        "88,8"  => "WDR 5",
        "88,9"  => "Deutschlandradio Kultur",
        "89,0"  => "Lokalradio Olpe",
        "89,1"  => "Deutschlandfunk (DLF)",
        "89,1"  => "Radio Sauerland",
        "89,2"  => "WDR (Test)",
        "89,3"  => "Antenne Unna",
        "89,4"  => "NE-WS 89,4",
        "89,4"  => "L`UniCo FM",
        "89,6"  => "WDR 5",
        "89,7"  => "WDR 3",
        "90,0"  => "CT das radio",
        "90,0"  => "WDR 5",
        "90,1"  => "WDR 4",
        "90,1"  => "Deutschlandradio Kultur",
        "90,1"  => "Radio 90,1",
        "90,3"  => "WDR 5",
        "90,6"  => "WDR 5",
        "90,7"  => "WDR 4",
        "90,8"  => "Radio Herne",
        "90,8"  => "Radio MK",
        "90,9"  => "Radio Q",
        "91,0"  => "Deutschlandradio Kultur",
        "91,0"  => "Deutschlandfunk (DLF)",
        "91,2"  => "WDR (Test)",
        "91,2"  => "Radio 91,2",
        "91,2"  => "Radio Bonn/Rhein-Sieg",
        "91,3"  => "Radio Lippe (geplant)",
        "91,3"  => "Deutschlandfunk (DLF)",
        "91,3"  => "BFBS Radio 1",
        "91,4"  => "Radio Erft",
        "91,5"  => "Radio MK",
        "91,5"  => "Deutschlandfunk (DLF)",
        "91,5"  => "Radio Ennepe Ruhr",
        "91,7"  => "WDR 4",
        "91,7"  => "BFBS Radio 2",
        "91,7"  => "WDR 3",
        "91,7"  => "Radio K.W.",
        "91,7"  => "Radio Herford",
        "91,8"  => "WDR 2 Wuppertal",
        "91,8"  => "WDR 2 Bielefeld",
        "91,9"  => "WDR 4",
        "92,0"  => "WDR 5",
        "92,0"  => "domradio",
        "92,1"  => "Radius 92,1",
        "92,2"  => "Radio Duisburg",
        "92,2"  => "Deutschlandfunk (DLF)",
        "92,2"  => "Radio RSG",
        "92,3"  => "WDR 2 Siegen",
        "92,5"  => "BFBS Radio 1",
        "92,5"  => "Radio MK",
        "92,6"  => "Radio WAF",
        "92,7"  => "WDR 3",
        "92,7"  => "Radio Rur",
        "92,7"  => "Radio Ennepe Ruhr",
        "92,9"  => "Radio Mülheim",
        "93,0"  => "Radio WMW",
        "93,0"  => "elDOradio",
        "93,1"  => "WDR 3",
        "93,2"  => "WDR 2 Bielefeld",
        "93,3"  => "WDR 2 Rhein-Ruhr",
        "93,5"  => "WDR 2 Siegen",
        "93,6"  => "WDR Eins Live",
        "93,7"  => "Radio Hochstift",
        "93,8"  => "WDR 2 Siegen",
        "93,9"  => "WDR 4",
        "93,9"  => "Deutschlandfunk (DLF)",
        "93,9"  => "WDR 5",
        "94,1"  => "WDR 2 Münster",
        "94,2"  => "Radio Bonn/Rhein-Sieg",
        "94,2"  => "WDR 2 Aachen",
        "94,2"  => "Deutschlandfunk (DLF)",
        "94,3"  => "Antenne Bethel",
        "94,3"  => "Radio RSG",
        "94,3"  => "WDR 3",
        "94,5"  => "Deutschlandfunk (DLF)",
        "94,6"  => "Radio MK",
        "94,6"  => "Test FM",
        "94,6"  => "Deutschlandradio Kultur",
        "94,6"  => "Radio Vest",
        "94,7"  => "Radio FH",
        "94,7"  => "Radio WAF",
        "94,8"  => "WDR (Test)",
        "94,8"  => "Radio Sauerland",
        "94,9"  => "Radio Herford",
        "95,1"  => "WDR 3",
        "95,1"  => "Radio Westfalica",
        "95,2"  => "WDR 3",
        "95,4"  => "Antenne Münster",
        "95,5"  => "Deutschlandfunk (DLF)",
        "95,6"  => "Radio Vest",
        "95,7"  => "Radio WAF",
        "95,7"  => "Radio Westfalica",
        "95,7"  => "WDR 2 Wuppertal",
        "95,8"  => "WDR 5",
        "95,9"  => "WDR 3",
        "95,9"  => "Triquency",
        "95,9"  => "Radio Gütersloh",
        "96,0"  => "WDR Eins Live",
        "96,0"  => "WDR 2 Münster",
        "96,0"  => "WDR 2 Bielefeld",
        "96,1"  => "Radio Emscher Lippe",
        "96,1"  => "WDR 4",
        "96,1"  => "Triquency",
        "96,2"  => "Radio Sauerland",
        "96,3"  => "WDR 3",
        "96,3"  => "Radio WAF",
        "96,3"  => "Deutschlandradio Kultur",
        "96,4"  => "Radio Siegen (geplant)",
        "96,4"  => "WDR 2 Bielefeld",
        "96,5"  => "Deutschlandradio Kultur",
        "96,8"  => "bonn FM",
        "96,9"  => "Deutschlandradio Kultur",
        "96,9"  => "Radio Berg",
        "97,0"  => "WDR 3",
        "97,1"  => "Antenne GL",
        "97,1"  => "Hochschulradio Düsseldorf",
        "97,1"  => "WDR 2 Siegen",
        "97,2"  => "107.8 Antenne AC",
        "97,2"  => "Radio MK",
        "97,3"  => "Radio Siegen",
        "97,3"  => "WDR 3",
        "97,3"  => "WDR 3",
        "97,4"  => "Antenne Unna",
        "97,5"  => "WDR 3",
        "97,5"  => "Deutschlandradio Kultur",
        "97,6"  => "Radio WMW",
        "97,6"  => "WDR (Test)",
        "97,6"  => "Radio Bielefeld",
        "97,6"  => "Radio Neandertal",
        "97,6"  => "WDR 5",
        "97,7"  => "Deutschlandradio Kultur",
        "97,8"  => "Radio Bonn/Rhein-Sieg",
        "97,8"  => "WDR 3",
        "98,0"  => "Antenne Niederrhein",
        "98,1"  => "WDR 3",
        "98,2"  => "WDR 3",
        "98,2"  => "WDR Eins Live",
        "98,3"  => "Radio Bielefeld",
        "98,4"  => "WDR 3",
        "98,5"  => "Radio Bochum",
        "98,6"  => "WDR 2 + Messeradio Köln",
        "98,6"  => "WDR 5",
        "98,7"  => "Radio Emscher Lippe",
        "98,9"  => "Deutschlandradio Kultur",
        "98,9"  => "Lokalradio Olpe",
        "98,9"  => "Radio Siegen",
        "99,1"  => "Hochschulradio Aachen",
        "99,1"  => "WDR 2 Bielefeld",
        "99,2"  => "WDR 2 Rhein-Ruhr",
        "99,4"  => "WDR 2 Siegen",
        "99,4"  => "Triquency",
        "99,5"  => "WDR 4",
        "99,5"  => "Radio MK",
        "99,6"  => "WDR 4",
        "99,7"  => "Radio Euskirchen",
        "99,7"  => "WDR 5",
        "99,7"  => "Radio Berg",
        "99,7"  => "WDR Eins Live",
        "99,8"  => "WDR 2 Wuppertal",
        "99,9"  => "Radio Bonn/Rhein-Sieg",
        "100,0" => "Kölncampus",
        "100,0" => "WDR 4",
        "100,1" => "107.8 Antenne AC",
        "100,1" => "WDR Eins Live",
        "100,2" => "Radio MK",
        "100,2" => "Deutschlandradio Kultur",
        "100,4" => "WDR 2 Köln",
        "100,5" => "WDR 4",
        "100,6" => "Welle Niederrhein",
        "100,7" => "WDR 4",
        "100,8" => "WDR 2 Aachen",
        "100,9" => "Hellweg Radio",
        "101,0" => "WDR 2 Aachen",
        "101,0" => "Radio Lippe",
        "101,1" => "WDR 4",
        "101,1" => "Deutschlandradio Kultur",
        "101,2" => "WDR 4",
        "101,3" => "WDR 4",
        "101,6" => "BFBS Radio 2",
        "101,7" => "WDR 4",
        "101,7" => "domradio",
        "101,8" => "WDR 2 Siegen",
        "101,9" => "WDR 5",
        "101,9" => "BFBS Radio 1",
        "102,1" => "NE-WS 89,4",
        "102,1" => "WDR 2 Siegen",
        "102,2" => "Radio Essen",
        "102,2" => "BFBS Radio 2",
        "102,3" => "Antenne Unna",
        "102,4" => "WDR Eins Live",
        "102,5" => "WDR Eins Live",
        "102,7" => "Deutschlandfunk (DLF)",
        "102,7" => "Deutschlandfunk (DLF)",
        "102,8" => "Deutschlandfunk (DLF)",
        "103,0" => "BFBS Radio 1",
        "103,3" => "Funkhaus Europa",
        "103,6" => "Radio WMW",
        "103,6" => "Hellweg Radio",
        "103,7" => "WDR Eins Live",
        "103,8" => "WDR 4",
        "103,9" => "Radio Q",
        "104,0" => "BFBS Radio 1",
        "104,0" => "Radio RST",
        "104,1" => "WDR 4",
        "104,2" => "Radio Bonn/Rhein-Sieg",
        "104,2" => "Antenne Düsseldorf",
        "104,2" => "Radio Ennepe Ruhr",
        "104,3" => "BFBS Radio 2",
        "104,4" => "WDR 4",
        "104,4" => "Deutschlandfunk (DLF)",
        "104,5" => "CampusFM",
        "104,5" => "Deutschlandfunk (DLF)",
        "104,5" => "WDR 4",
        "104,7" => "WDR Eins Live",
        "104,8" => "Radio Hochstift",
        "104,8" => "Radio Hochstift",
        "104,9" => "Radio Sauerland",
        "105,0" => "Radio Essen",
        "105,0" => "Radio Lippe Welle Hamm",
        "105,0" => "107.8 Antenne AC",
        "105,0" => "BFBS Radio 2",
        "105,1" => "BFBS Radio 1",
        "105,2" => "Radio Vest",
        "105,2" => "Radio Berg",
        "105,2" => "Radio RST",
        "105,4" => "Radio Siegen",
        "105,5" => "WDR Eins Live",
        "105,5" => "WDR Eins Live",
        "105,6" => "CampusFM",
        "105,7" => "Antenne Niederrhein",
        "105,7" => "Radio Ennepe Ruhr",
        "105,7" => "WDR Eins Live",
        "105,7" => "Radio Berg",
        "105,8" => "Radio Erft",
        "106,0" => "BFBS Radio 1",
        "106,1" => "Deutschlandradio Kultur",
        "106,1" => "Deutschlandradio Kultur",
        "106,2" => "Deutschlandradio Kultur",
        "106,2" => "106.2 Radio Oberhausen",
        "106,3" => "Radio Kiepenkerl",
        "106,4" => "WDR Eins Live",
        "106,5" => "Radio Sauerland",
        "106,5" => "Radio Sauerland",
        "106,5" => "Radio St. Laurentius",
        "106,6" => "Radio Lippe",
        "106,6" => "Radio Westfalica",
        "106,6" => "Deutschlandfunk (DLF)",
        "106,7" => "WDR Eins Live",
        "106,8" => "Radio Gütersloh",
        "106,9" => "Radio Euskirchen",
        "107,0" => "WDR Eins Live",
        "107,1" => "Radio Köln",
        "107,2" => "WDR Eins Live",
        "107,2" => "Deutschlandfunk (DLF)",
        "107,3" => "WDR Eins Live",
        "107,3" => "Hellweg Radio",
        "107,4" => "Radio Euskirchen",
        "107,4" => "Radio Kiepenkerl",
        "107,4" => "Radio Lippe",
        "107,4" => "Radio Wuppertal",
        "107,5" => "Radio Rur",
        "107,5" => "Radio Gütersloh",
        "107,5" => "WDR Eins Live",
        "107,6" => "Radio Leverkusen",
        "107,6" => "Radio Sauerland",
        "107,6" => "Radio K.W.",
        "107,7" => "WDR Eins Live",
        "107,7" => "Hellweg Radio",
        "107,7" => "107.7 Radio Hagen",
        "107,8" => "107.8 Antenne AC",
        "107,8" => "Lokalradio Olpe",
        "107,9" => "Radio Bonn/Rhein-Sieg",
        "107,9" => "WDR Eins Live",
        "107,9" => "Radio RSG",
    );

    my @m = mode values %radio_ukw_nrw;
    my $m = shift @m;
    @m = sort @m;
    unshift @m, $m;
    is_deeply([14, 'WDR 5', 'WDR Eins Live'], \@m, "multimodal result in list context");
    $m = mode values %radio_ukw_nrw;
    is(14, $m, "multimodal result in scalar context");
}

leak_free_ok(
    'mode (unimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
        my @m = mode @probes;
    },
    'scalar mode (unimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
        my $m = mode @probes;
    },
    'mode (bimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4, (7) x 3, (8) x 7);
        my @m = mode @probes;
    },
    'scalar mode (bimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4, (7) x 3, (8) x 7);
        my $m = mode @probes;
    },
    'mode (multimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4, (7) x 3, (8) x 7, (9) x 4, (10) x 3, (11) x 7);
        my @m = mode @probes;
    },
    'scalar mode (multimodal)' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4, (7) x 3, (8) x 7, (9) x 4, (10) x 3, (11) x 7);
        my $m = mode @probes;
    },
);

leak_free_ok(
    'mode (unimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4);
            my @m      = mode @probes;
        };
    },
    'scalar mode (unimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4);
            my $m      = mode @probes;
        };
    },
    'mode (bimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj = DieOnStringify->new;
            my @probes =
              ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4, $obj, (7) x 3, $obj, (8) x 7);
            my @m = mode @probes;
        };
    },
    'scalar mode (bimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj = DieOnStringify->new;
            my @probes =
              ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4, $obj, (7) x 3, $obj, (8) x 7);
            my $m = mode @probes;
        };
    },
    'mode (multimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = (
                (1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4, $obj,
                (7) x 3, $obj, (8) x 7, $obj, (9) x 4, $obj, (10) x 3, $obj, (11) x 7
            );
            my @m = mode @probes;
        };
    },
    'scalar mode (multimodal) with exception in overloading stringify' => sub {
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = (
                (1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4, $obj,
                (7) x 3, $obj, (8) x 7, $obj, (9) x 4, $obj, (10) x 3, $obj, (11) x 7
            );
            my $m = mode @probes;
        };
    },
);

done_testing;



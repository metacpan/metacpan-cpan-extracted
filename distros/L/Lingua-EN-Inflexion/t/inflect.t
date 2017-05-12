use Test::More;
use Lingua::EN::Inflexion;

my $SINGULAR = 'maximum';
my $PLURAL   = 'maximums';
my $CLASSIC  = 'maxima';

my %expected = (
    '#' => {
             'N'  => { 
                        0 => "0 $PLURAL were found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "0 $CLASSIC were found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#a' => {
             'N'  => { 
                        0 => "0 $PLURAL were found",
                        1 => "a $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "0 $CLASSIC were found",
                        1 => "a $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#as' => {
             'N'  => { 
                        0 => "no $SINGULAR was found",
                        1 => "a $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $SINGULAR was found",
                        1 => "a $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#w' => {
             'N'  => { 
                        0 => "zero $PLURAL were found",
                        1 => "one $SINGULAR was found",
                        2 => "two $PLURAL were found",
                       10 => "ten $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "zero $CLASSIC were found",
                        1 => "one $SINGULAR was found",
                        2 => "two $CLASSIC were found",
                       10 => "ten $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#s' => {
             'N'  => { 
                        0 => "no $SINGULAR was found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $SINGULAR was found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#ws' => {
             'N'  => { 
                        0 => "no $SINGULAR was found",
                        1 => "one $SINGULAR was found",
                        2 => "two $PLURAL were found",
                       10 => "ten $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $SINGULAR was found",
                        1 => "one $SINGULAR was found",
                        2 => "two $CLASSIC were found",
                       10 => "ten $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#n' => {
             'N'  => { 
                        0 => "no $PLURAL were found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $CLASSIC were found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#nw' => {
             'N'  => { 
                        0 => "no $PLURAL were found",
                        1 => "one $SINGULAR was found",
                        2 => "two $PLURAL were found",
                       10 => "ten $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $CLASSIC were found",
                        1 => "one $SINGULAR was found",
                        2 => "two $CLASSIC were found",
                       10 => "ten $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#ns' => {
             'N'  => { 
                        0 => "no $SINGULAR was found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $PLURAL were found",
                       10 => "10 $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $SINGULAR was found",
                        1 => "1 $SINGULAR was found",
                        2 => "2 $CLASSIC were found",
                       10 => "10 $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
    '#nws' => {
             'N'  => { 
                        0 => "no $SINGULAR was found",
                        1 => "one $SINGULAR was found",
                        2 => "two $PLURAL were found",
                       10 => "ten $PLURAL were found",
                       11 => "11 $PLURAL were found",
                     },
             'Nc' => {
                        0 => "no $SINGULAR was found",
                        1 => "one $SINGULAR was found",
                        2 => "two $CLASSIC were found",
                       10 => "ten $CLASSIC were found",
                       11 => "11 $CLASSIC were found",
                     },
           },
);

for my $countfmt (keys %expected) {
    for my $nounfmt (keys %{ $expected{$countfmt} }) {
        for my $count (keys  %{ $expected{$countfmt}{$nounfmt} }) {
            is inflect("<$countfmt:$count> <$nounfmt:$SINGULAR> <V:were> found"),
               $expected{$countfmt}{$nounfmt}{$count}
                  => "$countfmt / $nounfmt / $count";
        }
    }
}

my @results = 1..10;
is inflect "<#i:$#results> <N:maximum> <V:was> found",    "10 maximums were found" => '#i / N / V';
is inflect "<#Inc:$#results> <N:maximum> <V:was> found",  "10 maximums were found" => '#Inc / N / V';
is inflect "<#Inc:$#results> <Nc:maximum> <V:was> found", "10 maxima were found"   => '#Inc / N / V';

is inflect "<#d:$#results> <N:item> <V:was> found",       "items were found"       => '#d:10 / N / V';
is inflect "<#d:1> <N:item> <V:was> found",               "item was found"         => '#d:1 / N / V';

is inflect "<#da:2> <N:item> <V:was> found",              "items were found"       => '#da:2 / N / V';
is inflect "<#da:1> <N:item> <V:was> found",              "an item was found"      => '#da:1 / N / V';

is inflect "<#dan:2> <N:maximum> <V:was> found",          "maximums were found"    => '#dan:2 / N / V';
is inflect "<#dan:1> <N:item> <V:was> found",             "an item was found"      => '#dan:1 / N / V';
is inflect "<#dan:0> <N:items> <V:were> found",           "no items were found"    => '#dan:0 / N / V';

is inflect "<#dans:0> <N:maximums> <V:was> found",        "no maximum was found"   => '#danc:0 / N / V';

is inflect "<#e:12> <N:maximum> <V:was> found",           "12 maximums were found"  => '#e:12 / N / V';
is inflect "<#e:2> <N:maximum> <V:was> found",            "two maximums were found" => '#e:2 / N / V';
is inflect "<#e:1> <N:item> <V:was> found",               "an item was found"       => '#e:1 / N / V';
is inflect "<#e:0> <N:items> <V:were> found",             "no item was found"       => '#e:0 / N / V';

is inflect "<#a:1> <N:idea>",          "an idea",         "Unseparated count (1) and noun";
is inflect "<#a:2> <N:idea>",          "2 ideas",         "Unseparated count (2) and noun";
is inflect "<#a:1> good <N:idea>",     "a good idea",     "Separated count (1) and noun";
is inflect "<#a:2> good <N:idea>",     "2 good ideas",    "Separated count (2) and noun";

is inflect "Found <#f:0> <N:matches>",  "Found no matches",          "#f:0";
is inflect "Found <#f:1> <N:matches>",  "Found one match",           "#f:1";
is inflect "Found <#f:2> <N:matches>",  "Found a couple of matches", "#f:2";
is inflect "Found <#f:3> <N:matches>",  "Found a few matches",       "#f:3";
is inflect "Found <#f:4> <N:matches>",  "Found a few matches",       "#f:4";
is inflect "Found <#f:5> <N:matches>",  "Found a few matches",       "#f:5";
is inflect "Found <#f:6> <N:matches>",  "Found several matches",     "#f:6";
is inflect "Found <#f:7> <N:matches>",  "Found several matches",     "#f:7";
is inflect "Found <#f:8> <N:matches>",  "Found several matches",     "#f:8";
is inflect "Found <#f:9> <N:matches>",  "Found several matches",     "#f:9";
is inflect "Found <#f:10> <N:matches>", "Found many matches",        "#f:10";
is inflect "Found <#f:99> <N:matches>", "Found many matches",        "#f:99";

is inflect "Found <#f:0>.",  "Found none.",        "Trailing #f:0";
is inflect "Found <#f:1>.",  "Found one.",         "Trailing #f:1";
is inflect "Found <#f:2>.",  "Found a couple.",    "Trailing #f:2";
is inflect "Found <#f:3>.",  "Found a few.",       "Trailing #f:3";
is inflect "Found <#f:4>.",  "Found a few.",       "Trailing #f:4";
is inflect "Found <#f:5>.",  "Found a few.",       "Trailing #f:5";
is inflect "Found <#f:6>.",  "Found several.",     "Trailing #f:6";
is inflect "Found <#f:7>.",  "Found several.",     "Trailing #f:7";
is inflect "Found <#f:8>.",  "Found several.",     "Trailing #f:8";
is inflect "Found <#f:9>.",  "Found several.",     "Trailing #f:9";
is inflect "Found <#f:10>.", "Found many.",        "Trailing #f:10";
is inflect "Found <#f:99>.", "Found many.",        "Trailing #f:99";

is inflect "Looking for <#d:1> <Np:ox>",    'Looking for oxen',    '<Np:ox> --> oxen';
is inflect "Looking for <#d:2> an <Ns:ox>", 'Looking for an ox',   '<Ns:ox> --> ox';
is inflect "Looking for <#d:1> <Np:oxen>",    'Looking for oxen',    '<Np:oxen> --> oxen';
is inflect "Looking for <#d:2> an <Ns:oxen>", 'Looking for an ox',   '<Ns:oxen> --> ox';

done_testing();

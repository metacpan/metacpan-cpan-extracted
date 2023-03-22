#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Benchmark qw(:hireswallclock cmpthese);
use File::Temp ();
use HTML::Entities qw(encode_entities);
use HTML::Blitz ();
use HTML::Blitz::Builder qw(mk_doctype mk_comment mk_elem to_html);
use HTML::Template ();
use HTML::Template::Pro ();
use HTML::Zoom ();
use Mojo::Template ();
use Template ();
use Text::Xslate ();

sub vers {
    my ($pkg) = @_;
    my $vpkg =
        $pkg =~ /^Mojo::/ ? do { require Mojolicious; Mojolicious:: } :
        $pkg =~ /^Template::/ ? do { require Template; Template:: } :
        $pkg;
    my $v = $vpkg->VERSION
        // die "$vpkg has no version";
    "$pkg $v"
}

my $data = [];
{
    my $img_counter = 0;
    my $gen_img_data = sub {
        my $src = "img/pic-$img_counter.jpg";
        $img_counter++;
        my $alt = "placeholder photo $img_counter";
        $img_counter %= 11;
        +(
            img_src => $src,
            img_alt => $alt,
        )
    };

    for my $i (1 .. 5) {
        push @$data, {
            name => "Category $i",
            cid  => "1234$i",
            card => [
                map +{
                    $gen_img_data->(),
                    name        => "Card $_",
                    description => [
                        map +{ para => $_ },
                        (
                            "Lorem ipsum dolor sit amet, consectetur adipiscing
                            elit, sed do eiusmod tempor incididunt ut labore et
                            dolore magna aliqua. Lectus magna fringilla urna
                            porttitor rhoncus dolor purus non. Quis hendrerit
                            dolor magna eget est lorem ipsum dolor. Eu ultrices
                            vitae auctor eu augue ut lectus arcu.",

                            "Ut placerat orci nulla pellentesque dignissim.
                            Eget arcu dictum varius duis at consectetur lorem
                            donec massa.  Semper risus in hendrerit gravida
                            rutrum quisque non tellus orci.",

                            "Velit dignissim sodales ut eu sem integer vitae.
                            Morbi tempus iaculis urna id. Lectus urna duis
                            convallis convallis. Id cursus metus aliquam
                            eleifend mi in nulla posuere sollicitudin.  Tempor
                            id eu nisl nunc mi. Blandit massa enim nec dui nunc
                            mattis enim ut tellus.",

                            "Sit amet est placerat in egestas erat imperdiet
                            sed. Id interdum velit laoreet id. Laoreet
                            suspendisse interdum consectetur libero id
                            faucibus.",

                            "At lectus urna duis convallis convallis tellus id.
                            Massa tempor nec feugiat nisl pretium fusce id
                            velit. Vitae congue mauris rhoncus aenean.  Morbi
                            tempus iaculis urna id volutpat.",
                        )[$_ % 5 .. 4]
                    ],
                    location => [
                        do {
                            my $outer = $_;
                            map +{
                                name  => "Location name $outer-" . ($_ + 1),
                                times => [
                                    map
                                        +{ time => sprintf('%02u:%02u', 7 + $_, $_ % 2 ? 30 : 0) },
                                        0 .. ($outer + $_ + 1) % 7
                                ],
                            }, 0 .. ($outer + 1) % 4
                        },
                    ],
                },
                1 .. 40,
            ],
        };
    }
}

my $template_file = 'bench.html';
my $template_html = do {
    open my $fh, '<:encoding(UTF-8)', $template_file
        or die "$0: can't open $template_file: $!\n";
    local $/;
    readline $fh
};

my $blitz_fn = do {
    my $blitz = HTML::Blitz->new;
    $blitz->add_rules(
        [ '.category' =>
            [ repeat_outer => 'category',
                [ '.cat-start' => [ set_attribute_var => 'id', 'cid' ] ],
                [ '.cat-name' => [ replace_inner_var => 'name' ] ],
                [ '.cat-link' => [ set_attribute_var => 'href', 'cid_link' ] ],
                [ '.card' =>
                    [ repeat_outer => 'card',
                        [ 'img' =>
                            [ set_attributes =>
                                {
                                    src => [var => 'img_src'],
                                    alt => [var => 'img_alt'],
                                }
                            ],
                        ],
                        [ '.card-name' => [ replace_inner_var => 'name' ] ],
                        [ '.description' =>
                            [ repeat_inner => 'description',
                                [ '.desc-para' => [ replace_inner_var => 'para' ] ],
                            ],
                        ],
                        [ '.location' =>
                            [ repeat_outer => 'location',
                                [ '.loc-name' => [ replace_inner_var => 'name' ] ],
                                [ '.times' =>
                                    [ repeat_inner => 'times',
                                        [ '.time' => [ replace_inner_var => 'time' ] ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ],
    );

    my $template = $blitz->apply_to_html($template_file, $template_html);
    $template->compile_to_sub
};

my $proto_zoom = HTML::Zoom->from_html($template_html);

my $tt_template = Template->new(
    INCLUDE_PATH => '.',
    ENCODING     => 'utf-8',
    STRICT       => 1,
) // die "TT2 error: " . Template->error;

my $html_template = HTML::Template->new(
    filename       => 'bench.tmpl',
    utf8           => 1,
    default_escape => 'html',
    case_sensitive => 1,
);

my $html_template_pro = HTML::Template::Pro->new(
    filename       => 'bench.tmpl',
    utf8           => 1,
    default_escape => 'html',
    case_sensitive => 1,
);

my $xslate_cache = File::Temp->newdir('xslate-cache-XXXXXX', TMPDIR => 1);
my $xslate = Text::Xslate->new(
    cache_dir => $xslate_cache->dirname,
);
$xslate->load_file('bench.tx');

my $mojo_template = do {
    my $filename = 'bench.mt';
    my $mt = Mojo::Template->new(
        auto_escape => 1,
        vars        => 1,
        name        => $filename,
    );

    $mt->parse(do {
        open my $fh, '<:encoding(UTF-8)',  $filename or die "$filename: $!";
        local $/;
        readline $fh
    })
};

cmpthese(-5, {
    vers('Mojo::Template') => sub {
        my $result = $mojo_template->process({ data => $data });
    },

    vers('HTML::Template::Pro') => sub {
        my %html_template_data = (
            category => [
                map {
                    my $category_name = $_->{name};
                    my $cid_link      = "#cid-$_->{cid}";
                    +{
                        name     => $category_name,
                        cid      => "cid-$_->{cid}",
                        card => [
                            map +{
                                category_name => $category_name,
                                cid_link      => $cid_link,
                                %$_,
                            }, @{$_->{card}}
                        ],
                    }
                } @$data
            ],
        );

        $html_template_pro->param(%html_template_data);
        my $result = $html_template_pro->output;
        $html_template_pro->clear_params;
    },

    vers('HTML::Template') => sub {
        my %html_template_data = (
            category => [
                map {
                    my $category_name = $_->{name};
                    my $cid_link      = "#cid-$_->{cid}";
                    +{
                        name     => $category_name,
                        cid      => "cid-$_->{cid}",
                        card => [
                            map +{
                                category_name => $category_name,
                                cid_link      => $cid_link,
                                %$_,
                            }, @{$_->{card}}
                        ],
                    }
                } @$data
            ],
        );

        $html_template->param(%html_template_data);
        my $result = $html_template->output;
        $html_template->clear_params;
    },

    vers('HTML::Zoom') => sub {
        my $zoom = $proto_zoom
            ->select('.category')
            ->repeat([
                map {
                    my $category = $_;
                    sub {
                        $_
                        ->select('.cat-start')->set_attribute(id => "cid-$category->{cid}")
                        ->select('.cat-name')->replace_content($category->{name})
                        ->select('.cat-link')->set_attribute(href => "#cid-$category->{cid}")
                        ->select('.card')->repeat([
                            map {
                                my $card = $_;
                                sub {
                                    $_
                                    ->select('img')->set_attribute({ src => $card->{img_src}, alt => $card->{img_alt} })
                                    ->select('.card-name')->replace_content($card->{name})
                                    ->select('.description')->repeat_content([
                                        map {
                                            my $para = $_->{para};
                                            sub {
                                                $_
                                                ->select('.desc-para')->replace_content($para)
                                            }
                                        }
                                        @{$card->{description}}
                                    ])
                                    ->select('.location')->repeat([
                                        map {
                                            my $location = $_;
                                            sub {
                                                $_
                                                ->select('.loc-name')->replace_content($location->{name})
                                                ->select('.times')->repeat_content([
                                                    map {
                                                        my $time = $_->{time};
                                                        sub {
                                                            $_
                                                            ->select('.time')->replace_content($time)
                                                        }
                                                    }
                                                    @{$location->{times}}
                                                ])
                                            }
                                        }
                                        @{$card->{location}}
                                    ])
                                }
                            }
                            @{$category->{card}}
                        ])
                    }
                }
                @$data
            ]);

        my $result = $zoom->to_html;
    },

    vers('HTML::Blitz') => sub {
        my $blitz_data = {
            category => [
                map +{
                    name     => $_->{name},
                    cid      => "cid-$_->{cid}",
                    cid_link => "#cid-$_->{cid}",
                    card     => $_->{card},
                }, @$data
            ],
        };

        my $result = $blitz_fn->($blitz_data);
    },

    'HTML-Blitz-used-wrong' => sub {
        my $blitz = HTML::Blitz->new;
        $blitz->add_rules(
            [ '.category' =>
                [ repeat_outer => 'category',
                    [ '.cat-start' => [ set_attribute_var => 'id', 'cid' ] ],
                    [ '.cat-name' => [ replace_inner_var => 'name' ] ],
                    [ '.cat-link' => [ set_attribute_var => 'href', 'cid_link' ] ],
                    [ '.card' =>
                        [ repeat_outer => 'card',
                            [ 'img' =>
                                [ set_attributes =>
                                    {
                                        src => [var => 'img_src'],
                                        alt => [var => 'img_alt'],
                                    }
                                ],
                            ],
                            [ '.card-name' => [ replace_inner_var => 'name' ] ],
                            [ '.description' =>
                                [ repeat_inner => 'description',
                                    [ '.desc-para' => [ replace_inner_var => 'para' ] ],
                                ],
                            ],
                            [ '.location' =>
                                [ repeat_outer => 'location',
                                    [ '.loc-name' => [ replace_inner_var => 'name' ] ],
                                    [ '.times' =>
                                        [ repeat_inner => 'times',
                                            [ '.time' => [ replace_inner_var => 'time' ] ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        );

        my $template = $blitz->apply_to_html($template_file, $template_html);

        my $blitz_data = {
            category => [
                map +{
                    name     => $_->{name},
                    cid      => "cid-$_->{cid}",
                    cid_link => "#cid-$_->{cid}",
                    card     => $_->{card},
                }, @$data
            ],
        };

        my $result = $template->process($blitz_data);
    },

    vers('Template::Toolkit') => sub {
        $tt_template->process('bench.tt', { data => $data }, \my $result)
            or die "TT2 error: " . $tt_template->error;
    },

    vers('Text::Xslate') => sub {
        my $result = $xslate->render('bench.tx', { data => $data });
    },

    'handwritten' => sub {
        my $html = "";
        $html .= "<!DOCTYPE html>\n";
        $html .= "<html>\n";
        $html .= "    <head>\n";
        $html .= "        <meta charset=\"utf-8\">\n";
        $html .= "        <!--\n";
        $html .= "    Some men are born to good luck: all they do or try to do comes right—all\n";
        $html .= "    that falls to them is so much gain—all their geese are swans—all their\n";
        $html .= "    cards are trumps—toss them which way you will, they will always, like poor\n";
        $html .= "    puss, alight upon their legs, and only move on so much the faster. The\n";
        $html .= "    world may very likely not always think of them as they think of themselves,\n";
        $html .= "    but what care they for the world? what can it know about the matter?\n";
        $html .= "\n";
        $html .= "    One of these lucky beings was neighbour Hans. Seven long years he had\n";
        $html .= "    worked hard for his master. At last he said, ‘Master, my time is up; I must\n";
        $html .= "    go home and see my poor mother once more: so pray pay me my wages and let\n";
        $html .= "    me go.’ And the master said, ‘You have been a faithful and good servant,\n";
        $html .= "    Hans, so your pay shall be handsome.’ Then he gave him a lump of silver as\n";
        $html .= "    big as his head.\n";
        $html .= "\n";
        $html .= "    Hans took out his pocket-handkerchief, put the piece of silver into it,\n";
        $html .= "    threw it over his shoulder, and jogged off on his road homewards. As he\n";
        $html .= "    went lazily on, dragging one foot after another, a man came in sight,\n";
        $html .= "    trotting gaily along on a capital horse. ‘Ah!’ said Hans aloud, ‘what a\n";
        $html .= "    fine thing it is to ride on horseback! There he sits as easy and happy as\n";
        $html .= "    if he was at home, in the chair by his fireside; he trips against no\n";
        $html .= "    stones, saves shoe-leather, and gets on he hardly knows how.’ Hans did not\n";
        $html .= "    speak so softly but the horseman heard it all, and said, ‘Well, friend, why\n";
        $html .= "    do you go on foot then?’ ‘Ah!’ said he, ‘I have this load to carry: to be\n";
        $html .= "    sure it is silver, but it is so heavy that I can’t hold up my head, and you\n";
        $html .= "    must know it hurts my shoulder sadly.’ ‘What do you say of making an\n";
        $html .= "    exchange?’ said the horseman. ‘I will give you my horse, and you shall give\n";
        $html .= "    me the silver; which will save you a great deal of trouble in carrying such\n";
        $html .= "    a heavy load about with you.’ ‘With all my heart,’ said Hans: ‘but as you\n";
        $html .= "    are so kind to me, I must tell you one thing—you will have a weary task to\n";
        $html .= "    draw that silver about with you.’ However, the horseman got off, took the\n";
        $html .= "    silver, helped Hans up, gave him the bridle into one hand and the whip into\n";
        $html .= "    the other, and said, ‘When you want to go very fast, smack your lips loudly\n";
        $html .= "    together, and cry “Jip!”’\n";
        $html .= "\n";
        $html .= "    Hans was delighted as he sat on the horse, drew himself up, squared his\n";
        $html .= "    elbows, turned out his toes, cracked his whip, and rode merrily off, one\n";
        $html .= "    minute whistling a merry tune, and another singing,\n";
        $html .= "\n";
        $html .= "    ‘No care and no sorrow,\n";
        $html .= "    A fig for the morrow!\n";
        $html .= "    We’ll laugh and be merry,\n";
        $html .= "    Sing neigh down derry!’\n";
        $html .= "\n";
        $html .= "    After a time he thought he should like to go a little faster, so he smacked\n";
        $html .= "    his lips and cried ‘Jip!’ Away went the horse full gallop; and before Hans\n";
        $html .= "    knew what he was about, he was thrown off, and lay on his back by the\n";
        $html .= "    road-side. His horse would have ran off, if a shepherd who was coming by,\n";
        $html .= "    driving a cow, had not stopped it. Hans soon came to himself, and got upon\n";
        $html .= "    his legs again, sadly vexed, and said to the shepherd, ‘This riding is no\n";
        $html .= "    joke, when a man has the luck to get upon a beast like this that stumbles\n";
        $html .= "    and flings him off as if it would break his neck. However, I’m off now once\n";
        $html .= "    for all: I like your cow now a great deal better than this smart beast that\n";
        $html .= "    played me this trick, and has spoiled my best coat, you see, in this\n";
        $html .= "    puddle; which, by the by, smells not very like a nosegay. One can walk\n";
        $html .= "    along at one’s leisure behind that cow—keep good company, and have milk,\n";
        $html .= "    butter, and cheese, every day, into the bargain. What would I give to have\n";
        $html .= "    such a prize!’ ‘Well,’ said the shepherd, ‘if you are so fond of her, I\n";
        $html .= "    will change my cow for your horse; I like to do good to my neighbours, even\n";
        $html .= "    though I lose by it myself.’ ‘Done!’ said Hans, merrily. ‘What a noble\n";
        $html .= "    heart that good man has!’ thought he. Then the shepherd jumped upon the\n";
        $html .= "    horse, wished Hans and the cow good morning, and away he rode.\n";
        $html .= "        -->\n";
        $html .= "        <title>Templatized torture test - Bencherino!</title>\n";
        $html .= "\n";
        $html .= "<style>\n";
        $html .= "\n";
        $html .= "h1, h2, h3, h4, h5, h6 {\n";
        $html .= "    font-family: sans-serif;\n";
        $html .= "}\n";
        $html .= "\n";
        $html .= ".cardbox {\n";
        $html .= "    display: grid;\n";
        $html .= "    grid-template-columns: repeat(auto-fit, minmax(250px, 510px));\n";
        $html .= "    gap: 20px;\n";
        $html .= "}\n";
        $html .= "\n";
        $html .= ".card {\n";
        $html .= "    border: 3px solid rebeccapurple;\n";
        $html .= "    padding: 10px;\n";
        $html .= "    border-radius: 10px;\n";
        $html .= "    background-color: #f7f1e6;\n";
        $html .= "}\n";
        $html .= "\n";
        $html .= ".card > img {\n";
        $html .= "    max-width: 100%;\n";
        $html .= "}\n";
        $html .= "\n";
        $html .= "</style>\n";
        $html .= "\n";
        $html .= "    </head>\n";
        $html .= "\n";
        $html .= "    <body>\n";
        $html .= "\n";
        $html .= "        <h1>A page with assorted random data</h1>\n";
        $html .= "\n";
        for my $category (@$data) {
            $html .= "        <section class=\"category\">\n";
            $html .= "            <h2 class=\"cat-name cat-start\" id=\"" . encode_entities("cid-$category->{cid}") . "\">" . encode_entities($category->{name}) . "</h2>\n";
            $html .= "            <div class=\"cardbox\">\n";
            for my $card (@{$category->{card}}) {
                $html .= "                <div class=\"card\">\n";
                $html .= "                    <h3 class=\"card-name\">" . encode_entities($card->{name}) . "</h3>\n";
                $html .= "                    <img src=\"" . encode_entities($card->{img_src}) . "\" alt=\"" . encode_entities($card->{img_alt}) . "\" />\n";
                $html .= "                    <!-- ^ HTML::Zoom requires this \"/\" -->\n";
                $html .= "                    <p>(Category: <a class=\"cat-name cat-link\" href=\"" . encode_entities("#cid-$category->{cid}") . "\">" . encode_entities($category->{name}) . "</a>)</p>\n";
                $html .= "                    <div class=\"description\">\n";
                for my $para (@{$card->{description}}) {
                    $html .= "                        <p class=\"desc-para\">" . encode_entities($para->{para}) . "</p>\n";
                }
                $html .= "                    </div>\n";
                $html .= "                    <h4>Locations</h4>\n";
                $html .= "                    <ul>\n";
                for my $location (@{$card->{location}}) {
                    $html .= "                        <li class=\"location\">\n";
                    $html .= "                            <p class=\"loc-name\">" . encode_entities($location->{name}) . "</p>\n";
                    $html .= "                            <h5>Times</h5>\n";
                    $html .= "                            <ul class=\"times\">\n";
                    for my $time (@{$location->{times}}) {
                        $html .= "                                <li class=\"time\">" . encode_entities($time->{time}) . "</li>\n";
                    }
                    $html .= "                            </ul>\n";
                    $html .= "                        </li>\n";
                }
                $html .= "                    </ul>\n";
                $html .= "                </div>\n";
            }
            $html .= "            </div>\n";
            $html .= "        </section>\n";
        }
        $html .= "\n";
        $html .= "    </body>\n";
        $html .= "\n";
        $html .= "</html>\n";

        my $result = $html;

    },

    vers('HTML::Blitz::Builder') => sub {
        my @head = (
            mk_elem(meta => { charset => 'utf-8' }),
            mk_comment(<<'EOF'),
Some men are born to good luck: all they do or try to do comes right—all
that falls to them is so much gain—all their geese are swans—all their
cards are trumps—toss them which way you will, they will always, like poor
puss, alight upon their legs, and only move on so much the faster. The
world may very likely not always think of them as they think of themselves,
but what care they for the world? what can it know about the matter?

One of these lucky beings was neighbour Hans. Seven long years he had
worked hard for his master. At last he said, ‘Master, my time is up; I must
go home and see my poor mother once more: so pray pay me my wages and let
me go.’ And the master said, ‘You have been a faithful and good servant,
Hans, so your pay shall be handsome.’ Then he gave him a lump of silver as
big as his head.

Hans took out his pocket-handkerchief, put the piece of silver into it,
threw it over his shoulder, and jogged off on his road homewards. As he
went lazily on, dragging one foot after another, a man came in sight,
trotting gaily along on a capital horse. ‘Ah!’ said Hans aloud, ‘what a
fine thing it is to ride on horseback! There he sits as easy and happy as
if he was at home, in the chair by his fireside; he trips against no
stones, saves shoe-leather, and gets on he hardly knows how.’ Hans did not
speak so softly but the horseman heard it all, and said, ‘Well, friend, why
do you go on foot then?’ ‘Ah!’ said he, ‘I have this load to carry: to be
sure it is silver, but it is so heavy that I can’t hold up my head, and you
must know it hurts my shoulder sadly.’ ‘What do you say of making an
exchange?’ said the horseman. ‘I will give you my horse, and you shall give
me the silver; which will save you a great deal of trouble in carrying such
a heavy load about with you.’ ‘With all my heart,’ said Hans: ‘but as you
are so kind to me, I must tell you one thing—you will have a weary task to
draw that silver about with you.’ However, the horseman got off, took the
silver, helped Hans up, gave him the bridle into one hand and the whip into
the other, and said, ‘When you want to go very fast, smack your lips loudly
together, and cry “Jip!”’

Hans was delighted as he sat on the horse, drew himself up, squared his
elbows, turned out his toes, cracked his whip, and rode merrily off, one
minute whistling a merry tune, and another singing,

‘No care and no sorrow,
A fig for the morrow!
We’ll laugh and be merry,
Sing neigh down derry!’

After a time he thought he should like to go a little faster, so he smacked
his lips and cried ‘Jip!’ Away went the horse full gallop; and before Hans
knew what he was about, he was thrown off, and lay on his back by the
road-side. His horse would have ran off, if a shepherd who was coming by,
driving a cow, had not stopped it. Hans soon came to himself, and got upon
his legs again, sadly vexed, and said to the shepherd, ‘This riding is no
joke, when a man has the luck to get upon a beast like this that stumbles
and flings him off as if it would break his neck. However, I’m off now once
for all: I like your cow now a great deal better than this smart beast that
played me this trick, and has spoiled my best coat, you see, in this
puddle; which, by the by, smells not very like a nosegay. One can walk
along at one’s leisure behind that cow—keep good company, and have milk,
butter, and cheese, every day, into the bargain. What would I give to have
such a prize!’ ‘Well,’ said the shepherd, ‘if you are so fond of her, I
will change my cow for your horse; I like to do good to my neighbours, even
though I lose by it myself.’ ‘Done!’ said Hans, merrily. ‘What a noble
heart that good man has!’ thought he. Then the shepherd jumped upon the
horse, wished Hans and the cow good morning, and away he rode.
EOF
            mk_elem(title => "Templatized torture test - Bencherino!"),
            mk_elem(style => <<'EOF'),
h1, h2, h3, h4, h5, h6 {
    font-family: sans-serif;
}

.cardbox {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 510px));
    gap: 20px;
}

.card {
    border: 3px solid rebeccapurple;
    padding: 10px;
    border-radius: 10px;
    background-color: #f7f1e6;
}

.card > img {
    max-width: 100%;
}
EOF
        );

        my @categories;
        for my $category (@$data) {

            my @cards;
            for my $card (@{$category->{card}}) {

                my @description;
                for my $para (@{$card->{description}}) {
                    push @description, mk_elem(p => { class => 'desc-para' },
                        $para->{para},
                    );
                }

                my @locations;
                for my $location (@{$card->{location}}) {

                    my @times;
                    for my $time (@{$location->{times}}) {
                        push @times, mk_elem(li => { class => 'time' },
                            $time->{time},
                        );
                    }

                    push @locations, mk_elem(li => { class => 'location' },
                        mk_elem(p => { class => 'loc-name' },
                            $location->{name},
                        ),
                        mk_elem(h5 => 'Times'),
                        mk_elem(ul => { class => 'times' },
                            @times,
                        ),
                    );
                }

                push @cards, mk_elem(div => { class => 'card' },
                    mk_elem(h3 => { class => 'card-name' },
                        $card->{name},
                    ),
                    mk_elem(img => { src => $card->{img_src}, alt => $card->{img_alt} }),
                    mk_comment(" ^ HTML::Zoom requires this \"/\" "),
                    mk_elem(p =>
                        "(Category: ",
                        mk_elem(a => { class => 'cat-name cat-link', href => "#cid-$category->{cid}" },
                            $category->{name},
                        ),
                        ")",
                    ),
                    mk_elem(div => { class => 'description' },
                        @description,
                    ),
                    mk_elem(h4 => 'Locations'),
                    mk_elem(ul =>
                        @locations,
                    ),
                );
            }

            push @categories, mk_elem(
                section => { class => 'category' },
                mk_elem(h2 => { class => 'cat-name cat-start', id => "cid-$category->{cid}" },
                    $category->{name},
                ),
                mk_elem(div => { class => 'cardbox' },
                    @cards,
                ),
            );
        }

        my @body = mk_elem(
            body =>
            mk_elem(h1 => "A page with assorted random data"),
            @categories,
        );

        my @document = (
            mk_doctype,
            mk_elem(
                html =>
                @head,
                @body,
            )
        );

        my $result = to_html @document;
    },
});

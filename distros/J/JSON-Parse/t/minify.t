use FindBin '$Bin';
use lib "$Bin";
use JPT;
use JSON::Whitespace ':all';

my $in = <<EOF;
{
            "animals":{
                    "elephant":"🐘",
                    "goat":"🐐",
                    "kingkong":"🦍"
            },
            "baka":{
                    "あ":"ほ",
                    "ば":"か",
                    "ま":"ぬけ"
            },
            "fruit":{
                    "grape":"🍇",
                    "melon":"🍈",
                    "watermelon":"🍉"
            },
            "moons":{
                    "🌑":0,
                    "🌒":1,
                    "🌓":2,
                    "🌔":3,
                    "🌕":4,
                    "🌖":5,
                    "🌗":6,
                    "🌘":7
            }
    }
EOF
my $minify = json_minify ($in);
is ($minify, '{"animals":{"elephant":"🐘","goat":"🐐","kingkong":"🦍"},"baka":{"あ":"ほ","ば":"か","ま":"ぬけ"},"fruit":{"grape":"🍇","melon":"🍈","watermelon":"🍉"},"moons":{"🌑":0,"🌒":1,"🌓":2,"🌔":3,"🌕":4,"🌖":5,"🌗":6,"🌘":7}}', "Removed whitespace from JSON");
done_testing ();

use warnings;
use strict;
use JSON::Whitespace ':all';

my $in = <<EOF;
{
            "animals":{
                    "kingkong":"🦍"
            },
            "baka":[
                    "ドジ"
            ],
            "fruit":{
                    "grape":"🍇"
            },
            "moons":{
                    "🌑":0
            }
    }
EOF
my $minify = json_minify ($in);
print $minify;

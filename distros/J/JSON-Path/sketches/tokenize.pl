use 5.016;

use JSON::Path::Tokenizer qw(tokenize);
use Data::Dumper;
print Dumper tokenize(q{$.path\.one.two});


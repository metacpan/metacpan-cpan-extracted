use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use HTML::Valid;

my $htv = HTML::Valid->new (
    alt_text => 'samba',
    show_body_only => 1,
    quiet => 1,
);
my $html = <<EOF;
<img src='http://example.org/my.png'>
EOF
my ($out, $errors) = $htv->run ($html);
TODO: {
local $TODO='Eliminate error message with alt text';
ok (length ($errors) == 0, "no errors");
note ($errors);
};
like ($out, qr/<img/, "Got image back");
like ($out, qr/alt="samba"/i, "Alt added correctly");
done_testing ();

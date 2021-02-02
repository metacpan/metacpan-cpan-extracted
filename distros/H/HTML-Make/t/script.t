use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use HTML::Make;

for my $thing (qw!defer async!) {
    my $script = HTML::Make->new ('script', attr => 
				  {$thing => 1, src => 'some.js'});
    my $text = $script->text ();
    like ($text, qr!<script.*$thing.*!, "Got $thing");
    unlike ($text, qr!$thing=!, "No equals with $thing");
}
done_testing ();

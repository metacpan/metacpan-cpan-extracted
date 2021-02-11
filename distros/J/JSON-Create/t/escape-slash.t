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
use JSON::Create;
my $jc = JSON::Create->new ();
# Input with slashes at start and end.
my $input = {'/dogs/' => '/dinky/'};
# Regex for the case it is not escaped.
my $notesc = qr!"/.*?/"!;
# Regex for the case it is escaped.
my $esc = qr!"\\/.*?\\/"!;

# Test that the default is not to escape.

my $out = $jc->create ($input);
note ($out);
like ($out, $notesc, "default is no escape");
unlike ($out, $esc, "default is no escape");

# Test that the escaping works.

$jc->escape_slash (1);
my $outesc = $jc->create ($input);
note ($outesc);
unlike ($outesc, $notesc, "escaping works OK");
like ($outesc, $esc, "escaping works OK");

# Test that the escaping can be switched off again.

$jc->escape_slash (0);
my $outunesc = $jc->create ($input);
note ($outunesc);
like ($outunesc, $notesc, "switching off escaping works OK");
unlike ($outunesc, $esc, "switching off escaping works OK");

done_testing ();

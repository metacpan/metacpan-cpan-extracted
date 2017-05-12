# Upstream error in tidylib:
# https://github.com/htacg/tidy-html5/issues/315

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

my $html1 =<<EOF;
<p>
This
<pre>
end
</pre>
</p>
EOF
my $htv1 = HTML::Valid->new (
    quiet => 1,
    show_body_only => 1,
);
my ($output, $errors) = $htv1->run ($html1);
like ($output, qr!<p>This</p>!, "<p> tag trimmed correctly");
TODO: {
    local $TODO = 'Remove doubled error messages';
    my $doubled;
    my @errors = split /\n/, $errors;
    ok (scalar (@errors) == 1, "Only got one error message");
    if (scalar (@errors) > 1) {
	my ($firstloc) = split (':', $errors[0]);
	my ($secondloc) = split (':', $errors[1]);
	ok ($firstloc ne $secondloc, "Errors not in the same place");
	note ("'$firstloc' ne '$secondloc'");
    }
};

done_testing ();

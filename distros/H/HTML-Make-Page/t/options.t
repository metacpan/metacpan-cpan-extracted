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
use HTML::Make::Page 'make_page';

my $warnings;
$SIG{__WARN__} = sub {
    $warnings = "@_";
};

eval {
    my ($h, $b) = make_page (css => ['my.css', 'your.css']);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option css recognised");
eval {
    my ($h, $b) = make_page (js => ['cat.js', 'dog.js', {src => 'parrot.js', async => 1}]);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option js recognised");
eval {
    my ($h, $b) = make_page (lang => "en");

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option lang recognised");
eval {
    my ($h, $b) = make_page (link => [{rel=>"icon", type=>"image/png", href=>"favicon.png"}]);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option link recognised");
eval {
    my ($h, $b) = make_page (meta => [{name => 'author', content => 'Long John Silver'}]);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option meta recognised");
eval {
    my ($h, $b) = make_page (quiet => 1);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option quiet recognised");
eval {
    my $style = <<EOF;
h1 => {
   color => 'white';
   background-color => '#FFF';
}
EOF
    my ($h, $b) = make_page (style => $style);

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option style recognised");
eval {
    my ($h, $b) = make_page (title => "My Cool Page");

};
ok (! $@, "No errors");
if ($@) {
    diag ($@);
}
ok ($warnings !~ /Unknown option/, "Option title recognised");
done_testing ();

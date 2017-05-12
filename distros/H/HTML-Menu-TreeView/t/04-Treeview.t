use HTML::Menu::TreeView qw(help);
my $TreeView = new HTML::Menu::TreeView();
my $hashref  = $TreeView->help();
use Test::More tests => 60;
foreach my $key (sort(keys %{$hashref})) {
    ok(length($hashref->{$key}) eq length($TreeView->help($key)));
}
$TreeView->language('de');
$hashref = $TreeView->help();
foreach my $key (sort(keys %{$hashref})) {
    ok(length($hashref->{$key}) eq length($TreeView->help($key)));
}
1;

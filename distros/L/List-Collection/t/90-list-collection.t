use Modern::Perl;
use Test::More;
my $module = 'List::Collection';
use_ok($module);


my @methods = qw/new _remove_obj intersect union subtract complement/;
for (@methods) {
  can_ok($module, $_);
}

new_ok($module);

done_testing;


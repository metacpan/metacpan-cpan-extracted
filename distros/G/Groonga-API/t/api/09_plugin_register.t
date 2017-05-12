use strict;
use warnings;
use Groonga::API::Test;

db_test(sub {
  my ($ctx, $db) = @_;

  my $dir = Groonga::API::plugin_get_system_plugins_dir();
  my $suffix = Groonga::API::plugin_get_suffix();

  my $path = "$dir/suggest$suffix";

  SKIP: {
    skip "suggest plugin is not found", 1 unless -f $path;
    my $rc = Groonga::API::plugin_register_by_path($ctx, $path);
    is $rc => GRN_SUCCESS, "registered suggest plugin";
  }
});

db_test(sub {
  my ($ctx, $db) = @_;

  my $dir = Groonga::API::plugin_get_system_plugins_dir();
  my $suffix = Groonga::API::plugin_get_suffix();

  my $path = "$dir/suggest$suffix";

  SKIP: {
    skip "suggest plugin is not found", 1 unless -f $path;
    my $name = "suggest";
    my $rc = Groonga::API::plugin_register($ctx, $name);
    is $rc => GRN_SUCCESS, "registered suggest plugin";
  }
});

done_testing;

package Mason::Test::Plugins::Notify::Interp;
$Mason::Test::Plugins::Notify::Interp::VERSION = '2.24';
use Mason::PluginRole;

before 'run' => sub {
    print STDERR "starting interp run\n";
};

1;

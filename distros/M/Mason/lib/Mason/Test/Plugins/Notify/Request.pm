package Mason::Test::Plugins::Notify::Request;
$Mason::Test::Plugins::Notify::Request::VERSION = '2.24';
use Mason::PluginRole;

before 'run' => sub {
    my ( $self, $path ) = @_;
    print STDERR "starting request run - $path\n";
};

before 'comp' => sub {
    my ( $self, $path ) = @_;
    print STDERR "starting request comp - $path\n";
};

1;

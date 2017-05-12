use Plack::App::CGIBin;
use Plack::Builder;

my $app = Plack::App::CGIBin->new(root => "cgi-bin/")->to_app;
builder {
    mount "/cgi-bin" => $app;
};

use Net::Trackback::Client;
use Data::Dumper;
my $client = Net::Trackback::Client->new();
my $url ='http://localhost/kwiki/index.cgi?HomePage';
my $data = $client->discover($url);

print Dumper($data);

my $ping_url = $data->[0]->ping;

require Net::Trackback::Ping;
my $p = {
   ping_url => $ping_url,
   url => 'http://www.burningchrome.com/~cdent/mt/archives/000361.html',
   title => 'Some stuff',
   excerpt => $ARGV[0],
   blog_name => 'Glacial Erratics',
};
my $ping = Net::Trackback::Ping->new($p);
my $msg = $client->send_ping($ping);
print Dumper($msg);

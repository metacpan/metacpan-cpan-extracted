##
## This script generates lib/MIME/DB.pm for a given mime-db version
##
use strict;
use warnings;
use JSON::XS qw(decode_json);

# changelog: https://github.com/jshttp/mime-db/releases

my $cmd = join(" ", $0, @ARGV);

my $tag = shift || 'v1.49.0';

$tag = "v$tag" unless $tag =~ /^v/;

print STDERR "mini-db $tag\n";

# my $url = sprintf 'https://raw.githubusercontent.com/jshttp/mime-db/%s/db.json', $tag;
my $url = sprintf 'https://cdn.jsdelivr.net/gh/jshttp/mime-db@%s/db.json', $tag;

print STDERR "getting $url\n";

my $json = `curl -k -f -s $url` || die;

my $db = decode_json($json);
for (values %$db) {
	$_->{compressible} = $_->{compressible} ? 1:0 if exists $_->{compressible};
}

print STDERR "creating lib/MIME/DB.pm\n";

{
	mkdir('lib');
	mkdir('lib/MIME');
	open(my $fh, '>', 'lib/MIME/DB.pm') or die $!;
	printf $fh ("package MIME::DB;\n\$VERSION = '%s';\n# generation date: %s\n# command: %s\n# source url: %s\nuse constant version => '%s';\nsub data { %s }\n1",
		$tag,
		time2isoz(),
		$cmd,
		$url,
		$tag,
		minidump($db)
	);
}

print STDERR "OK\n";

sub minidump {
	require Data::Dumper;
	my $struct = shift;
	no warnings;
	local $Data::Dumper::Deepcopy = 1;
	local $Data::Dumper::Indent = 0;
	my $data = Data::Dumper::Dumper($struct);
	$data =~ s/\s=>\s/=>/g;
	$data =~ s/'([a-zA-A]\w*)'=>/$1=>/g;
	$data =~ s/'=>/',/g;
	$data =~ s/^\$VAR1\s*=\s*//;
	$data =~ s/;$//;
	die if $data =~ /\$VAR1/;
	die if $data =~ /\s/;
	return $data
}

sub time2isoz {
	my ($sec,$min,$hour,$mday,$mon,$year) = defined($_[0]) ? gmtime($_[0]) : gmtime();
	sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year+1900, $mon+1, $mday, $hour, $min, $sec);
}
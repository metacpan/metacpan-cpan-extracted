use strict;
use Session;
use Data::Dump 'dump';

my %session_config = (
	Store      => "MySQL",
	DataSource => "DBI:mysql:streawkceur:localhost",
	UserName   => "streawkceur",
	Password   => "blub23ding42",
	Lock       => 'Null',
	Generate   => 'MD5',
	Serialize  => 'Storable',
);


my $create = 1;
my $session;
if ($create) {
	$session = Session->new(undef, %session_config) or warn 'create error';
	$session->set('test' => 'blub');
	print dump $session;
	my $sid = $session->session_id();
	undef($session);
	my $nsession = Session->new($sid, %session_config) or warn 'ncreate error';
	print dump $nsession;
} else {
	my $SID = 'ca293be27c427843c0328d7cd6a4d848';
	$session = Session->new($SID, %session_config) or warn 'recover error';
}

print $session->get('test');
print dump $session;


#!/usr/bin/perl

use strict;
use Test::More;
use Email::Simple;
use MIME::Base64 qw(encode_base64 decode_base64);
use POSIX qw(strftime setsid :sys_wait_h);
use Mail::SpamAssassin;
use JSON::XS;
use Math::Round qw(nearest round);
use Hash::Util qw(lock_hashref);
use Redis;
use DBI;
use IPTables::ChainMgr;
#use Data::Dumper;

my ($sa, $msg, $email, $status, $debug, $db, $v, $a, $b, $c, $d, %re, %config, $version, $file, $iptables, $ip6tables, $skip_tests);
$debug = '';
$version = 1.2;
#$debug = 'info';
#$debug = 'all';

sub find_bin {
	my $path;
	foreach $path (@{['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin']}){
		return $path.'/'.$_[0] if (-e $path.'/'.$_[0]);
	}
}

sub trim {
	my $str = shift;
	$str =~ s/(?:^[\r\n\t ]+)|(?:[\r\0]+)|(?:[\r\n\t ]+$)//g;
	$str =~ s/^['"]//;
	$str =~ s/[, \t]$//g;
	$str =~ s/['"]$//;
	$str =~ s/#/\\#/;
	return $str;
}

sub db_state {
	return if(!$debug);
	print "\nstore:\n";
	map{print "\t".$_.' => '.$db->get($_)."\n"} @{[$db->keys($_[0].'*')]};
	print "\n";
}

sub db_param {
	my (%dbc, $c);

	%dbc = (db_type=>'redis',db_user=>'',db_name=>'sa_ipf_test',db_auth=>'',db_host=>'127.0.0.1',db_port=>'');

	/()/;
	do{
		diag("\nmysql/redis store [".$dbc{db_type}."]>");
		$c = <STDIN>;
		chomp($c);

	}while($c!~/((?:redis)|(?:mysql))/i && ($c));
	$dbc{db_type} = lc($1) if($1);
	diag("type: ".$dbc{db_type});

	diag("\nhost [127.0.0.1]>");
	$c = <STDIN>;
	chomp($c);
	$dbc{db_host} = $c if($c);
	diag("host: ".$dbc{db_host});

	diag("\nport (example: ".($dbc{db_type}eq'redis'?6379:3306).") []>");
	$c = <STDIN>;
	chomp($c);
	$dbc{db_port} = $c if($c);
	diag("port: ".$dbc{db_port});

	/()/;
	do{
		diag("\n".($dbc{db_type}eq'redis'?'key prefix':'database name')." (^([a-zA-Z0-9_]+)\$) [".$dbc{db_name}."]>");
		$c = <STDIN>;
		chomp($c);

	}while($c!~/^([a-zA-Z0-9_]+)$/ && ($c));
	$dbc{db_name} = lc($1) if($1);
	diag(($dbc{db_type}eq'redis'?'key prefix':'database name').": ".$dbc{db_name});

	if($dbc{db_type} eq 'redis'){
		diag("\nredis auth password []>");
		system(find_bin('stty'), '-echo') if(find_bin('stty'));
		$c = <STDIN>;
		system(find_bin('stty'), 'echo') if(find_bin('stty'));
		chomp($c);
		$dbc{db_auth} = $c if($c);
		diag("password: ".$dbc{db_auth}?'*****':'None');

	}else{
		diag("\ndatabase user []>");
		$c = <STDIN>;
		chomp($c);
		$dbc{db_user} = $c if($c);
		diag("user: ".$dbc{db_user});

		diag("\ndatabase password (not shown) []>");
		system(find_bin('stty'), '-echo') if(find_bin('stty'));
		$c = <STDIN>;
		system(find_bin('stty'), 'echo') if(find_bin('stty'));
		chomp($c);
		$dbc{db_auth} = $c if($c);
		diag("password: ".$dbc{db_auth}?'*****':'None');
	}
	return \%dbc;
}

$dbconnect_mysql::name = 'dbconnect_mysql';

sub dbconnect{
	my ($db,$h,$r,$conf);
	$conf = shift;
	if($conf->{db_type} eq 'redis'){
		$conf->{db_port} = 6379 if(1>int($conf->{db_port}));

		$db = length($conf->{db_auth})>0 ? Redis->new(server => $conf->{db_host}.':'.$conf->{db_port}, password => $conf->{db_auth}) : Redis->new(server => $conf->{db_host}.':'.$conf->{db_port});
		return ($db=0) if (!$db->ping);
	}elsif($conf->{db_type} eq 'mysql'){

		fatal('Could not establish connection to mysql:'. $DBI::errstr) if (!($db = DBI->connect('DBI:mysql::'.(0<int($conf->{db_port})?'@'.$conf->{db_host}.':'.$conf->{db_port}:'localhost'), $conf->{db_user}, $conf->{db_auth}, {PrintError => 1})));

		$db->{PrintError} = 0;
		($db->do('create database if not exists '.$conf->{db_name}) && $db->do('use '.$conf->{db_name})) if (!$db->do('use '.$conf->{db_name}));
		$db->do('create table if not exists `'.$conf->{db_name}.'`.`ent` (k varchar(128) NOT NULL,v TEXT NOT NULL,modified timestamp NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP, PRIMARY KEY (k(128))) ENGINE=InnoDB DEFAULT CHARSET=utf8') if(!$db->do('select 1 from '.$conf->{db_name}.'.ent limit 1'));
		$db->{PrintError} = 1;
		$db = sub { my $self = { db => $db }; bless $self, *dbconnect_mysql; return $self; }->();

	}
	return $db;
}

sub dbconnect_mysql::get {
	my ($h,$r,$db);
	$db = (shift)->{db};
	#$k =~ tr/\x00-\x09\x0b\x0c\x0e-\x1f//d;
	$h = $db->prepare(sprintf('select v from ent where k=%s limit 1', length($_[0]) >0 ? $db->quote($_[0]) : "''"));
	$h->execute();
	$r = $h->fetchrow_hashref('NAME_lc');
	$h->finish();
	return ((defined $r) && $r && ($r->{v})) ? $r->{v} : '';
}

sub dbconnect_mysql::set {
	my ($v,$r,$db);
	$db = (shift)->{db};
	$v = length($_[1]) >0 ? $db->quote($_[1]) : "''";
	$db->do(sprintf('insert into ent (k, v) values (%s, %s) on duplicate key update v=%s', length($_[0]) >0 ? $db->quote($_[0]) : "''", $v, $v));
}

sub dbconnect_mysql::keys {
	my ($h,$db,@o,$v);
	$db = (shift)->{db};
	@o = ();
	$v=shift;
	$v=~s/\*/\%/g;
	$h = $db->prepare(sprintf('select k from ent where k like %s limit 256000',length($v) >0 ? $db->quote($v) : "''"));
	$h->execute();
	map { push @o, $_->{k} } @{$h->fetchall_arrayref({})};
	$h->finish();
	return @o;
}

sub dbconnect_mysql::del {
	my $db = (shift)->{db};
	$db->do(sprintf('delete from ent where k=%s limit 1', length($_[0]) >0 ? $db->quote($_[0]) : "''"));
}

sub dbconnect_mysql::quit {
		my $db = (shift)->{db};
		$db->disconnect if($db);
}

sub dbconnect_mysql::AUTOLOAD {
		my ($self, @args, $name);
		$name = $dbconnect_mysql::AUTOLOAD;
		($self, @args) = @_;
		return;
}

$skip_tests = '';
sub check_skip_tests {

	do{
                diag("\n\n############################### WARNING ####################################");
                diag("\n\nThe required kernel module 'iptable-filter' is not loaded on this system.");
                diag("\nI can try to load this module for you (a=auto), you may skip the tests that");
                diag("\ndepend on 'iptable-filter' (s=skip), or you may quit and rerun this");
		diag("\ninstallation after manually loading the module yourself (q=quit).");                
                diag("\n\nMail::SpamAssassin::Contrib::Plugin::IPFilter will not function properly");
                diag("\nwithout 'iptable-filter' loaded. Ensure that it is loaded at startup.");
                diag("\n\n############################################################################");

		diag("\n\n[a/s/q]>");
		$c = <STDIN>;
		chomp($c);

	}while($c!~/^[\t ]*([aqs])/i && ($c));

	$c = lc($1);
	if($c eq 'q'){
		done_testing();
		exit;
	}elsif($c eq 's'){
		$skip_tests = 1;
		return 0;
	}
	return 1;
}

$c = '';
foreach $file (@INC){
	if($file=~/^(.*\/lib)\/?$/ && -e $1.'/Mail/SpamAssassin/Contrib/Plugin/IPFilter.pm'){
		$c = $file;
		$c=~s/\/$//g;
		$c .='/Mail/SpamAssassin/Contrib/Plugin/IPFilter.pm';
		open(FILE, $c) || die "Could not open $c ($!)\n";
		$d = do { local $/; <FILE> };
		close(FILE);

		next if($d !~ /\$VERSION[ \t]*=[ \t]*\Q$version\E[ .0\t]*;/);
		#$a =~ s/^.*?sub[ \t]+compile\_regex//ism;
		#$a =~ s/\);.*$//sm;
		#map{ index($_,'=>')>0 && $_=~/^[ \t'"]*([^ \t'"]+)[ \t'"]*=>[ \t'"]*qr\/(.*)\/['" \t,]*$/ && ($re{trim($1)}=qr/$2/)} split("\n", trim($a));
		$d =~ s/^.*?sub[ \t]+get\_config[ \t]*\{.*?return[ \t]*\{[ \t\r\n]*//ism;
		$d =~ s/\};.*$//sm;
		map{ $_=~/^[ \t'"]*([^ \t'"]+)[ \t'"]*=>[ \t'"]*(.*?)['" \t,]*$/ && ($config{trim($1)}=trim($2))} split("\n", trim($d));
		last;
	}
}

$file = $c;
if(!$file){
	warn('Could not find Mail/SpamAssassin/Contrib/Plugin/IPFilter.pm in @INC!');
	done_testing();
	exit;
}

if(($a = find_bin('modprobe')) && ($b = find_bin('lsmod'))){
	$skip_tests = $> == 0 ? `$a -a ip_tables iptable-filter 2>&1` : `sudo $a -a ip_tables iptable-filter 2>&1` if(`$b 2>&1` !~ /iptable[s\-_ ]+filter/i && check_skip_tests());
	$skip_tests =~ s/[ \r\n\t]//g;
}else{
	$skip_tests = 1;
}

while(($c = db_param()) && !($db = dbconnect($c))){
	diag("\nCould not connect to ".$c->{db_type}.". Please try again.\n");
}

map {$config{$_}=$c->{$_}} keys %{$c};

$config{blacklist_score} = int($config{blacklist_score})>0 ? int($config{blacklist_score}) : 30;
$config{average_score_for_rule} = (exists $config{average_score_for_rule} && 0<int($config{average_score_for_rule})) ? int($config{average_score_for_rule})+2 : 8;
$config{trigger_score} = (exists $config{trigger_score} && 0<int($config{trigger_score})) ? int($config{trigger_score}) : 6;
$config{trigger_messages} = (exists $config{trigger_messages} && 0<int($config{trigger_messages})) ? int($config{trigger_messages}) : 3;
$config{seconds_between_messages} = 0.99;

$config{iptables_support} = 0;
$config{filter_name}.='test';

#x tests planned but only y executed?
if(!$skip_tests){

	$config{iptables_support} = 4;

	$config{iptables_bin} = find_bin('iptables') ? find_bin('iptables') : $config{iptables_bin};
	ok($config{iptables_bin}, 'Found iptables binary') || die('Could not find iptables binary');
	$config{ip6tables_bin} = find_bin('ip6tables') ? find_bin('ip6tables') : $config{ip6tables_bin};
	$config{ip6tables_bin} = '' if(-e $config{ip6tables_bin});

	$config{iptables_lockfile} = -d '/var/lock' ? '/var/lock/spamipfilter' : ((-d '/tmp') ? '/tmp/spamipfilter.lock' : './spamipfilter') if(!$config{iptables_lockfile});

	$b = 0;
	$iptables = IPTables::ChainMgr->new(ipt_bin_name => $config{iptables_bin}, use_ipv6 => 0, ipt_rules_file => '', iptout => '', ipterr => '', debug => 0, verbose => 0, ipt_alarm => 5, ipt_exec_style => 'popen', ipt_exec_sleep => 0);
	$iptables->{'parse_obj'}->{'_lockless_ipt_exec'} = 0 if($iptables && $iptables->{'parse_obj'} && $iptables->{'parse_obj'}->{'_lockless_ipt_exec'});

	($a, $b, $c) = $iptables->chain_exists('filter', $config{filter_name});
	(($iptables->create_chain('filter', $config{filter_name})) xor ($iptables->add_jump_rule('filter', 'INPUT', 4, $config{filter_name}))) if($a!=1);
	ok((($a, $b, $c) = $iptables->chain_exists('filter', $config{filter_name})) && $a==1, 'chain '.$config{filter_name}.' exists');

	if($config{ip6tables_bin}){

		$config{iptables_support} = 6;

		$b = 0;
		$ip6tables = IPTables::ChainMgr->new(ipt_bin_name => $config{ip6tables_bin}, use_ipv6 => 1, ipt_rules_file => '', iptout => '', ipterr => '', debug => 0, verbose => 0, ipt_alarm => 5, ipt_exec_style => 'popen', ipt_exec_sleep => 0);
		$ip6tables->{'parse_obj'}->{'_lockless_ipt_exec'} = 0 if($ip6tables && $ip6tables->{'parse_obj'} && $ip6tables->{'parse_obj'}->{'_lockless_ipt_exec'});

		($a, $b, $c) = $ip6tables->chain_exists('filter', $config{filter_name});
		(($ip6tables->create_chain('filter', $config{filter_name})) xor ($ip6tables->add_jump_rule('filter', 'INPUT', 4, $config{filter_name}))) if($a!=1);
		ok((($a, $b, $c) = $ip6tables->chain_exists('filter', $config{filter_name})) && $a==1, 'chain '.$config{filter_name}.' exists');
	}
}

$c = '';
map {$c.="ipfilter_$_ ".trim($config{$_})."\n"} keys %config;

map{$db->del($_)} @{[$db->keys($config{db_name}.'*')]};
$sa = Mail::SpamAssassin->new({debug=>$debug, local_tests_only=>1, config_text=>"required_score ".$config{trigger_score}."\nheader IPFSPAM Subject =~ /ipfilter\\_spam/i\nscore IPFSPAM ".$config{average_score_for_rule}."\nheader IPFHAM Subject =~ /ipfilter\\_ham/i\nscore IPFHAM 1\nloadplugin Mail::SpamAssassin::Plugin::Check\nloadplugin Mail::SpamAssassin::Contrib::Plugin::IPFilter\n".$c});


$c = strftime('%a, %e %b %Y %H:%M:%S +0000 (UTC)', gmtime);
$c =~ s/[^a-z0-9 +\-():]/ /ig;
$msg = Email::Simple->create(
	header => [
		From    => 'root@localhost.localdomain',
		To      => 'root@localhost.localdomain',
		Subject => '<ipfilter_spam>',
		Received => 'from localhost.localdomain (localhost.localdomain [198.51.100.1])     by mail.localhost.localdomain (Postfix) with ESMTPS id 9FF9F90090F     for <root@localhost.localdomain>; '.$c,
	],
	body => '...',
)->as_string;

db_state($config{db_name});

$status = $sa->check_message_text($msg);
db_state($config{db_name});
$v = $db->get($config{db_name}.'-198.51.100.1') || '';

/()/;
ok($v =~ /^([0-9.]+),([0-9.]+),1,([0-9]+),(.*)$/, 'Found record for {'.$config{db_name}.'-198.51.100.1} : '.$v);
$a = $b = 0;
if(($1)&&($2)){
	$v = $1.','.$2.',1,'. ($3 - 200) .','.$4;
	$a = $1 + 0.0;
	$b = $2 + 0.0;
	$db->set($config{db_name}.'-198.51.100.1' => $v);
}

db_state($config{db_name});
sleep(1);
$status = $sa->check_message_text($msg);
$v = $db->get($config{db_name}.'-198.51.100.1') || '';

/()/;
ok($v =~ /^([0-9.]+),([0-9.]+),2,([0-9]+),(.*)$/, 'Found updated record for {'.$config{db_name}.'-198.51.100.1} : '.$v);
$c = $d = -1;
if(($1)&&($2)){
	$c = $1 + 0.0;
	$d = $2 + 0.0;
}
ok($c>$a && $d>$b, 'Record {'.$config{db_name}.'-198.51.100.1} correctly updated on receipt of second spam msg : '."$c>$a && $d>$b");
db_state($config{db_name});

sleep(1);
$status = $sa->check_message_text($msg);
$v = $db->get($config{db_name}.'-198.51.100.1') || '';

/()/;
ok($v =~ /^([0-9.]+),([0-9.]+),3,([0-9]+),(.*)$/, 'Found updated record for {'.$config{db_name}.'-198.51.100.1 : '.$v);
$c = $d = -1;
if(($1)&&($2)){
	$c = $1 + 0.0;
	$d = $2 + 0.0;
}
db_state($config{db_name});

sleep(1);
$msg =~ s/<ipfilter_spam>/<ipfilter_ham>/i;
$status = $sa->check_message_text($msg);
db_state($config{db_name});
$v = $db->get($config{db_name}.'-198.51.100.1') || '';

/()/;
ok($v=~/^([0-9.]+),([0-9.]+),[23],([0-9]+),(.*)$/, 'Found updated record for {'.$config{db_name}.'-198.51.100.1} : '.$v);
$a = $b = 0;
if(($1)&&($2)){
	$a = $1 + 0.0;
	$b = $2 + 0.0;
}
ok($c>$a && $d>$b, 'Record {'.$config{db_name}.'-198.51.100.1} correctly updated on receipt of ham msg : '."$c>$a && $d>$b");

$msg =~ s/<ipfilter_ham>/<ipfilter_spam>/i;
map{sleep(1) xor $sa->check_message_text($msg)} (3..($config{trigger_messages}+2));

$v = $db->get($config{db_name}.';expires-198.51.100.1') || '';
ok($v =~ /^([0-9]+)$/, 'Found expires record for {'.$config{db_name}.';expires-198.51.100.1} : '.$v);

if(!$skip_tests){
	$iptables->flush_chain('filter', $config{filter_name});
	sleep(1);
	$ip6tables->flush_chain('filter', $config{filter_name}) if($config{ip6tables_bin});
}

sleep(1);
system(find_bin('echo').' "IPFilterUpdate '.encode_base64(JSON::XS->new->utf8->encode(\%config), '').'" | '.$^X.' '.$file);
sleep(2);

if(!$skip_tests){
	$v = '';
	(undef, $b, undef) = $iptables->run_ipt_cmd($config{iptables_bin}. ' -L '.$config{filter_name});
	$v = join('', @{$b}) if($b && ${$b}[1]);
	ok($v =~ /198\.51\.100\.1/,'IPTables rule for 198.51.100.1 set') || warn($v);
}

$v = $db->get($config{db_name}.'-198.51.100.1') || '';

/()/;
ok($v =~ /^([0-9.]+,[0-9.]+,)[0-9]+,([0-9]+),(.*)$/, 'Found updated record for {'.$config{db_name}.'-198.51.100.1} : '.$v);
if(($1)&&($2)){
	$a = time() - 7200;
	$v = $1.',1,'. $a .','.$3;
	$db->set($config{db_name}.';expires-198.51.100.1' => $a);
	$db->set($config{db_name}.'-198.51.100.1' => $v);
}

if(!$skip_tests){
	$iptables->flush_chain('filter', $config{filter_name});
	sleep(1);
	$ip6tables->flush_chain('filter', $config{filter_name}) if($config{ip6tables_bin});
	sleep(1);

	$iptables->run_ipt_cmd($config{iptables_bin}.' -t filter -I '.$config{filter_name}.' -i eth+ -s 198.51.100.1 -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.$a.'\'');
	sleep(1);
	$ip6tables->run_ipt_cmd($config{ip6tables_bin}.' -t filter -I '.$config{filter_name}.' -i eth+ -s ::ffff:198.51.100.1/128 -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.$a.'\'')  if($config{ip6tables_bin});
}

sleep(1);

system(find_bin('echo').' "IPFilterUpdate '.encode_base64(JSON::XS->new->utf8->encode(\%config), '').'" | '.$^X.' '.$file);
sleep(2);

if(!$skip_tests){
	(undef, $b, undef) = $iptables->run_ipt_cmd($config{iptables_bin}. ' -L '.$config{filter_name});
	$v = join('', @{$b}) if($b && ${$b}[1]);
	ok($v !~ /198\.51\.100\.1/,'IPTables rule for 198.51.100.1 cleared') || warn($v);
}

$v = $db->get($config{db_name}.';expires-198.51.100.1') || '';
ok(!$v, $config{db_name}.';expires-198.51.100.1 cleared : '.$v);

$c = strftime('%a, %e %b %Y %H:%M:%S +0000 (UTC)', gmtime);
$c =~ s/[^a-z0-9 +\-():]/ /ig;
$msg = Email::Simple->create(
        header => [
                From    => 'ipfiltertest_42@gmail.com',
                To      => 'root@localhost.localdomain',
                Subject => '<ipfilter_ham>',
                Received => 'from test.google.com (test.google.com [198.51.100.2])     by mail.localhost.localdomain (Postfix) with ESMTPS id 9FF9F90090F     for <root@localhost.localdomain>; '.$c,
        ],
        body => '...',
)->as_string;

$status = $sa->check_message_text($msg);
db_state($config{db_name});

sleep(2);

$msg =~ s/<ipfilter_ham>/<ipfilter_spam>/i;
$status = $sa->check_message_text($msg);

$v = $db->get($config{db_name}.'-'.encode_base64('ipfiltertest_42','').'@gmail.com') || '';
ok($v =~ /^([0-9.]+,[0-9.]+,[0-9]+),([0-9]+),198\.51\.100\.2$/, $config{db_name}.'-ipfiltertest_42@gmail.com set : '.$v);

db_state($config{db_name});

$c = int($status->get_score());
ok($c < $config{blacklist_score}, 'ipfiltertest_42@gmail.com spam not blacklisted');

map{sleep(1) xor ($status=$sa->check_message_text($msg))} (1..($config{trigger_messages}+2));

$v = $db->get($config{db_name}.';expires-'.encode_base64('ipfiltertest_42','').'@gmail.com') || '';
ok($v =~ /^[0-9]+$/ && time()<int($v), 'Found record for {'.$config{db_name}.';expires-ipfiltertest_42@gmail.com} : '.$v);

$c = int($status->get_score());
ok($c >= $config{blacklist_score}, 'ipfiltertest_42@gmail.com spam blacklisted');
db_state($config{db_name});

$v = $db->get($config{db_name}.'-'.encode_base64('ipfiltertest_42','').'@gmail.com') || '';
/()/;
ok($v =~ /^([0-9.]+,[0-9.]+,)[0-9]+,([0-9]+),(.*)$/, 'Found record for {'.$config{db_name}.'-ipfiltertest_42@gmail.com} : '.$v);
if(($1)&&($2)){
        $a = time() - 7200;
        $v = $1.',1,'. $a .','.$3;
        $db->set($config{db_name}.';expires-'.encode_base64('ipfiltertest_42','').'@gmail.com' => $a);
        $db->set($config{db_name}.'-'.encode_base64('ipfiltertest_42','').'@gmail.com' => $v);
}


db_state($config{db_name});

sleep(2);
system(find_bin('echo').' "IPFilterUpdate '.encode_base64(JSON::XS->new->utf8->encode(\%config), '').'" | '.$^X.' '.$file);
sleep(2);

$status = $sa->check_message_text($msg);
$c = int($status->get_score());
ok($c < $config{blacklist_score}, 'ipfiltertest_42@gmail.com spam not blacklisted');

db_state($config{db_name});

$sa->finish();
$db->quit;

done_testing();

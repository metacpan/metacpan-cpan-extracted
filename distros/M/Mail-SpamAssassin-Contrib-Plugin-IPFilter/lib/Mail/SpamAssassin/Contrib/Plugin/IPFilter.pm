package Mail::SpamAssassin::Contrib::Plugin::IPFilter;

# ABSTRACT: Blocks bad MTA behavior using IPTables.

# <@LICENSE>
#
# Copyright 2016 Tamer Rizk, Inficron Inc. <foss[at]inficron.com>
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#   * Neither the name of Tamer Rizk, Inficron Inc, nor the names of its
#     contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# </@LICENSE>

# Author:  Tamer Rizk <foss[at]inficron.com>


use strict;
use Cwd;
use DBI;
use Redis;
use Date::Parse;
use JSON::XS;
use Mail::SpamAssassin;
use MIME::Lite;
use Sys::SigAction qw( timeout_call );
use MIME::Base64 qw(encode_base64 decode_base64);
use Math::Round qw(nearest round);
use Hash::Util qw(lock_hashref);
use Fcntl qw(:flock SEEK_END SEEK_SET);
use POSIX qw(strftime);
use IPTables::ChainMgr;
use Config::Crontab;
use Text::Document;
use Lingua::StopWords qw( getStopWords );
use Storable qw(freeze thaw);

#use Data::Dumper;
use vars qw($VERSION @ISA);
my ($Verbose, %Regex, $Logfile, %Cronjobs);
$Verbose = 1;

$VERSION = 1.2;

#stub
sub p2p {
	#Roughly: After some history of a user trading messages with another user, that network becomes a candidate. Agree to share blocklist on new well known port for this service if both consider each other candidates. A number of those agreeing on any given block, append the entry to local as an unsharable entry. Limit network user density from effecting operation. Extend to other firewalls/platforms.
}

sub inform {
	return if ($Verbose != 1);
	sub_exists('info') ? info('IPFilter: '.$_[0]) : warn('IPFilter: '.$_[0]);
}

sub error {
	info('IPFilter: '.$_[0]) if(sub_exists('info'));
	warn('IPFilter: '.$_[0]);
	return 0;
}

sub fatal {
	error($_[0]);
	exit;
}

sub find_bin {
	my $path;
	foreach $path (@{['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin']}){
		return $path.'/'.$_[0] if (-e $path.'/'.$_[0]);
	}
}

sub sub_exists {
	no strict 'refs';
	return defined &{$_[0]} ? 1 : 0;
}

$dbconnect_mysql::name = 'dbconnect_mysql';

sub dbconnect{
	my ($db,$conf);
	$conf = shift;
	if($conf->{db_type} eq 'redis'){
		$conf->{db_port} = 6379 if(1>int($conf->{db_port}));
		$db = length($conf->{db_auth})>0 ? Redis->new(server => $conf->{db_host}.':'.$conf->{db_port}, password => $conf->{db_auth}) : Redis->new(server => $conf->{db_host}.':'.$conf->{db_port});
		fatal('Could not establish connection to redis') if (!$db->ping);
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

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::exists {
				my ($h,$r,$db);
				$db = (shift)->{db};
				$h = $db->prepare(sprintf('select k from ent where k=%s limit 1', length($_[0]) >0 ? $db->quote($_[0]) : "''"));
				$h->execute();
				$r = $h->fetchrow_hashref('NAME_lc');
				$h->finish();
				return ((defined $r) && $r && (exists $r->{k})) ? 1 : 0;
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::get {
	my ($h,$r,$db);
	$db = (shift)->{db};
	#$k =~ tr/\x00-\x09\x0b\x0c\x0e-\x1f//d;
	$h = $db->prepare(sprintf('select v from ent where k=%s limit 1', length($_[0]) >0 ? $db->quote($_[0]) : "''"));
	$h->execute();
	$r = $h->fetchrow_hashref('NAME_lc');
	$h->finish();
	return ((defined $r) && $r && (defined $r->{v})) ? $r->{v} : '';
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::set {
	my ($v,$r,$db);
	$db = (shift)->{db};
	$v = length($_[1]) >0 ? $db->quote($_[1]) : "''";
	$db->do(sprintf('insert into ent (k, v) values (%s, %s) on duplicate key update v=%s', length($_[0]) >0 ? $db->quote($_[0]) : "''", $v, $v));
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::mget {
	my ($h,@k,@o,$db);
	$db = (shift)->{db};
	@o = ();
	map{ push @k, (length($_) >0 ? $db->quote($_) : "''") } @_;
	return @o if(@k==0);
	$h = $db->prepare('select v from ent where k in ('.join(', ',@k).') order by field(k, '.join(', ',@k).') limit '.int(@k+0));
	$h->execute();
	map { push @o, $_->{v} } @{$h->fetchall_arrayref({})};
	$h->finish();
	return @o;
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::keys {
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
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::del {
	my $db = (shift)->{db};
	$db->do(sprintf('delete from ent where k=%s limit 1', length($_[0]) >0 ? $db->quote($_[0]) : "''"));
};

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::quit {
		my $db = (shift)->{db};
		$db->disconnect if($db);
}

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::AUTOLOAD {
		my ($self, @args, $name);
		$name = $dbconnect_mysql::AUTOLOAD;
		($self, @args) = @_;
		return 0;
}

sub Mail::SpamAssassin::Contrib::Plugin::IPFilter::dbconnect_mysql::DESTROY {
		my $db = (shift)->{db};
		$db->disconnect if($db);
}

sub c_param {
	fatal('[c_params]: missing conf') if (!$_[0]);
	my $conf = JSON::XS->new->utf8->decode(decode_base64($_[0]));
	fatal('[c_params]: Invalid number of params '.join(',', keys %{$conf})) if (int(split('\x7C', sprintf('%s',$Regex{param}))) > int(keys %{$conf}));

	re_config($conf);
	$conf->{re} = \%Regex;
	return $conf;
}

sub c_logfile {
	fatal('[c_logfile] Could not find log dir '.$_[0]->{log_dir}) if (!$_[0]->{log_dir} || !-d $_[0]->{log_dir});
	$Logfile = $_[0]->{log_dir}.'/spamipfilter_'.strftime('%d-%m-%Y', localtime);
	if(!-e $Logfile){
		lock($Logfile);
		fatal('[c_logfile] Could not create log file '.$Logfile) if(!open(IPFILTERLOGSTATS, '+>>'.$Logfile));
		close(IPFILTERLOGSTATS);
		chmod(0600, $Logfile);
		chown(int($1),-1, $Logfile) if ($_[0]->{username} && getpwnam($_[0]->{username})=~/^([0-9]+)$/);
	}
}

sub c_ipfilter_update {

	my ($conf, @buffer, $db, $expires, $iptables, $sa);

	$expires = time();
	$conf = c_param(shift);

	$sa = Mail::SpamAssassin->new($conf);

	@buffer = iptables_cmd('-L '.$conf->{filter_name}.' -n -v -x', $conf);
	$iptables = join('', @{$buffer[1]}) if(@buffer && defined $buffer[1] && @{$buffer[1]});

	$db = dbconnect($conf);
	if($conf->{admin_email}){
		@buffer = localtime();
		clean_notifications($db, {conf => $conf}) if ($buffer[6]==6 && $buffer[2]==2);
		notify_blacklist($db, {conf => $conf});
	}
	refresh_iptables($db, {conf => $conf, iptables => $iptables});
	refresh_list($db, {conf => $conf, mailsa => $sa});
	$db->quit;

	map{ (@buffer = $_ =~ $conf->{re}->{expires}) && ($buffer[0]) && ($buffer[0]=sanitize($buffer[0], $conf->{re}->{ipn}, '198.51.100.0')) && $expires > int($buffer[1]) && iptables_cmd('-t filter -D '.$conf->{filter_name}.' -i eth+ -s '.$buffer[0].' -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.int($buffer[1]).'\'', $conf) && iptables_cmd('-t filter -D '.$conf->{filter_name}.' -i eth+ -s '. ip6tables_normalize((index($buffer[0],'/')==-1?expand_ipv6($buffer[0]):expand_ipv6( shift @{[split('/',$buffer[0])]} ).'/'.cidr_16( pop @{[split('/',$buffer[0])]} )), $conf) .' -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.int($buffer[1]).'\'', $conf, 6) } split("\n", $iptables);

	exit;
}

sub c_maintenance {

	my ($conf, $db);
	$conf = c_param(shift);
	$db = dbconnect($conf);
	op_rkeys('-*', \&cache_decay_op, $db, { conf => $conf, cache_decay_secs => $conf->{cache_decay_days}*86400, trigger_messages => $conf->{trigger_messages}+0, average_score_for_rule => $conf->{average_score_for_rule}+0 });
	$db->quit;
	exit;
}

sub c_log_format {

	my (@data, $conf);
	$conf = c_param(shift);

	fatal('[c_log_format] Could not read log dir: '.$conf->{log_dir}) if (!$conf->{log_dir} || !-d $conf->{log_dir});

	$data[0] = 0;
	if(opendir(IPFILTERLOGDIR, $conf->{log_dir})){
					map{ $_ =~ /spamipfilter\_([0-9]+)\-([0-9]+)\-(2[0-9][0-9][0-9])/i && ($data[1]=int(str2time($2.'/'.$1.'/'.$3))) && ($data[0]<$data[1]) && ($data[0]=$data[1]) && ($Logfile=$conf->{log_dir}.'/'.$_) } readdir IPFILTERLOGDIR;
		closedir(IPFILTERLOGDIR);
	}
	inform('[c_log_format] '.$Logfile);
	if($Logfile && -e $Logfile && index($Logfile, $conf->{log_dir}.'/spamipfilter')==0 && index(substr($Logfile,0,len($Logfile)+1),'/')==-1){
		lock($Logfile);
		rename($Logfile, $conf->{log_dir}.'/.'. pop @{[split('/', $Logfile)]});
	}
	c_logfile($conf);

	exit;
}

sub c_log_piwik {
	my (@data, $conf);

	$conf = c_param(shift);
	fatal('[c_log_piwik] Could not find piwik host or path: '.$conf->{piwik_host}.' '.$conf->{piwik_path}) if (!$conf->{piwik_host} || !$conf->{piwik_path} || !-d $conf->{piwik_path} || !$conf->{log_dir});

				if(opendir(IPFILTERLOGDIR, $conf->{log_dir})){
								@data = grep /\.spamipfilter\_[0-9]+\-[0-9]+\-2[0-9][0-9][0-9]$/i, readdir IPFILTERLOGDIR;
								closedir(IPFILTERLOGDIR);
				}
	exit if (@data<1 || !find_bin('python'));
	map{system(find_bin('python').' '.$conf->{piwik_path}.'/misc/log-analytics/import_logs.py -d --url=\''.$conf->{piwik_host}.'\' --idsite='.$conf->{piwik_idsite}.' --recorders=4 --enable-http-errors --enable-http-redirects --enable-static --enable-bots '.$conf->{log_dir}.'/'.$_.' >> '.$conf->{log_dir}.'/import_logs.py.'.strftime('%m-%Y', localtime).'.log 2>&1')==0 && index($_, '.spamipfilter')==0 && index($_, '/')==-1 && unlink($conf->{log_dir}.'/'.$_)} @data;
	exit;
}

sub log_stats {
	return if(!$Logfile);
	my $s = shift;

	{
		lock($Logfile);
		if (!-e $Logfile){
			$Logfile = substr($Logfile,0,rindex($Logfile,'/')+1).'spamipfilter_'.strftime('%d-%m-%Y', localtime);
			select(undef, undef, undef, int(rand(24) + 8)/128);
			lock($Logfile);
			return if(!-e $Logfile);
			close(IPFILTERLOGSTATS) if(defined fileno(IPFILTERLOGSTATS));
			return if(!open(IPFILTERLOGSTATS, '>>'.$Logfile));
		}
		return if(!defined fileno(IPFILTERLOGSTATS) && !open(IPFILTERLOGSTATS, '>>'.$Logfile));
	}

	timeout_call( 10 ,sub {
		return if(!flock(IPFILTERLOGSTATS, LOCK_EX) || !seek(IPFILTERLOGSTATS, 0, SEEK_END));
		print IPFILTERLOGSTATS $s."\n";
		error('[log_stats] Could not unlock log file '.$Logfile) if(!flock(IPFILTERLOGSTATS, LOCK_UN));
	});

}

sub finish {
	close(IPFILTERLOGSTATS) if(defined fileno(IPFILTERLOGSTATS));
	close(IPTABLESLOCKFILE) if(defined fileno(IPTABLESLOCKFILE));
	close(IPFILTERCACHELOCK) if(defined fileno(IPFILTERCACHELOCK));
}

# Thanks to the authors of Net::IP: Manuel Valente, Monica Cortes Sack,
# and Lee Wilmot for the implementation concepts behind expand_ipv6()
sub expand_ipv6 {
	my ($a, $b, $c, $i, @d, @ip, $addr);
	$addr = shift;

	$addr =~ s/::/: :/g;
	@ip = split('\:', $addr);

	$c = $a = int(@ip + 0);
	for($i=-1;++$i<$a;){
		if(index($ip[$i], '.')!=-1){
			$b = unpack('B32', pack('C4C4C4C4', split('\.', $ip[$i])));
			$ip[$i] = substr(join(':', unpack('H4H4H4H4H4H4H4H4', pack('B128', '0' x (128 - length($b)) . $b))), -9);
			++$c;
			next;
		}
		$ip[$i] = ('0' x (4 - length($ip[$i]))) . $ip[$i];
	}

	@d = ('0000','0000','0000','0000','0000','0000','0000','0000');

	return (index($addr,'.')!=-1?'0:0:0:0:0:ffff:':'').join(':', (map{ $_ eq '000 ' ?  join(':', @d[0 .. (8 - $c)]) : lc($_) } @ip));
}

sub cidr_2 {
	my (@octet, $ipv6, $cidr);
	(@octet, $ipv6) = @_;
	$cidr = $ipv6 ? 128 : 32;
	while(0!=($octet[0] ^ $octet[1])){
		$octet[0] = $octet[0] >> 1;
		$octet[1] = $octet[1] >> 1;
		--$cidr;
	}
	return $cidr;
}

sub cidr_16 {
	return ($_[0]>-1 && $_[0]<33) ? (128-(32-$_[0])) : 128;
}

sub network_octet {
	# (octet, cidr) = @_
	return $_[2] ? sprintf('%02x', hex($_[0]) & (256 - (1<<(128-$_[1])))) : $_[0] & (256 - (1<<(32-$_[1])));
}

sub consolidate_network {
	my (%var, $cidr, $pre, $conf, $db, $params);
	($db, $params) = @_;

	$conf = $params->{conf};

	$pre = $params->{ip}.$params->{host};
	$params->{cidr}  = 32;
	$var{$pre} = int($params->{host});
	if($params->{ipv6}){
		$params->{cidr}  = 128;
		$var{$pre} = hex($params->{host});
	}

	map{$_=~$conf->{re}->{ipfromkey} && ($var{$1.$2} = ($params->{ipv6}) ? hex($2):int($2))} @{[$db->keys($conf->{db_name}.'-'.$params->{ip}.'*')]};
	$cidr = int( cidr_2(  @var{@{[sort { $var{$a} <=> $var{$b} } keys(%var)]}[0,-1]}, $params->{ipv6} ));
	$params->{host} = network_octet($params->{host}, $cidr, $params->{ipv6});
	$params->{network} = int($db->get($conf->{db_name}.';network-'.$params->{ip}.$params->{host}) || $params->{cidr});

	#an edge case may exist due to concurrency where multiple IPs within the same network overwrite one another
	if($cidr < $params->{cidr}){

		$pre = $params->{ip}.$params->{host};

		if($cidr < $params->{network}){
			%var = (def => {%{$params->{def_var}}, expires => 0});
			map{ $var{def} = { avg => 0<($var{def}->{avg}+0.0) ? ($var{def}->{avg} + $_->{avg})/2 : $_->{avg}, total => $var{def}->{total} + $_->{total}, spamhits => $var{def}->{spamhits} + $_->{spamhits}, lastspam => int($var{def}->{lastspam})>int($_->{lastspam}) ? $var{def}->{lastspam} : $_->{lastspam}, expires => int($var{def}->{expires})>int($_->{expires}) ? $var{def}->{expires} : $_->{expires} } } @{[ op_rkeys('-'.$params->{ip}.'*', \&consolidate_network_op, $db, {def_var => $params->{def_var}, conf => $conf}) ]};

			$db->set($conf->{db_name}.';network-'.$pre => $cidr);
			$db->set($conf->{db_name}.'-'.$pre => $var{def}->{avg}.','.$var{def}->{total}.','.$var{def}->{spamhits}.','.$var{def}->{lastspam}.','.$params->{sender});
			$db->set($conf->{db_name}.';expires-'.$pre => $var{def}->{expires}) if(int($var{def}->{expires})>0);
		}
	}
	return $pre;
}

sub op_rkeys {
	my ($n, $i, $c, @buffer, @acc, $re, $pattern, $code, $db, $params);
	($pattern, $code, $db, $params) = @_;

	$re = $params->{conf}->{re};

	@buffer = @{[$db->keys($params->{conf}->{db_name}.$pattern)]};

	$n = int(@buffer + 0);
	while(0!=$n%4){
		push @buffer, '';
		++$n;
	}

	for($i=0; $i<$n; $i+=4){
		$c = -1;
		map { push @acc, $code->($buffer[$i + ++$c], $_, $db, $params) } @{[$db->mget( grep /$re->{alnumchar}/, @{[@buffer[$i..($i+3)]]} )]};
	}

	return @acc;
}

sub op_batch {
	my ($n, $i, $c, @acc, $re, $buffer, $code, $params);
	($buffer, $code, $params) = @_;

	$re = $params->{conf}->{re};

	$n = int(@$buffer + 0);
	while(0!=$n%4){
		push @$buffer, '';
		++$n;
	}

	for($i=0; $i<$n; $i+=4){
		$c = -1;
		push @acc, $code->(\@{[ grep /$re->{alnumchar}/, @{[@$buffer[$i..($i+3)]]} ]}, $params);
	}

	return @acc;
}

sub tr_ascii {
	grep tr/\x00-\x09\x0b\x0c\x0e-\x1f\x7f-\xff//d, @_;
	return @_ == 1 ? $_[0] : @_;
}

sub sanitize {
	my ($var, $re, $def) = @_;
	$def = '' if (!defined $def);
	$var =~ tr/\x00-\x09\x0b\x0c\x0e-\x1f\x7f-\xff//d;
	return $var =~ $re ? $1 : ($def ? sanitize($def, $re) : '');
}

sub iptables_mgr {
	my ($iptables, @res, $ipv6);
	$ipv6 = (defined $_[1] && $_[1] == 6) ? 1 : 0;
	return 0 if($_[0]->{iptables_support}==0 || ($ipv6 && $_[0]->{iptables_support}!=6));
	$iptables = IPTables::ChainMgr->new(ipt_bin_name => ($ipv6 ? $_[0]->{ip6tables_bin} : $_[0]->{iptables_bin}), use_ipv6 => $ipv6, ipt_rules_file => '', iptout => '', ipterr => '', debug => 0, verbose => 0, ipt_alarm => 5, ipt_exec_style => 'popen', ipt_exec_sleep => 0);
	$iptables->{'parse_obj'}->{'_lockless_ipt_exec'} = 0 if($iptables && $iptables->{'parse_obj'} && $iptables->{'parse_obj'}->{'_lockless_ipt_exec'});
	fatal(($ipv6?'[ip6tables]':'[iptables]').'Could not determine if chain '.$_[0]->{filter_name}.' exists') if(!(@res = $iptables->chain_exists('filter', $_[0]->{filter_name})));
	if($res[0]!=1){
			$iptables->create_chain('filter', $_[0]->{filter_name});
			$iptables->add_jump_rule('filter', 'INPUT', 4, $_[0]->{filter_name});
	}

	return $iptables;
}

sub iptables_cmd {
	my ($args, $conf, @res, $iptables);
	($args, $conf, $iptables) = @_;

	return 1 if($conf->{iptables_support}==0);

	$iptables = 'iptables';
	if(defined $_[2] && $_[2] == 6){
		return 1 if($conf->{iptables_support}!=6);
		$iptables = 'ip6tables';
	}

	@res = (0, [], []);
	timeout_call( 5 ,sub {

		if((defined fileno(IPTABLESLOCKFILE) || open(IPTABLESLOCKFILE, '+>>'.$conf->{iptables_lockfile})) && flock(IPTABLESLOCKFILE, LOCK_EX)){
			@res = ();
			@res = $conf->{$iptables}->run_ipt_cmd($conf->{$iptables.'_bin'}.' '.$1) if($args !~ $conf->{re}->{martian_ip} && $args =~ $conf->{re}->{iptables_arg});
			flock(IPTABLESLOCKFILE, LOCK_UN);
			(@res && $res[0]==1) ? inform('['.$iptables.'] '.$conf->{$iptables.'_bin'}.' '.$args) : error('['.$iptables.'] Error: '.$conf->{$iptables.'_bin'}.' '.$args);
		}
	});

	return @res;
}

sub ip6tables_normalize {
	return $_[1]->{iptables_support} == 6 ? $_[1]->{ip6tables}->normalize_net($_[0]) : ''; #s/b default ip
}

sub service_cmd {

	my ($service, $initd, $arg, $cmd);

	$service = shift;
	$arg = join (' ', @_);

	if(($initd = find_bin('service'))){
		$cmd = "$initd $service $arg";
	}elsif(($initd = find_bin('initctl')) || ($initd = find_bin('svcadm')) || ($initd = find_bin('systemctl'))){
		$cmd = "$initd $arg $service";
	}elsif(( $service=~/\// && -e $service && ($initd=$service)) && (($initd="/etc/init.d/$service") && -e $initd) || (($initd="/sbin/init.d/$service") && -e $initd) ){
		$cmd = "$initd $arg";
	}

	return (!$cmd || system($cmd)!=0 || $? == -1 || $? & 127) ? 0 : 1;
}

sub clean_notifications {
	op_rkeys(';warning-*', \&clean_notifications_op, $_[0], $_[1]);
}

sub notify_blacklist {
	my $params = $_[1];
	return if ($_[1]->{conf}->{admin_email} !~ $_[1]->{conf}->{re}->{envelope});
	$_[1]->{admin_email_address} = $1.'@'.$2;
	op_rkeys(';warning0-*', \&notify_blacklist_op, $_[0], $_[1]);
}

sub refresh_iptables {
	$_[1]->{iptables} = '' if(!$_[1]->{iptables});
	op_rkeys(';expires-*', \&refresh_iptables_op, $_[0], $_[1]);
}

sub notify_blacklist_op {
	my ($re, %var, $msg, $res, $message, $k, $v, $db, $params);
	($k, $v, $db, $params) = @_;

	$re = $params->{conf}->{re};
	%var = (user => '', domain => '', email => '', ip => '', recipient => '', admin => $params->{admin_email_address});

	$db->del($k);
	$k =~ s/$re->{subkey}/;warning-/;
	return if($db->exists($k));
	$db->set($k => time());

	($v, $var{recipient}) = split("\n", $v);
	if($v =~ $re->{ip} && $k =~ $re->{emailfromkey}){
		$var{user} = decode_base64($1);
		$var{domain} = $2;
		$var{ip} = $v;
	}elsif($k =~ $re->{ipfromkey}){
		$var{ip} = $1.$2;
		return if($v !~ $re->{email});
		$var{user} = decode_base64($1);
		$var{domain} = $2;

	}else{
		return;
	}

	require Net::DNS;
	$res = Net::DNS::Resolver->new(udp_timeout=>10, tcp_timeout=>20);

	$v = $var{ip};
	$k = $v =~ $re->{colon} ? 1 : 0;
	$v =~ s/(\.|\:)(?:(?:[0-9]+\.[0-9]+)|(?:[0-9a-fA-F]+))$/$1/; #re

	$k = ' '.join(' ', map{  sub{ return join(' ', map{ $_->address } rr($res, $_[0], $k ? 'AAAA':'A')); }->($_->exchange) } rr($res, $var{domain}, 'MX'));

	return inform('[notify_blacklist] Failed') if($k!~/[ ]\Q$v\E(?:[ ]|$)/i);

	inform('[notify_blacklist] warning to '.$var{domain}.' '.$var{ip});

	$v = $var{email} = $var{user}.'@'.$var{domain};
	map{  $var{$_} = substr($var{$_}, 0,56) } keys %var;
	$message = $params->{conf}->{admin_message};
	$message =~ s/$re->{admintpl}/$var{lc($1)}/ig;

	$msg = MIME::Lite->new(
		'From'		=> $params->{conf}->{admin_email},
		'To'		=> $v,
		'Subject'	=> 'Delivery Failure Notification: blocked',
		'Type'		=> 'text/plain',
		'Data'		=> $message,
	);

	$msg->send;
}

sub clean_notifications_op {
	return if ((int($_[1]) + 2592000) > time());
	$_[2]->del($_[0]);
}

sub refresh_iptables_op {
	my ($re, $t, $ip, $cidr, $nm, $k, $v, $db, $params);
	($k, $v, $db, $params) = @_;

	$re = $params->{conf}->{re};

	$t = time();
	return if ( $t > int($v) || $k =~ $re->{martian_ip} || $k !~ $re->{ipfromkey});

	$ip = $1.$2;

	return if($params->{iptables} =~ /[^0-9]\Q$ip\E[^0-9]/sm);
	$nm = $ip =~ $re->{colon} ? 128 : 32;
	$cidr = $db->get($params->{conf}->{db_name}.';network-'.$ip) || $nm;

	$ip = sanitize($ip, $re->{ip}, '');
	$nm = sanitize($cidr, $re->{integer}, $nm);
	$v = sanitize($v, $re->{integer}, $t+864000);
	iptables_cmd('-t filter -I '.$params->{conf}->{filter_name}.' -i eth+ -s '.ip6tables_normalize((expand_ipv6($ip).'/'.cidr_16($nm)), $params->{conf}).' -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.$v.'\'', $params->{conf}, 6) if(($ip) && iptables_cmd('-t filter -I '.$params->{conf}->{filter_name}.' -i eth+ -s '.$ip.'/'.$nm.' -p tcp -m multiport --dports 25,587,110,143,465,993,995 -j REJECT -m comment --comment \'expires='.$v.'\'', $params->{conf}));

}

sub refresh_list {
	op_rkeys(';expires-*', \&refresh_list_op, $_[0], $_[1]);
}

sub refresh_list_op {
	my ($k, $v, $db, $params) = @_;

	return if ($v > time());
	$db->del($k);

	return if($k !~ $params->{conf}->{re}->{emailfromkey});
	$v = decode_base64($1).'@'.$2;
	#$params->{mailsa}->remove_address_from_whitelist($v);
	inform('[maintenance] removed from blacklist: '.$v);
}

sub consolidate_network_op {
	my ($k, $v, $db, $params, $re, %var, $ip);

	($k, $v, $db, $params) = @_;

	$re = $params->{conf}->{re};
	%var = $v =~ $re->{record} ? (avg => $1 + 0.0, total => $2 + 0.0, spamhits => int($3), lastspam => int($4), cachehit => 1) : %{$params->{def_var}};
	$var{expires} = 0;
	if($k =~ $re->{ipfromkey}){
		$ip = $1.$2;
		$var{expires} = $db->get($params->{conf}->{db_name}.';expires-'.$ip) || 0;
		$db->del($params->{conf}->{db_name}.';network-'.$ip);
		$db->del($params->{conf}->{db_name}.';expires-'.$ip);
	}
	$db->del($k);
	return \%var;
}

sub cache_decay_op {
	my ($re, $time, %a, $k, $v, $db, $params);

	($k, $v, $db, $params) = @_;

	$time = time();
	$re = $params->{conf}->{re};

	$v =~ s/$re->{spaces}//g;
	return if($v !~ $re->{record});

	%a = (avg => $1 + 0.0, total => $2 + 0.0, spamhits => int($3), lastspam => int($4), morf => $5);
	$a{lastspam_delta} = $time - $a{lastspam};

	return if($a{lastspam_delta}<60);

	if($params->{cache_decay_secs} < $a{lastspam_delta}){
		$db->del($k);
		inform('[maintenance] removed from cache: '.$k.' => '.$v);
		return;
	}

	$a{total} = nearest(0.01, $a{total} * exp(-3.2*$a{lastspam_delta}/$params->{cache_decay_secs}));
	$a{spamhits} = nearest(1, $a{total}/$params->{average_score_for_rule});
	$a{spamhits} = $params->{trigger_messages} if($a{spamhits} > $params->{trigger_messages});
	$a{spamhits} = 1 if($a{spamhits}<1);
	$a{avg} = nearest(0.01, $a{total}/$a{spamhits});

	$db->set($k => $a{avg}.','.$a{total}.','.$a{spamhits}.','.$a{lastspam}.','.$a{morf});
	inform('[maintenance] decay updated cache: '.$k.' => from: '.$v. ' to: '. $a{avg}.','.$a{total}.','.$a{spamhits}.','.$a{lastspam}.','.$a{morf});

}

sub get_config {
	return {
		iptables_bin				=> '/sbin/iptables',
		ip6tables_bin				=> '/sbin/ip6tables',
		iptables_support	=> 6,
		filter_name				=> 'spamipfilter',
		db_type				=> 'redis',
		db_host				=> '127.0.0.1',
		db_port				=> 0,
		db_user				=> '',
		db_auth				=> '',
		db_name			=> 'spamipfilter',
		piwik_host =>'',
		piwik_path=>,'',
		piwik_idsite=>1,
		log_dir => '/var/log',
		trigger_score				=> 6,
		trigger_messages			=> 3,
		trigger_sensitivity			=> 4,
		average_score_for_rule			=> 7,
		expire_rule_seconds			=> 172800,
		seconds_to_decay_penalty		=> 300,
		seconds_between_messages		=> 30,
		expires_multiplier_penalty		=> 1.5,
		cache_decay_days			=> 60,
		blacklist_score                         => 30,
		verbose					=> 0,
		whitelist				=> '',
		admin_email				=> '',
		admin_message				=> "\nYour message to \$recipient from \$email was blocked and your IP address \$ip blacklisted due to excessive unsolicited bulk email. \n\nTo reinstate your ability to send email to \$recipient, please reply to \$admin using a different off-network email, including the body of this message with a request for reinstatement.",
		common_hosts				=> 'gmail.com, google.com, yahoo.com, hotmail.com, live.com',
		iptables_lockfile => '',
		ua => '',
		username => '',
		lang => 'en',
		stopwords => ''

	};
}

sub re_config {
	my $k;
	$k = (($k = find_bin('lsmod')) && `$k 2>&1` !~ /iptable[s\-_ ]+filter/i && ($k = find_bin('modprobe')) && $> == 0) ? `$k -a ip_tables iptable-filter 2>&1` : '';
	$k =~ s/$Regex{spaces}//g;
	if($k){
		$_[0]->{iptables_support} = 0;
		error('iptables-filter kernel module not loaded... iptables functionality disabled');
	}
	$k = $_[0]->{db_name};

	$_[0]->{iptables} = iptables_mgr($_[0], 4);
	$_[0]->{ip6tables} = iptables_mgr($_[0], 6);

	$Regex{key} = qr/^(\Q$k\E)/;
	$Regex{emailfromkey} = qr/^\Q$k\E(?:;(?:(?:expires)|(?:warning[0-9]*)))?-([^\@]+)\@([^\@]+)$/;

	#similarity cache
	$_[0]->{stopwords} = $_[0]->{stopwords} ? ' '.lc($_[0]->{stopwords}).' ' : ' '.join(' ',keys %{getStopWords($_[0]->{lang})}).' ';

}

sub similarity {

        my ($v,$t,$c,$i,$add,$tmp,$cache);
        $add = $_[2] ? 1 : 0;

        $c = 0;
        $v = join("\n", grep{ ($_) && $c==0 && substr($_,0,1) ne '<' && !(index('<', $_)==-1 && $_=~/\:[ \t]*>/ ) && !(substr($_,0,2) eq "--" && length($_)<4 && ($c=1)) } split("\n", substr($_[0],0,32768) ));
        $v =~ s/<[>]*>/ /gsm;
        $v =~ s/(?:^|[\r\n\t ]+)[^\r\n\t ]+(?:(?:\:\/\/)|\@)[^\r\n\t ]+(?:[\r\n\t ]|$)/ /g;
        $v =~ s/[\x00-\x1F\x3D\x2C\x2D]/ /g;
	$v =~ s/[\x21-\x40\x5B-\x60\x7B-\xBF]//g;
        $v =~ s/[ ][ ][ ]*/ /g;

        $v = join(' ', grep { index($_[1]->{stopwords},' '.$_.' ')==-1 && length($_)>2 } split(' ', lc(substr($v,0,8192)) ));
        return 0 if(length($v)<5);

        $t = Text::Document->new();
        $t->AddContent($v);
        
        return inform('[similarity] could not acquire cache lock')+0 unless (defined fileno(IPFILTERCACHELOCK) && flock(IPFILTERCACHELOCK, LOCK_EX));

        $cache = thaw($_[1]->{db}->get($_[1]->{db_name}.';similarity-cache') || freeze({}));

        $i = 0;
        $c = time() - 172800;
        for(keys %{$cache}){

                $v = $t->CosineSimilarity($cache->{$_}->[1]) + 0;
                if(0.7<$v){

                        if($_[1]->{seconds_between_duplicates}>int(time()-int($_))){ 
                                flock(IPFILTERCACHELOCK, LOCK_UN);
                                return -1;
                        }

                        $cache->{$_}->[0]+=1;

                        $v = nearest(0.01,$v+$cache->{$_}->[0]);

                        inform('[similarity] '.$v);
                        $_[1]->{db}->set($_[1]->{db_name}.';similarity-cache' => freeze($cache));

                        flock(IPFILTERCACHELOCK, LOCK_UN);
                        return $v;
                }
                ($_ < $c && $cache->{$_}->[0]==0) ? delete $cache->{$_} : ++$i;

        }

        return flock(IPFILTERCACHELOCK, LOCK_UN)*0 if(!$add);

        map{ delete $cache->{$_} }@{[sort {$a <=> $b} keys %{$cache}]}[0 .. 128] if(1024<$i);

	$c = int(keys %{$cache})+0;
	inform('[similarity] (cache size '.$c.') adding...');

        do{
                $c = time().'.'.int(rand(65536));
        }while(exists $cache->{$c});

        $cache->{$c} = [0, $t, $tmp];

        $_[1]->{db}->set($_[1]->{db_name}.';similarity-cache' => freeze($cache));

        #inform('[similarity] '. join(',',keys %{thaw($_[1]->{db}->get($_[1]->{db_name}.';similarity-cache'))}) );

        flock(IPFILTERCACHELOCK, LOCK_UN);

        return 0;
} 

sub compile_regex {
	my $k = get_config()->{db_name};
	# Although SA preprocesses much of the data captured, this should be tightened
	return (
		from 				=> qr/(?:^|\n)[\t ]*from\:([^\r\n\@]+\@[^\r\n]+)[\r\n]/i,
		envelope			=> qr/(?:^|(?:[^\x3C]*\x3C))([^\x3C\x3E\@]+)\@([^\x3C\x3E\@]+)(?:\x3E|$)/,
		alnumchar			=> qr/[a-z0-9]/i,
		isint                       	=> qr/^[0-9]+$/i,
		spaces				=> qr/[\r\n\t ]+/,
		trim				=> qr/(?:^['",\r\n\t ]+)|(?:['",\r\n\t ]+$)/,
		email				=> qr/^(.+)\@(.+)$/,
		n_domainchars			=> qr/[^0-9.\-a-zA-Z]/,
		n_dbchars			=> qr/[^0-9.,\@a-z_\-+\/=]/i,
		integer				=> qr/^([0-9]+)$/,
		colon				=> qr/\:/,
		iptables_arg			=> qr/^([ -;=A-_a-~]+)$/,
		record				=> qr/^([0-9.]+),([0-9.]+),([0-9.]+),([0-9.]+)(?:(?:,(.*))|$)/,
		subkey				=> qr/;[a-zA-Z0-9]+\-/,
		ip				=> qr/^(?:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)|(?:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}))$/i,
		ipn				=> qr/^((?:(?:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)|(?:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}))(?:\/[0-9]+)?)$/i,
		key				=> qr/^(\Q$k\E)/,
		ipfromkey			=> qr/(?:^|-)((?:[0-9]+\.[0-9]+\.[0-9]+\.)|(?:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{4}\:[0-9a-f]{2}))([0-9a-f]+)(?:[^0-9a-f]|$)/i,
		emailfromkey			=> qr/^\Q$k\E(?:;(?:(?:expires)|(?:warning[0-9]*)))?-([^\@]+)\@([^\@]+)$/,
		admintpl			=> qr/\$((?:user)|(?:domain)|(?:ip)|(?:email)|(?:recipient)|(?:admin))/i,
		expires				=> qr/[^0-9]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?:\/[0-9]+)?)[^0-9]+0\.0\.0\.0\/0[^0-9]+.*?\bexpires=([0-9]+)[^0-9]/sm,
		#Thanks to Salvador Fandino's Regexp::IPv6
		rcvd_header			=> qr/from[ \t]+([^ \t]+)[ \t]+\(.*?\[[\t ]*((?:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)|(?::(?::[0-9a-fA-F]{1,4}){0,5}(?:(?::[0-9a-fA-F]{1,4}){1,2}|:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})))|[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}|:)|(?::(?:[0-9a-fA-F]{1,4})?|(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))))|:(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4})?|))|(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|:[0-9a-fA-F]{1,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){0,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,2}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,3}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))))[ \t]*\]/i,

		param => sub { my $r = '^(?:(?:'.join(')|(?:',keys %{get_config()}).'))$'; $r=~s/\_/\\_/g; return qr/$r/sm; }->(),
		martian_ip			=> sub {
				my ($r, @buffer);
				$r = find_bin('route');
				map{ $_=~/^[ ]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[ ]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[ ]+(?:[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+))[ ]/ && ((0<length($2) && ($2 ne '0.0.0.0') && push @buffer, $2) xor (0<length($1) && ($1 ne '0.0.0.0') && push @buffer, sub{ return $_[0].'([0-9]*[0-9])(?(?{int($+)<'.$_[1].' || int($+)>'.($_[1]+$_[2]).';})X)'; }->(substr($1, 0, rindex($1,'.')+1), int(substr($1, rindex($1,'.')+1)), 256-int($3)))) } split("\n", `$r -nA inet`);
				map{ $_=~/^[ ]*([0-9a-f\:]+)[^0-9a-f\:]/i && sub { $_[1] =~ /[0-9a-f]\:[0-9a-f]/i && $_[1] !~ /^(?:(?:0000\:)|(?:fc00\:)|(?:fe80\:)|(?:ff00\:)|(?:2001\:0db8\:)|(?:2001\:0010\:)|(?:3ffe\:))/i && (push @{$_[0]}, lc($_[1]).'[a-f0-9]{2}') }->(\@buffer, substr(expand_ipv6($1), 0, -2) ) } split("\n", `$r -nA inet6`);
				$r = '(?:'.join (')|(?:', @buffer).')';
				$r =~ s/\Q.\E/\\./g;
				$r =~ s/([0-9])\:/$1\\:/g;
				use re 'eval';
				#ipv6 needs *some* work
				return qr/(?:^|[^0-9a-f])(?:(?:0000\:)|(?:fc00\:)|(?:fe80\:)|(?:ff00\:)|(?:2001\:0db8\:)|(?:2001\:0010\:)|(?:3ffe\:)|(?:127\.)|(?:192\.168\.)|(?:0\.)|(?:10\.)|(?:100\.64\.)|(?:224\.)|(?:192\.0\.0\.)|(?:169\.254\.)|$r)(?:[^0-9a-f]|$)/i;

			}->()
	);
}

BEGIN {

	%Regex = compile_regex();
	%Cronjobs = (IPFilterUpdate => \&c_ipfilter_update, Maintenance => \&c_maintenance, LogFormat => \&c_log_format, LogPiwik => \&c_log_piwik);
	$Cronjobs{$1}->($2) if(do {local $/; STDIN->blocking(0); <STDIN>} =~ /^([a-zA-Z_]+)[ ][ ]*(.*)$/ && (STDIN->blocking(1)||1) && ($1) && ($2) && (exists $Cronjobs{$1}) );

	require Mail::SpamAssassin::Plugin;
	Mail::SpamAssassin::Plugin->import();
	require Mail::SpamAssassin::Logger;
	Mail::SpamAssassin::Logger->import();
	@ISA = qw(Mail::SpamAssassin::Plugin);

}  # ...


sub new {
	my ($class, $mailsa, $self);
	($class, $mailsa) = @_;
	$class = ref($class) || $class;
	$self = $class->SUPER::new($mailsa);
	bless ($self, $class);
	$self->{mailsa} = $mailsa;
	$self->set_config($mailsa->{conf});
	return $self;
}

sub set_config {
	my (@cmds, $c, $self, $conf);
	($self, $conf) = @_;
	$self->{conf} = get_config();
	foreach $c (keys %{$self->{conf}}){
		push(@cmds, {
				'setting' 	=> 'ipfilter_'.$c,
				'default' 	=> $self->{conf}->{$c},
				'type' 		=> $self->{conf}->{$c} =~ /^[0-9]+(?:\.[0-9]+)?$/ ? $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC : $Mail::SpamAssassin::Conf::CONF_TYPE_STRING
			}
		);
	}
	$self->register_eval_rule('check_spamipfilter');
	$conf->{parser}->register_commands(\@cmds);
}

sub finish_parsing_end {

	my ($c, $v, $ini, $db, $self, $params);

	($self, $params) = @_;
	$self->{conf}->{whitelist} = {};
	$ini = get_config(); #should == $self->{conf}

	foreach $c (keys %{$self->{conf}}){
		if(defined $params->{conf}->{'ipfilter_'.$c} && exists $ini->{$c} && $c=~$Regex{param}){
			$v = $params->{conf}->{'ipfilter_'.$c};
			$v =~ s/(?:^[\r\n\t ]+)|(?:[\x00])|(?:[\r\n\t ]+$)//g;
			$v =~ s/\/$//g if($c =~ /(?:(?:\_bin)|(?:\_dir)|(?:\_path))$/);
			if($v =~ /^([0-9]+(?:\.[0-9]+)?)$/ || $ini->{$c} =~ /^([0-9]+(?:\.[0-9]+)?)$/){
				$self->{conf}->{$c} = $1 + 0;
			}elsif($c =~ /whitelist$/i){
				$v =~ s/[ \r\n\t]*//g;
				map{($v =~ /^([^\x00-\x32]+\@[a-zA-Z0-9\-.]+)$/ || $v =~ /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]*)$/) && (${$self->{conf}->{whitelist}}{lc($1)} = 1)} split(',', $v);
			}elsif(($c =~ /(?:(?:\_host))$/i && ($v =~ /^((?:[a-z]+\:\/\/)?[a-zA-Z0-9\-.]+)$/ || $v =~ /^((?:[a-z]+\:\/\/)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]*)$/)) || ($c =~ /(?:(?:\_bin)|(?:\_dir)|(?:\_path))$/i && $v =~ /^[^\x00-\x31]+$/ && (-e $v || -d $v)) || ($c =~ /(?:(?:\_email))$/i && ($v =~ /^([^\x00-\x32]+\@[a-zA-Z0-9\-.]+)$/ || $v =~ /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]*)$/)) || ($c =~ /common_hosts$/i && $v =~ /^([a-zA-Z0-9\-.,]+)$/) || ($c =~ /\_(?:(?:name)|(?:type))$/i && $v =~ /^([a-zA-Z0-9_]+)$/) || ($c =~ /\_((?:message))$/i && $v =~ /^([^\x00-\x09\x0b\x0c\x0e-\x1f]+)$/) || $v =~ /^([\x20\x21\x23\x24\x25\x26-\x5b\x5d\x5e\x5f\x61-\x7e]*)$/){

				$self->{conf}->{$c} = $1;
			}else{
				inform('[finish_parsing_end] unknown configuration '.$c.' => '.$v);
			}
		}
	}

	$Verbose = 1 if(int($self->{conf}->{verbose})>0);

	$self->{conf}->{lang} = $self->{conf}->{lang} ? lc(substr($self->{conf}->{lang},0,2)) : 'en';

	$self->{conf}->{ua} = 'SpamAssassinIPFilter/'.$VERSION.' (compatible; foobot/2.0; +http://www.foo.com/foobot.htm)' if(!$self->{conf}->{ua});
	$self->{conf}->{username} = (((-e "/proc/$$/cmdline" && open(PROCCMDLINE,"/proc/$$/cmdline") && ($c=do{local $/; <PROCCMDLINE>}) && ($c=sub{ return $_[0] =~/[ \t\r\n]\-(?:(?:u)|(?:\-user))[='" ]*([^'" \t\r\n]+)(?:(?:[ \t\r\n'"])|$)/ ? $1 : '' }->($c, close(PROCCMDLINE)))) || (($c = $params->{username}) && $c!~/^root$/i) || (($c = $params->{home_dir_for_helpers}) && $c!~/(?:^|\/)root\/+?$/i) || (($c = find_bin('id')) && -e $c && (`$c spamd 2>&1`=~/[0-9]+/) && ($c='spamd')) ) && $c =~/^([a-z_][a-z0-9_-]*)$/i) ? $1 : 'root' if(!$self->{conf}->{username});

	$self->{conf}->{filter_name} = 'spamipfilter' if ($self->{conf}->{filter_name} !~ /^[a-z0-9\-_.]+$/i);
	$self->{conf}->{iptables_support} = $self->{conf}->{iptables_support} + 0;
	$self->{conf}->{iptables_support} = 4 if($self->{conf}->{iptables_support}!=0 && $self->{conf}->{iptables_support}!=4 && $self->{conf}->{iptables_support}!=6);
	if($self->{conf}->{iptables_support}>0){
		$self->{conf}->{iptables_bin} = ($self->{conf}->{iptables_bin} && -e $self->{conf}->{iptables_bin}) ? $self->{conf}->{iptables_bin} : (find_bin('iptables') ? find_bin('iptables') : '');
		$self->{conf}->{iptables_lockfile} = (-d '/var/lock' && -w '/var/lock') ? '/var/lock/spamipfilter' : (-d '/tmp' ? '/tmp/spamipfilter.lock' : getcwd().'/spamipfilter') if(!$self->{conf}->{iptables_lockfile});
		$self->{conf}->{ip6tables_bin} = ($self->{conf}->{ip6tables_bin} && -e $self->{conf}->{ip6tables_bin}) ? $self->{conf}->{ip6tables_bin} : (find_bin('ip6tables') ? find_bin('ip6tables') : '') if($self->{conf}->{iptables_support}>4);
	}

	$self->{conf}->{iptables_support} = 4 if(!$self->{conf}->{ip6tables_bin});
	$self->{conf}->{iptables_support} = 0 if(!$self->{conf}->{iptables_bin});

	$self->{conf}->{db_host} =~ s/^.*?\:\/\///g;
	$self->{conf}->{db_port} = int($self->{conf}->{db_port});
	$self->{conf}->{db_port} = 0 if ($self->{conf}->{db_port}<1);

	$self->{conf}->{piwik_idsite} = int($self->{conf}->{piwik_idsite}+0);
	$self->{conf}->{piwik_host} = 'http://'.$self->{conf}->{piwik_host} if ($self->{conf}->{piwik_host} && $self->{conf}->{piwik_host}!~/^[^\/]+\:\/\//);

	$self->{conf}->{expire_rule_seconds} = $self->{conf}->{expire_rule_seconds} + 0.0;
	$self->{conf}->{expire_rule_seconds} = 300 if(300 > $self->{conf}->{expire_rule_seconds});
	$self->{conf}->{cache_decay_days} = $self->{conf}->{expire_rule_seconds}*90/86400;
	$self->{conf}->{cache_decay_days} = 1 if(0.2 > $self->{conf}->{cache_decay_days});
	$self->{conf}->{seconds_to_decay_penalty} =  2 if(2 > $self->{conf}->{seconds_to_decay_penalty});
	$self->{conf}->{seconds_between_messages} =  0.99 if(1 > $self->{conf}->{seconds_between_messages});
	$self->{conf}->{trigger_messages} =  1 if(1 > $self->{conf}->{trigger_messages});
	$self->{conf}->{average_score_for_rule} =  1 if(0.2 > $self->{conf}->{average_score_for_rule});
	$self->{conf}->{trigger_sensitivity} = 1 if(0.2 > $self->{conf}->{trigger_sensitivity});

	$self->{conf}->{common_hosts} =~ s/[ \r\n\t]*//g;
	$c = $self->{conf}->{common_hosts};
	$c =~ s/\Q.\E/\\./g;
	$c = ($self->{conf}->{common_hosts}) ? '(?:^|\.)((?:'.join(')|(?:', split(',', lc($c))).'))(?:[^a-z]|$)' : '^$';
	$Regex{common_hosts} = qr/$c/i;

	($self->{conf}->{log_dir} = -d '/tmp' ? '/tmp' :  getcwd()) if(!-d $self->{conf}->{log_dir} || !-w $self->{conf}->{log_dir});


        if(-d $self->{conf}->{log_dir}){
                mkdir($self->{conf}->{log_dir}.'/'.$self->{conf}->{filter_name}) if(!-d $self->{conf}->{log_dir});
                $self->{conf}->{log_dir} = $self->{conf}->{log_dir}.'/'.$self->{conf}->{filter_name} if(-d $self->{conf}->{log_dir}.'/'.$self->{conf}->{filter_name} && -w $self->{conf}->{log_dir}.'/'.$self->{conf}->{filter_name});
        }

	fatal('Could not find log directory '.$self->{conf}->{log_dir}) if(!-d $self->{conf}->{log_dir} || !-w $self->{conf}->{log_dir});
	c_logfile($self->{conf});
	chown(int($1),-1, $self->{conf}->{log_dir}.'/.cache.lock' ) if ((defined fileno(IPFILTERCACHELOCK) || open(IPFILTERCACHELOCK, '+>>'.$self->{conf}->{log_dir}.'/.cache.lock' )) && $self->{conf}->{username} && getpwnam($self->{conf}->{username})=~/^([0-9]+)$/);

	map { ($_ =~ /(?:(?:\_bin)|(?:\_dir)|(?:\_path))$/) && (!-e $self->{conf}->{$_} && !-d $self->{conf}->{$_}) && ($self->{conf}->{$_}='')} (keys %{$self->{conf}});


	$v = sub {

		my ($cron, $cfg);
		$cron = $_[1] ? new Config::Crontab(-owner => $_[1], -strict => 0) : new Config::Crontab();

		#see caveats: http://search.cpan.org/~scottw/Config-Crontab-1.40/Crontab.pm#CAVEATS
		$cron->remove($cron->select(-command_re => 'Mail::SpamAssassin::Contrib::Plugin::IPFilter'));
		$cron->remove($cron->select(-name => 'MAIL_SPAMASSASSIN_CONTRIB_PLUGIN_IPFILTER'));

		$cron->write;

		$c = new Config::Crontab::Block;
		$cfg = encode_base64(JSON::XS->new->utf8->encode($self->{conf}),'');

	
		#$c->last( new Config::Crontab::Env( -name => 'MAIL_SPAMASSASSIN_CONTRIB_PLUGIN_IPFILTER', -value=> '"'.encode_base64(JSON::XS->new->utf8->encode($self->{conf}), '').'"') );

		#TODO: better $cfg handling... env. var or r/o file
		$c->last( new Config::Crontab::Event( -data => '*/15 * * * * '.$_[0].' \'IPFilterUpdate '.$cfg.'\' | '.$^X." '-MMail::SpamAssassin::Contrib::Plugin::IPFilter' > /dev/null 2>&1") );
		$c->last( new Config::Crontab::Event( -data => '15 00 * * * '.$_[0].' \'LogFormat '.$cfg.'\' | '.$^X." '-MMail::SpamAssassin::Contrib::Plugin::IPFilter' > /dev/null 2>&1") );
		$c->last( new Config::Crontab::Event( -data => '00 23 * * * '.$_[0].' \'Maintenance '.$cfg.'\' | '.$^X." '-MMail::SpamAssassin::Contrib::Plugin::IPFilter' > /dev/null 2>&1") );
		$c->last( new Config::Crontab::Event( -data => '00 01 * * * '.$_[0].' \'LogPiwik '.$cfg.'\' | '.$^X." '-MMail::SpamAssassin::Contrib::Plugin::IPFilter' > /dev/null 2>&1") ) if ($self->{conf}->{piwik_host} && $self->{conf}->{piwik_path} && -d $self->{conf}->{piwik_path});
		$cron->last($c);
		$cron->write;

		undef $cron;
		$cron = $_[1] ? new Config::Crontab(-owner => $_[1], -strict => 0) : new Config::Crontab();
		$cron->read;

		return $c->dump;

	};

	error('[finish_parsing_end] Could not setup cron jobs') if($v->(find_bin('echo'), 'root') !~ /MAIL[_:]+SPAMASSASSIN[_:]+CONTRIB[_:]+PLUGIN[_:]+IPFILTER/i && $v->(find_bin('echo')) !~ /MAIL[_:]+SPAMASSASSIN[_:]+CONTRIB[_:]+PLUGIN[_:]+IPFILTER/i);


	re_config($self->{conf});
	$self->{conf}->{iptables}->flush_chain('filter', $self->{conf}->{filter_name}) if($self->{conf}->{iptables_support}>0);
	$self->{conf}->{ip6tables}->flush_chain('filter', $self->{conf}->{filter_name}) if($self->{conf}->{iptables_support}>4);

	$self->{conf}->{re} = \%Regex;
	lock_hashref($self->{conf});
	#service_cmd('crond', 'reload') || service_cmd('cron', 'reload');
	$self->inhibit_further_callbacks();
	return 1;
}
    
sub check_spamipfilter() {
	my ( $self, $pms ) = @_;
	return 0;
}

sub check_end {

	my ($msg, $conf, $msg_score, $spam_score, $nonspam_trigger, $spam_trigger, $db, $key, $pre, $re, %var, %def_var, %sender, %whitelist, $self, $params, $tmp);
	($self, $params) = @_;
	$_ = '';
	%sender = (ip => '', host => '', ipv6 => 0, to => '', envelope => '', from => '', fkey => '', user => '',  domain => '', is_common_domain => 0, extra => '');
	%def_var = (avg => 0, total => 0, spamhits => 0, lastspam => 0, extra => '');

	$msg = $params->{permsgstatus};
	$conf = $self->{conf};

	$re = $self->{conf}->{re};
	%whitelist = %{$self->{conf}->{whitelist}};

	$msg_score = $msg->get_score() + 0.0;
	$spam_score = $msg->get_required_score() + 0.0;
	$spam_trigger = $spam_score + 1;
	$nonspam_trigger = $spam_score - 1;

	if($conf->{trigger_score} > $spam_score){
		$spam_trigger = $conf->{trigger_score};
		$nonspam_trigger = $spam_score - ($conf->{trigger_score} - $spam_score);
	}

	inform('[check_end] processing message with score='.$msg_score.' (spam_score:'.$spam_score.', spam_trigger:'.$spam_trigger.', nonspam_trigger:'.$nonspam_trigger.')');

	$pre = substr($msg->get('ALL-INTERNAL'), 0, 4096);
	$sender{envelope} = $msg->get('EnvelopeFrom:addr') || $msg->get('From:addr');
	$sender{envelope} =~ s/$re->{trim}//g;

	/()/;
	if($sender{envelope} !~ $re->{envelope}){
		return error('[check_end] Could not find "envelope" in msg') if($pre !~ $re->{from} && substr($msg->get('ALL'), 0, 4096) !~ $re->{from});
		$sender{envelope} = $1;
		$sender{envelope} =~ s/$re->{trim}//g;
	}

	if((($1) && ($2)) || $sender{envelope} =~ $re->{envelope}){
		$sender{from} = substr("$1\@$2", 0, 512);
		$sender{from} =~ s/$re->{spaces}//g;
	}

	return error('[check_end] Could not find "from" in envelope '.$sender{envelope}) if($sender{from} !~ $re->{email});

	$sender{user} = $1;
	$sender{domain} = $2;
	$sender{domain} =~ s/$re->{n_domainchars}//g;
	$sender{fkey} = encode_base64($sender{user}, '').'@'.$sender{domain};
	$sender{extra} = $sender{fkey};

	$sender{to} = lc($msg->get('To:addr') || '');
	$sender{to} =~ s/$re->{spaces}//g;
	tr_ascii($sender{from}, $sender{to});

	/()/;
	$pre = substr($msg->get('Received'), 0, 4096) if($pre !~ $re->{rcvd_header});

	if((($1) && ($2)) || $pre =~ $re->{rcvd_header}){
		$sender{host} = lc($1);
		$sender{ip} = $2;
		inform('[check_end] Received header: '.tr_ascii(substr($pre,0,32)));
	}else{
		%var = (pre=>'');
		#inform('[check_end] Could not match rcvd host/ip');


		while ( $var{pre} = pop @{$msg->{relays_untrusted}} ){

			if($var{pre}->{ip} && !$var{pre}->{ip_private}){
				$sender{ip} = $var{pre}->{ip};
				$sender{host} = $var{pre}->{rdns} ? lc($var{pre}->{rdns}) : 'unknown';
				last;
			}
		}
		if (!$sender{ip}){
			#inform('[check_end] Could not determine IP '.tr_ascii($pre));
			return 0;
		}
	}

	tr_ascii($sender{ip}, $sender{host});
	if($sender{ip} =~ $re->{colon}){
		$sender{ipv6}= 1;
		inform('[check_end] Expanding IP '.$sender{ip});
		$sender{ip} = expand_ipv6($sender{ip});
	}

	if ($sender{ip} !~ $re->{ip}){
		inform('[check_end] Could not determine IP '.$sender{ip});
		return 0;
	}

	inform('[check_end] user/domain/ip/host: '.$sender{user}.'/'.$sender{domain}.'/'.$sender{ip}.'/'.$sender{host});

	$key = $conf->{db_name}.'-'.$sender{ip};

	if($sender{host} =~ $re->{common_hosts}){
		$sender{is_common_domain} = 1;
		$sender{domain} = $1 if(!$sender{envelope});
		inform('[check_end] domain is common');
		if(!$sender{user} || !$sender{domain}){
			$sender{from} = 'no user specified' if (!$sender{from});
			return error('[check_end] Could not find envelope user from: '.$sender{domain}.' ('.$sender{from}.')');
		}

		$sender{from} = $sender{user}.'@'.$sender{domain};
		if(exists $whitelist{'@'.$sender{domain}} || exists $whitelist{$sender{from}}){
			$msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score => -1*$conf->{blacklist_score});
			inform('[check_end] done '.$sender{from}.' whitelisted ('.$msg->get_score().')');
			return 1;
		}
		$sender{extra} = $sender{ip};
		$sender{fkey} = encode_base64($sender{user}, '').'@'.$sender{domain};
		$key = $conf->{db_name}.'-'.$sender{fkey};
	}

	inform('[check_end] key: '.$key);

	if(exists $whitelist{$sender{ip}}){
		$msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score => -1*$conf->{blacklist_score});
		inform('[check_end] done '.$sender{ip}.' whitelisted ('.$msg->get_score().')');
		return 1;
	}

	return error('[check_end] Could not establish connection to database') if(!($db = dbconnect($conf)));

	$sender{host} = $sender{ip};
	if($key=~$re->{ipfromkey}){
		$sender{ip} = consolidate_network($db, {ip => $1, host => $2, sender => $sender{fkey}, ipv6 => $sender{ipv6}, conf => $conf, def_var => \%def_var});
		if(exists $whitelist{$sender{ip}}){
			inform('[check_end] done '.$sender{ip}.' whitelisted');
			return 1;
		}
		$key = $conf->{db_name}.'-'.$sender{ip};
	}

	$pre = $key;
	$pre =~ s/$re->{key}/$1;expires/;
	if($pre ne $key && ($pre = $db->get($key)) && $pre =~ $re->{isint} && time()<int($pre)){
		$msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score => $conf->{blacklist_score});
		#$msg->{conf}->{scoreset}->[0]->{uc($conf->{filter_name})} = sprintf("%0.3f", $conf->{blacklist_score});
		inform('[check_end] done '.$sender{from}.' is blacklisted ('.$msg->get_score().')');
		return 1;
	}

	$pre = $db->get($key) || '';
	$pre =~ s/$re->{n_dbchars}//g;
	inform('[check_end] cached record: '.$pre);
	%var = $pre =~ $re->{record} ? (avg => $1 + 0.0, total => $2 + 0.0, spamhits => int($3), lastspam => int($4), extra => $5, cachehit => 1) : %def_var;

	$var{lastspam_delta} = $var{lastspam}>0 ? time() - $var{lastspam} : 0;

	if(exists $var{cachehit} && $var{lastspam}!=0 && $sender{extra} eq $var{extra} && $conf->{seconds_between_messages}>$var{lastspam_delta}){

                if(0!=($var{score}=similarity(join("\n\n",@{$msg->get_decoded_stripped_body_text_array()}), {stopwords=>$conf->{stopwords}, db=>$db, db_name=>$conf->{db_name}, seconds_between_duplicates => $conf->{seconds_between_messages}>>1}, $msg_score >= $spam_score))){

                        $var{score} =  $var{score}>$conf->{trigger_messages} ? $var{score} - $conf->{trigger_messages} : $var{score}/$conf->{trigger_messages};
                        $var{x} = $conf->{seconds_to_decay_penalty}<$var{lastspam_delta} ? 5.436 : $var{lastspam_delta}/$conf->{seconds_to_decay_penalty};
			$var{score} = nearest(0.01, exp(-1*$var{x}/10)*abs($var{score}));
                        $msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score =>  $var{score}>$conf->{blacklist_score}?$conf->{blacklist_score}:$var{score});
                }

		inform('[check_end] skipping duplicate msg with score '.$msg->get_score());
		return 1;
	}
	$var{score} = 0;
	if($msg_score < $spam_trigger){
	   inform('[check_end] processing nonspam') if($msg_score < $spam_score);

           $var{score} = similarity(join("\n\n",@{$msg->get_decoded_stripped_body_text_array()}), {stopwords=>$conf->{stopwords}, db=>$db, db_name=>$conf->{db_name}, seconds_between_duplicates => $conf->{seconds_between_messages}>>1}, $msg_score >= $spam_score);
	   if($var{score}==-1){
		inform('[check_end] skipping duplicate msg');
                return 1;
           }

	   $var{score} =  $var{score}>$conf->{trigger_messages} ? $var{score} - $conf->{trigger_messages} : $var{score}/$conf->{trigger_messages};
	   if($msg_score < $nonspam_trigger && $var{score}==0){
		if(exists $var{cachehit}){
			$var{total} = $var{total} - ($var{avg} + ($spam_score - $msg_score));
			--$var{spamhits};
			if($var{total}<1){
				%var = (%def_var, lastspam => $var{lastspam}, score => $var{score});
			}else{
				$var{total} = nearest(0.01, $var{total});
				$var{avg} = $var{spamhits}>1 ? nearest(0.01, $var{total}/$var{spamhits}) : $var{total};
				$var{spamhits} = 0 if($var{spamhits}<1);
			}
			$db->set($key => $var{avg}.','.$var{total}.','.$var{spamhits}.','.$var{lastspam}.','.$sender{extra});
			inform('[check_end:nonspam] updated cache: '.$key.' => from: '.$pre.' to: '.$var{avg}.','.$var{total}.','.$var{spamhits}.','.$var{lastspam}.','.$sender{extra});
		}
            }   
	}
	return inform('[check_end] done')+0 if($var{score}+$msg_score < $spam_trigger);

	inform('[check_end] processing as spam candidate');

	$var{w} =  $var{spamhits} < 1 ?  $conf->{trigger_sensitivity} : ($conf->{trigger_sensitivity}-1)/$var{spamhits};
        $var{x} = (!exists $var{cachehit} || $var{cachehit}==0 || $conf->{seconds_to_decay_penalty}<$var{lastspam_delta}) ? 5.436 : $var{lastspam_delta}/$conf->{seconds_to_decay_penalty};

	if($var{score}==0){	
		$var{score} = ($msg_score<($spam_trigger*3)) ? similarity(join("\n\n",@{$msg->get_decoded_stripped_body_text_array()}), {stopwords=>$conf->{stopwords}, db=>$db, db_name=>$conf->{db_name}, seconds_between_duplicates => $conf->{seconds_between_messages}>>1}, 1) : $conf->{trigger_messages}+1;
        	if($var{score}>0){
			$var{score} =  $var{score}>$conf->{trigger_messages} ? $var{score} - $conf->{trigger_messages} : $var{score}/$conf->{trigger_messages};
			$var{score} = nearest(0.01, exp(-1*$var{x}/10)*abs($var{score}));
                        $msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score =>  $var{score}>$conf->{blacklist_score}?$conf->{blacklist_score}:$var{score});
			inform('[check_end] updated score '.$msg->get_score());	
		}elsif($var{score}==-1){
             		inform('[check_end] skipping duplicate spam msg');
             		return 1;
		}
	}else{
		$var{score} = exp(-1*$var{x}/10)*abs($var{score});
		$var{score}=$conf->{blacklist_score} if($conf->{blacklist_score}<$var{score});

	}

	#inform('[check_end:spam] '.$var{score} .','.$var{x}.','.$var{w}.','.($var{cachehit}?1:0).','.$conf->{seconds_to_decay_penalty}.'<'.$var{lastspam_delta});


	$var{y} = exp(-1*$var{x}) + exp(-3.2*$var{w});
	$var{score} = nearest(0.01, $var{score} + $var{y});

	inform('[check_end] penalty '.$var{score});

	$var{spamhits} = 1 if(++$var{spamhits}<1);
	$var{total} = nearest(0.01, $var{total} + $var{score} + $msg_score);
	$var{avg} = nearest(0.01, $var{total}/$var{spamhits});
	$var{lastspam} = time();

	$db->set($key => $var{avg}.','.$var{total}.','.$var{spamhits}.','.$var{lastspam}.','.$sender{extra});
	inform('[check_end:spam] updated cache: '.$key.' => from: '.$pre.' to: '.$var{avg}.','.$var{total}.','.$var{spamhits}.','.$var{lastspam}.','.$sender{extra});

	$sender{to_user} = '-';
	$sender{to_domain} = $sender{to};
	if($sender{to} =~ $re->{email} && ($1) && ($2)){
		$sender{to_user} = $1;
		$sender{to_domain} = $2;
	}
	$sender{user} =~ s/$re->{n_dbchars}//g;
	$sender{domain} =~ s/$re->{n_domainchars}//g;
	$sender{to_user} =~ s/$re->{n_dbchars}//g;
	$sender{to_domain} =~ s/$re->{n_domainchars}//g;
	$sender{user} = '-' if (!$sender{user});
	$sender{domain} = 'null.invalid' if (!$sender{domain});
	$sender{to_user} = '-' if (!$sender{to_user});
	$sender{to_domain} = 'null.invalid' if (!$sender{to_domain});

	log_stats($sender{ip}.' - - ['.strftime("%d/%b/%Y:%H:%M:%S %z", localtime).'] "GET /'.$sender{to_domain}.'/'.$sender{to_user}.'?pk_spam='. nearest(10, $var{score}).' HTTP/1.1" 200 1024 "http://'.$sender{domain}.'/'.$sender{user}.'" "'.$conf->{ua}.'"');

	if($var{avg} >= $conf->{average_score_for_rule} && $var{spamhits} >= $conf->{trigger_messages}){

		$var{z} = $var{y} * ($var{score}/$conf->{average_score_for_rule});
		$var{z} = $conf->{expires_multiplier_penalty}*(1 + $var{z}) if($var{z} >= $conf->{expires_multiplier_penalty});
		inform('[check_end] expires penalty '.$var{z});

		$var{expires} = $var{lastspam} + int($conf->{expire_rule_seconds} * $var{z});

		$msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score => $conf->{blacklist_score});

		if($sender{is_common_domain}){
			$db->set($conf->{db_name}.';expires-'.$sender{fkey} => $var{expires});
			$db->set($conf->{db_name}.';warning0-'.$sender{fkey} => $sender{ip}."\n".$sender{to}) if($conf->{admin_email} && !$db->exists($conf->{db_name}.';warning-'.$sender{fkey}));
		}else{
			$db->set($conf->{db_name}.';expires-'.$sender{ip} => $var{expires});
			$db->set($conf->{db_name}.';warning0-'.$sender{ip} => $sender{fkey}."\n".$sender{to}) if($conf->{admin_email} && !$db->exists($conf->{db_name}.';warning-'.$sender{ip}));
		}
		inform('[check_end] added to blacklist: '.$sender{from}.' '.$sender{ip});
		log_stats($sender{ip}.' - - ['.strftime("%d/%b/%Y:%H:%M:%S %z", localtime).'] "GET /blacklist/'.$sender{to_domain}.'/'.$sender{to_user}.'?pk_total='. nearest(10, $var{total}).'  HTTP/1.1" 200 1024 "http://'.$sender{domain}.'/'.$sender{user}.'" "'.$conf->{ua}.'"');

	}elsif($var{score}>10){
                $msg->got_hit(uc($conf->{filter_name}), 'HEADER: ', score => nearest(0.01, 0.1*$var{score}));
	}

	inform('[check_end] done ('.$msg->get_score().')');
	return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::SpamAssassin::Contrib::Plugin::IPFilter - Blocks bad MTA behavior using IPTables.

=head1 VERSION

version 1.2

=head1 SYNOPSIS

To try this out, add this or uncomment this line in init.pre:

	LoadPlugin    Mail::SpamAssassin::Contrib::Plugin::IPFilter

I<Configuration defaults>

	iptables_support 6
	iptables_bin $PATH/iptables
	ip6tables_bin $PATH/ip6tables
	filter_name spamipfilter
	db_type	redis
	db_host 127.0.0.1
	db_port 6387
	db_user	 ''
	db_auth	 ''
	db_name spamipfilter
	trigger_score 6
	trigger_messages 3
	trigger_sensitivity 4
	average_score_for_rule 7
	expire_rule_seconds 172800
	seconds_between_messages 30
	seconds_to_decay_penalty 300
	expires_multiplier_penalty 1.5
	cache_decay_days 60
	blacklist_score 30
	common_hosts gmail.com, google.com, yahoo.com, hotmail.com, live.com
	admin_email ''
	admin_message Your message to $recipient from $email was blocked and
		your IP address $ip blacklisted due to excessive unsolicited
		bulk email. To reinstate your ability to send email to $recipient,
		please reply to $admin using a different off-network email,
		including the body of this message, with a request for reinstatement.
	log_dir /var/log
	verbose 0
	lang en

=head1 DESCRIPTION

Mail::SpamAssassin::Contrib::Plugin::IPFilter blacklists unsolicited bulk email senders using IPTables. It will blacklist the sender IP using the smallest network possible, up to /24, when UCE originates from multiple hosts on the same network. Depending on the diversity and frequency of spam received on a server, it may take a couple of days to become effective. Thereafter, the cache state will decay to prevent spammers from burning IP blocks.

Responsible, well-known email hosts (common_hosts) are given special treatment to avoid blacklisting their networks and the score is increased for external filtering of UCE originating from those hosts. The plugin may be configured to email the blacklisted sender a warning for remediation.

A crontab entry is created for maintenance. IPV6 support is experimental. Future versions may include a collaborative blacklist.

=head1 NAME

Mail::SpamAssassin::Contrib::Plugin::IPFilter - Blocks bad MTA behavior using IPTables.

=begin html

<p>The following options may be used in site-wide (local.cf) configuration files to customize operation, and must be prefixed by ipfilter_:</p>

<b>filter_name</b><br>
The name of the chain that Mail::SpamAssassin::Contrib::Plugin::IPFilter will create to block spammers. [a-zA-Z0-9_.]

<br><br><b>iptables_support</b><br>
	iptables support. 0 = disable iptables. 4 = support ipv4 only. 6 = support ipv4 and ipv6.

<br><br><b>iptables_bin</b><br>
	The path to the iptables binary on your system.

<br><br><b>ip6tables_bin</b><br>
	The path to the ip6tables binary on your system.

<br><br><b>db_type</b><br>
	The type of storage to use (mysql/redis).

<br><br><b>db_host</b><br>
	The IPv4 address of your database server.

<br><br><b>db_port</b><br>
	The port that the database server is listening on.

<br><br><b>db_user</b><br>
	The database user, if applicable.

<br><br><b>db_auth</b><br>
	The database password, if applicable.

<br><br><b>db_name</b><br>
	The database name (mysql) or the prefix for keys (redis) created and used by Mail::SpamAssassin::Contrib::Plugin::IPFilter. ^[a-zA-Z0-9_.]$

<br><br><b>log_dir</b><br>
	The directory to use for apache style logs reflecting spam messages for export to analytics. Informational messages are still logged via SpamAssassin.

<br><br><b>average_score_for_rule</b><br>
	The average spam score for a host required to trigger a rule after trigger_messages.

<br><br><b>seconds_between_messages</b><br>
	After how long should messages with the same envelope to/from be considered.

<br><br><b>cache_decay_days</b><br>
	After how long will entries in the cache decay, assuming no spam messages are seen. Note that the cache will decay according to: cumulative_spam_score_for_host * exp(-3*lastspam_delta/cache_decay_secs)

<br><br><b>expire_rule_seconds</b><br>
	After how long will a block rule expire.

<br><br><b>expires_multiplier_penalty</b><br>
	A factor used to penalize hosts with longer rule expiration based on the spam of score of the message resulting in a rule, relative to the average spam score required to set the rule.

<br><br><b>seconds_to_decay_penalty</b><br>
	A frequency indicator used to tune penalization for a given host based on how many spam messages were seen for that host over a time period.

<br><br><b>trigger_score</b><br>
	The score for which Mail::SpamAssassin::Contrib::Plugin::IPFilter will process a spam message. This should be greater than the SpamAssassin required_score.

<br><br><b>trigger_messages</b><br>
	The minimum number of spam messages from a given host before a rule is triggered.

<br><br><b>trigger_sensitivity</b><br>
	A quantity used to tune penalization for a given host based on how many spam messages were seen for that host.

<br><br><b>common_hosts</b><br>
	Hosts which should not be blacklisted via IPTables rule, and fall back to SpamAssassin blacklist.

<br><br><b>blacklist_score</b><br>
	A score to add to message headers of blacklisted senders originating from common_hosts.

<br><br><b>admin_email</b><br>
	The email address to send blacklist warnings from. If left unconfigured, no warnings will be sent.

<br><br><b>admin_message</b><br>
	The warning message that will be sent. Parameters $user, $domain, $ip, $email, $recipient and $admin may be used for templatization.

<br><br><b>whitelist</b><br>
	Any email address or ip address to whitelist. Email addresses may be specified as foo@example.com or just @example.com to match the whole domain, and IPs may be specified as 1.2.3.4 or just 1.2.3. to match the class C address space.

<br><br><b>verbose</b><br>
	Log additional information via Mail::SpamAssassin::Logger

=end html

=head1 COPYRIGHT

I<Copyright E<copy> 2016 - Tamer Rizk, Inficron Inc.>

This is free, open source software, licensed under the L<Revised BSD License|http://opensource.org/licenses/BSD-3-Clause>. Please feel free to use and distribute it accordingly.

=head1 AUTHOR

Tamer Rizk <foss@inficron.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Tamer Rizk.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

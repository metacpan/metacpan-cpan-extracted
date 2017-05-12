package EasyDBAccess;
use strict;
use warnings(FATAL=>'all');

our $VERSION = '3.1.2';

#===================================
#===Module  : 43effa740d56a6fd
#===Version : 4439fc8192ad837b
#===================================

#===================================
#===Module  : Framework::EasyDBAccess
#===File    : lib/Framework/EasyDBAccess.pm
#===Comment : the database access interface
#===Require : DBI DBD::Mysql Encode FileHandle
#===Require2: EasyHandler
#===================================

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 19937129           ===
#===Homepage: www.lua.cn         ===
#===================================

#=======================================
#===Author  : huang.shuai            ===
#===Email   : huang.shuai@adways.net ===
#===MSN     : huang.shuai@adways.net ===
#=======================================

#===3.1.2(2009-03-26): fix bug in batch_insert
#===3.1.1(2006-12-27): change document for return value detail
#===3.1.0(2006-12-07): fix bug in id() when concurrency
#===3.0.9(2006-11-24): add DEFAULT for column default value
#===3.0.8(2006-09-22): remove DESTROY function, when set InactiveDestroy true, you should not explicitly call to the disconnect method
#===3.0.7(2006-09-13): modified batch_insert
#===3.0.6(2006-07-21): change Makefile.PL
#===3.0.5(2006-07-20): change META.yml
#===3.0.4(2006-07-19): add insert_one_row(), update()
#===3.0.3(2006-07-18): modified global constants, document format
#===3.0.2(2006-07-13): modified function close(), modified select_one() for bugs
#===3.0.1(2006-07-12): u can get err_str from $dba->err_str()
#===3.0.0(2006-05-08): merge $param and $ext_option,more document
#===2.9.2(2006-04-12): remove relation between $_name_utf8 and EasyTool, add _EasyDBAccess_EasyHandler, use this package instead if EasyTool not load
#===2.9.1(2006-04-10): add option $_HIDE_CONN_PARAM, hide conn infomation by default when die, for security
#===2.9.0(2006-04-10): replace globe constant modifier from 'my' to 'our'
#===2.8.0(2006-04-05): add batch_insert function, add select_array function
#===2.7.0(2006-02-13): BUG Fix ,check ^1
#===2.6.0(2006-02-07): delete auto_die_handler function, delete install function, add note function
#===2.5.0(2006-02-07): new usage: $dba->err_code() $dba->err_code('ER_DUP_ENTRY') $dba->err_code(1062) 
#===2.4.0(2006-01-03): u can get err_code from $dba->err_code();
#===2.2.2(2005-09-07): use socket to connect mysql server
#===2.2.2(2005-08-10): change qquote check utf8::is_utf8 before use it,so that the program can run in perl low version
#===2.2.1(2005-07-01): rename errcode to err_code, add err_code ER_PARSE_ERROR
#===2.2.0(2005-07-01): return use wantarray
#===2.1.1(2005-04-28): add errcode function
#===2.1.0            : improve id function
#===2.0.4            : add once function
#===2.0.3            : some small bug fix
#===2.0.2            : encoding bug fix
#===2.0.1            : so that u can change $_debug in runtime >>my $_debug=1; => our $_debug=1;

#===ERR_CODE
#NO_ERROR     0
#NO_LINE      1
#PARAM_ERR    2
#CONN_ERR     3
#PREPARE_ERR  4
#EXEC_ERR     5

#===INSTALL for specified function
#===ID
#CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL ,PRIMARY KEY (ATTRIB))
#CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT UNSIGNED NOT NULL ,PRIMARY KEY(ATTRIB)) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin
#===SID
#CREATE TABLE SID(RECORD_TIME INT UNSIGNED NOT NULL, SID INT UNSIGNED NOT NULL,COMMENT VARCHAR(255) DEFAULT NULL,PRIMARY KEY(RECORD_TIME,SID))
#CREATE TABLE SID(RECORD_TIME INT UNSIGNED NOT NULL, SID INT UNSIGNED NOT NULL,COMMENT VARCHAR(255) DEFAULT NULL,PRIMARY KEY(RECORD_TIME,SID)) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin
#===NOTE
#CREATE TABLE NOTE(TEXT TEXT NOT NULL, RECORD_TIME INT UNSIGNED NOT NULL)
#CREATE TABLE NOTE(TEXT TEXT NOT NULL, RECORD_TIME INT UNSIGNED NOT NULL) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin


use DBI;
use Encode;
use FileHandle;

#==3.0.3==
#our $_pkg_name=__PACKAGE__;
#===end===
sub foo{1};

#==3.0.3==
our $_pkg_name;
#===end===
our $_DEBUG;
our $_SETNAMES;
our $_HIDE_CONN_PARAM;
our $_name_mysql_ver_3;
our $_name_mysql_ver_41;
our $_name_utf8;
our $_dbh_attr_default;
our $_mysql_conn_attrib;
our $_mysql_error_code_map;
our $_ONCE;
our $_str_func_new;
our $_str_func_id;
#==3.0.3==
our $_str_func_sid;
our $_str_func_die_to_file;
our $_str_func_err_str;
our $_str_func_err_code;
our $_str_func_lookup_err_code;
our $_str_func_is_int;
#===end===
our $_str_func_execute;
our $_str_func_select;
our $_str_func_select_one;
our $_str_func_select_col;
our $_str_func_select_row;
our $_str_func_select_array;
our $_str_new_param_err;
our $_str_new_conn_err;
our $_str_sql_null_err;
our $_str_inline_null_err;
our $_str_no_line;
our $_str_param_err;
our $_str_conn_err;
our $_str_prepare_err;
our $_str_exec_err;
our $_str_dbh_do_err;
our $_str_dbh_prepare_err;
our $_str_dbh_execute_err;
our $_str_dbh_fetchall_arrayref_err;
our $_str_dbh_fetchrow_arrayref_err_a;
our $_str_dbh_fetchrow_arrayref_err_b;
our $_str_dbh_fetchrow_hashref_err_a;
our $_str_dbh_fetchrow_hashref_err_b;
our $_max_conflict;

BEGIN{

#==3.0.3==
$_pkg_name=__PACKAGE__;
#===end===

#===========================================
#=== options
  #===if you set $_DEBUG=false then no "die"
  $_DEBUG=1;

  #===if you set $_SETNAMES=false then won't do set names when connect
  $_SETNAMES=1;
  
  #===if you set $_HIDE_CONN_PARAM=true, then won't show connect param when die(protect connection password)
  $_HIDE_CONN_PARAM=1;
  
#============================================

#============================================
#===names
  #===name for mysql version
  $_name_mysql_ver_3='3.23';
  $_name_mysql_ver_41='4.1';

  #===use the name of EasyTool if exist
  $_name_utf8='utf8';
#============================================

#============================================
$_dbh_attr_default = {PrintError=>0,RaiseError=>0,LongReadLen=>1048576,FetchHashKeyName=>'NAME_lc',AutoCommit=>1};
$_mysql_conn_attrib= ['host','port','database','mysql_client_found_rows','mysql_compression','mysql_connect_timeout','mysql_read_default_file','mysql_read_default_group','mysql_socket','mysql_ssl','mysql_ssl_client_key','mysql_ssl_client_cert','mysql_ssl_ca_file','mysql_ssl_ca_path','mysql_ssl_cipher','mysql_local_infile'];
$_mysql_error_code_map={
  ER_DUP_ENTRY=>1062,         #Duplicate entry for key
  ER_NO_SUCH_TABLE=>1146,     #No such table
  ER_PARSE_ERROR=>1064        #SQL string parse error
};
#============================================

$_ONCE=0;#ignore the next function's error

$_str_func_new='new';
$_str_func_id='id';
#==3.0.3==
$_str_func_sid='sid';
$_str_func_die_to_file='die_to_file';
$_str_func_err_str='err_str';
$_str_func_err_code='err_code';
$_str_func_lookup_err_code='_lookup_err_code';
$_str_func_is_int='is_int';
#===end===
$_str_func_execute='execute';
$_str_func_select='select';
$_str_func_select_one='select_one';
$_str_func_select_col='select_col';
$_str_func_select_row='select_row';
$_str_func_select_array='select_array';

$_str_new_param_err='only can accept one or two param';
$_str_new_conn_err='connect to database failed';
$_str_sql_null_err='sql string is null';
$_str_inline_null_err='null in inline param';
$_str_no_line='NO_LINE';
$_str_param_err='PARAM_ERR';
$_str_conn_err='CONN_ERR';
$_str_prepare_err='PREPARE_ERR';
$_str_exec_err='EXEC_ERR';
$_str_dbh_do_err='when call $dbh->do, system return fause';
$_str_dbh_prepare_err='when call $dbh->prepare, system return fause';
$_str_dbh_execute_err='when call $dbh->execute, system return fause';
$_str_dbh_fetchall_arrayref_err='when call $sth->fetchall_arrayref, system return fause, maybe u use select on a none select sql';
$_str_dbh_fetchrow_arrayref_err_a='when call $sth->fetchrow_hashref, system return fause, maybe u use select on a none select sql';
$_str_dbh_fetchrow_arrayref_err_b='when call $dbh->fetchrow_arrayref, system return fause, maybe u try to get one row from a result set with no row in it';
$_str_dbh_fetchrow_hashref_err_a='when call $sth->fetchrow_hashref, system return fause, maybe u use select on a none select sql';
$_str_dbh_fetchrow_hashref_err_b='when call $sth->fetchrow_hashref, system return fause, maybe u try to get one row from a result set with no row in it';

$_max_conflict=10;

}

sub new {
  my $class = shift;
  my ($param,$option);
  
  my $once=($_ONCE==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;};
  
  my $param_count=scalar(@_);
  if($param_count==1){
    ($param)=@_;
  }elsif($param_count==2){
    ($param,$option)=@_;
  }else{
    my ($err_code,$err_detail)=(2,'');
    my $sys_err='';
    my $param="ParamInfo :\n".($_HIDE_CONN_PARAM?'connect param is hide for security':_dump([@_]))."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_new\(\) throw $_str_param_err\nHelpNote  : $_str_new_param_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      CORE::die $err_detail;
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(!defined($option)){$option={};}
  #===make a copy of $param, merge two param
  $param={%$param,%$option};

  my $self = bless {},$class;
  my $dbh;
  my $type=delete $param->{'type'}||'mysql';
  my $die_handler=$param->{die_handler};

  if(!defined($die_handler)){
    if(defined($param->{err_file})){
      if(defined(&EasyHandler::foo)){
        $die_handler=EasyHandler->new(\&die_to_file,[$param->{err_file}]);
      }else{
        $die_handler=_EasyDBAccess_EasyHandler->new(\&die_to_file,[$param->{err_file}]);
      }
    }
  }

  my ($version,$ver,$unicode,$encoding);

  if($type eq 'mysql'){
    my $usr=_IFNULL(delete($param->{usr}),'root');
    my $pass=_IFNULL(delete($param->{pass}),'');
    my $dsn;
    my $socket=delete($param->{socket});
    if(defined($socket)){
      $encoding=_IFNULL(delete($param->{encoding}),$_name_utf8);
      $unicode=_IFNULL(delete($param->{unicode}),0);
      $version=delete $param->{version};
      my $extra_conn_attrib='';
      foreach(@$_mysql_conn_attrib){
        if(defined($param->{$_})){
          $extra_conn_attrib.=$_.'='.(delete $param->{$_}).';';
        }
      }
      $dsn ='DBI:mysql:'.$extra_conn_attrib.'mysql_socket='.$socket;
    }else{
      my $host=_IFNULL(delete($param->{host}),'127.0.0.1');
      my $port=_IFNULL(delete($param->{port}),3306);
      $encoding=_IFNULL(delete($param->{encoding}),$_name_utf8);
      $unicode=_IFNULL(delete($param->{unicode}),0);
      $version=delete $param->{version};
      my $extra_conn_attrib='';
      foreach(@$_mysql_conn_attrib){
        if(defined($param->{$_})){
          $extra_conn_attrib.=$_.'='.(delete $param->{$_}).';';
        }
      }
      $dsn ='DBI:mysql:host='.$host.';'.$extra_conn_attrib.'port='.$port;
    }

    #===merge default attrib and user set attrib
    my $attr={%$_dbh_attr_default};
    while(my ($k,$v)=each %$param){$attr->{$k}=$v;}

    #===$param now no use at all,so destroy it
    undef %$param;

    #===try to connect
    $dbh = DBI->connect($dsn,$usr,$pass,$attr);

    #===connect to database failed
    if(!defined($dbh)){
      my ($err_code,$err_detail)=(3,'');
      my $sys_err=defined(&DBI::errstr)?"ErrString : ".&DBI::errstr."\n":'';
      my $param="ParamInfo :\n".($_HIDE_CONN_PARAM?'connect param is hide for security':_dump([@_]))."\n";
      my $caller='';
      for(my $i=0;;$i++){
        my $ra_caller_info=[caller($i)];
        if(scalar(@$ra_caller_info)==0){last;}
        else{
          $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
        }
      }
      $caller="CallerInfo:\n$caller";
      $err_detail="$_pkg_name\:\:$_str_func_new\(\) throw $_str_conn_err\nHelpNote  : $_str_new_conn_err\n$sys_err$param$caller\n";
      if($_DEBUG&&!$once){
        if(defined($die_handler)){
          $die_handler->execute($err_code,$err_detail,$_pkg_name);
        }else{
          CORE::die $err_detail;
        }
      }
      return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
    }

    #===get database version
    if(!defined($version)){
      $version=$dbh->selectrow_arrayref("SHOW VARIABLES LIKE 'VERSION'")->[1];
    }
    $ver=substr($version,0,3);
    
    #===if version>4.1 then set charset
    if($ver>=$_name_mysql_ver_41&&$_SETNAMES){
      $dbh->do("SET NAMES '$encoding'");
    }
  }else{CORE::die "$_pkg_name\:\:$_str_func_new\(\) unknow database type";}

  $self->{dbh}=$dbh;
  $self->{type}=$type;
  $self->{ver}=$ver;
  $self->{version}=$version;
  $self->{die_handler}=$die_handler;
  $self->{unicode}=$unicode;
  $self->{encoding}=$encoding;
#==3.0.1==
  $self->{err_str}=undef;
#===end===
  $self->{err_code}=undef;
  $self->{once}=0;#ignore the next function's error
  return wantarray?($self,0,undef,$_pkg_name):$self;
}

sub dbh{return $_[0]->{dbh};}
#==3.0.2==
#sub close{undef $_[0];return 1;}
sub close{
  if(defined $_[0]){
      if(defined($_[0]->{dbh})){
        $_[0]->{dbh}->disconnect();
        $_[0]->{dbh}=undef;
      }
      undef $_[0];
  }
  return 1;
}
#===end===
sub type{return $_[0]->{type};}
sub once{
  my ($self)=@_;
  if(ref $self eq $_pkg_name){
    $self->{once}=1;
  }else{
    $_ONCE=1;
  }
}

sub id{
  my $self=shift;
  if($self->{type} eq 'mysql'){
    if(defined($_[1])&&($_[1]>1)){
      my $rc=$self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+?) WHERE ATTRIB=?;',undef,$_[1],defined($_[0])?$_[0]:'ANON');
      if($rc==0){
        $self->{dbh}->do('INSERT INTO RES(ATTRIB,ID) VALUES(?,0);',undef,defined($_[0])?$_[0]:'ANON');
        $self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+?) WHERE ATTRIB=?;',undef,$_[1],defined($_[0])?$_[0]:'ANON');
      }
      my $id=$self->{dbh}->selectrow_arrayref('SELECT LAST_INSERT_ID();')->[0];
      return $id;
    }
    my $rc=$self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+1) WHERE ATTRIB=?;',undef,defined($_[0])?$_[0]:'ANON');
    if($rc==0){
#==3.1.0==
#      $self->{dbh}->do('INSERT INTO RES(ATTRIB,ID) VALUES(?,1);',undef,defined($_[0])?$_[0]:'ANON');
#      return 1;
      $self->{dbh}->do('INSERT INTO RES(ATTRIB,ID) VALUES(?,0);',undef,defined($_[0])?$_[0]:'ANON');
      $self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+1) WHERE ATTRIB=?;',undef,defined($_[0])?$_[0]:'ANON');
#==end==
    }
    my $id=$self->{dbh}->selectrow_arrayref('SELECT LAST_INSERT_ID();')->[0];
    return $id;
  }else{CORE::die "$_pkg_name\:\:$_str_func_id\(\) unknow database type;";}
}


sub sid{
  my $self=shift;
  if($self->{type} eq 'mysql'){
    my ($now,$sid,$succ)=(CORE::time(),undef,undef);
    for(1..$_max_conflict){
      my $rc=int $self->{dbh}->do('INSERT IGNORE INTO SID(RECORD_TIME,SID,COMMENT)VALUES(?,LAST_INSERT_ID(FLOOR(RAND()*4294967296)+1),?)',undef,$now,$_[0]);
      if($rc==1){
        $sid=$self->{dbh}->selectrow_arrayref('SELECT LAST_INSERT_ID()')->[0];
        $succ=1;
        last;
      }else{
        next;
      }
    }
    if($succ){
      return sprintf("%08x%08x",$now,$sid);
    }else{
#==3.0.3==
#     CORE::die $_pkg_name."::sid: too much conflict";
      CORE::die "$_pkg_name\:\:$_str_func_sid\(\) too much conflict";
#===end===
    }
#==3.0.3==
# }else{CORE::die "$_pkg_name\:\:$_str_func_id\(\) unknow database type;";}
  }else{CORE::die "$_pkg_name\:\:$_str_func_sid\(\) unknow database type;";}
#===end===
}

sub sid_info{
  my $self=shift;
  if(defined($_[0])&&(ref($_[0]) eq '')&&($_[0]=~/^([0-9a-fA-F]{8})([0-9a-fA-F]{8})$/)){
    my $rtn=$self->select_row('SELECT RECORD_TIME,SID,COMMENT FROM SID WHERE RECORD_TIME=? AND SID=?',[hex $1,hex $2]);
    return $rtn;
  }
  return undef;
}

sub note{
  my $self=shift;
  return $self->{dbh}->do('INSERT INTO NOTE(TEXT,RECORD_TIME) VALUES(?,?);',undef,$_[0],CORE::time());
}

sub _replace {
  while(my($k,$v)=each %{$_[1]}){
    if(!defined($v)){return 0;}
    $_[0]=~s/\Q%$k\E/$v/g;
  }
  return 1;
}

sub _encode{
  if(defined($_[2])){
    $_[0]=Encode::encode($_[2],$_[0]);
    my $ra=[];
    foreach(@{$_[1]}){
      push @$ra,utf8::is_utf8($_)?Encode::encode($_[2],$_):$_;
    }
    $_[1]=$ra;
  }else{
    &utf8::encode($_[0]);
    my $ra=[];
    foreach(@{$_[1]}){
      if(utf8::is_utf8($_)){&utf8::encode($_);}
      push @$ra,$_;
    }
    $_[1]=$ra;
  }
}

sub _decode{
  my $ref=ref $_[0];
  if($ref eq 'ARRAY'){
    foreach (@{$_[0]}){
      _decode($_,$_[1]);
    }
  }elsif($ref eq 'HASH'){
    foreach (keys(%{$_[0]})){
      my $k=$_;
      _decode($k,$_[1]);
      my $v=delete $_[0]->{$_};
      _decode($v,$_[1]);
      $_[0]->{$k}=$v;
    }
  }else{
    if(defined($_[1])){
      $_[0]=Encode::decode($_[1],$_[0]);
    }else{
      &utf8::decode($_[0]);
    }
  }
}

# put a string value in double quotes
sub qquote {
  local($_) = shift;
  s/([\\\"\@\$])/\\$1/g;
  s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if (defined(&utf8::is_utf8) && utf8::is_utf8($_));
  return qq("$_") unless 
    /[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/;  # fast exit
  s/([\a\b\t\n\f\r\e])/{
    "\a" => "\\a","\b" => "\\b","\t" => "\\t","\n" => "\\n",
      "\f" => "\\f","\r" => "\\r","\e" => "\\e"}->{$1}/eg;
  s/([\0-\037\177])/'\\x'.sprintf('%02X',ord($1))/eg;
  s/([\200-\377])/'\\x'.sprintf('%02X',ord($1))/eg;
  return qq("$_");
}

sub _dump{
  my $max_line=80;
  my $param_count=scalar(@_);
  my ($flag,$str1,$str2);
  if($param_count==1){
    my $data=$_[0];
    my $type=ref $data;
    if($type eq 'ARRAY'){
      my $strs=[];
      foreach(@$data){push @$strs,_dump($_);}
      
      $str1='[';
      $flag=0;
      foreach(@$strs){$str1.=$_.', ';$flag=1;}
      if($flag==1){chop($str1);chop($str1);}
      $str1.=']';

      $str2='[';
      foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
      $str2.="\n]";
      
      return length($str1)>$max_line?$str2:$str1;
    }elsif($type eq 'HASH'){
      my $strs=[];
      foreach(keys(%$data)){push @$strs,[qquote($_),_dump($data->{$_})];}
      
      $str1='{';
      $flag=0;
      foreach(@$strs){$str1.="$_->[0] => $_->[1], ";$flag=1;}
      if($flag==1){chop($str1);chop($str1);}
      $str1.='}';

      $str2='{';
      foreach(@$strs){ $_->[1]=~s/\n/\n\x20\x20/g;
        $str2.="\n\x20\x20$_->[0] => $_->[1],";}
      $str2.="\n}";
      
      return length($str1)>$max_line?$str2:$str1;
    }elsif($type eq ''){
      $flag=0;
      if(!defined($data)){return 'undef'};
      eval{if($data eq int $data){$flag=1;}};
      if($@){undef $@;}
      if($flag==0){return qquote($data);}
      elsif($flag==1){return $data;}
    }else{
      return ''.$data;
    }
  }else{
    my $strs=[];
    foreach(@_){push @$strs,_dump($_);}

    $str1='(';
    $flag=0;
    foreach(@$strs){$str1.=$_.', ';$flag=1;}
    if($flag==1){chop($str1);chop($str1);}
    $str1.=')';

    $str2='(';
    foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
    $str2.="\n)";
      
    return length($str1)>$max_line?$str2:$str1;
  }
}

sub _IFNULL{
  defined($_[0])?$_[0]:$_[1];
}

sub build_array{
  my ($filter,$hash,$array)=@_;
  my $ra=[];
  
  #^1
  #===BUG,fixed in 2.7.0
  #$array=defined($array)?$array=[@$array]:[];
  #^1 END
  
  $array=defined($array)?[@$array]:[];

  my $err_code=0;
  foreach(@$filter){
    if(defined($_)&&($_ ne '?')){
      if(exists($hash->{$_})){
        push @$ra,$hash->{$_};
      }else{
        $err_code=1;
        push @$ra,undef;
      }
    }else{
      push @$ra,shift @$array;
    }
  }
  return wantarray ? ($ra,$err_code):$ra;
}

sub build_update{
  my ($filter,$hash)=@_;;
  my $str='';
  my $ra_bind_param=[];
  my $flag=0;
  foreach(@$filter){
    $_=lc($_);
    if(exists($hash->{$_})){
      push @$ra_bind_param,$hash->{$_};
      $str.=uc($_).'=?,';
      $flag++;
    }
  }
  my $str2=$str;
  if($flag!=0){chop($str2)};
  return wantarray ? ($str2,$ra_bind_param,$flag,$str):$str;
}

sub batch_insert{
  my $self=shift;
  my ($sql_str,$values_tmpl,$values,$max_count)=@_;

  my $values_str='';my $bind_param=[];my $c=0;  
  my $item_count=scalar(@$values);
#==3.1.2==
#if ($item_count==0){return 1;}
if ($item_count==0){return wantarray?(1,0,undef,$_pkg_name):1;}
#==end==

  if(!defined($max_count)){$max_count=1;}
  for(my $i=0;$i<$item_count;$i++ ){
#==3.0.9==
  	my $tmp_tmpl = $values_tmpl;
  	my $posi = -1;
  	for(my $j=0; $j<@{$values->[$i]}; ++$j){
  			$posi = index($tmp_tmpl, '?', $posi + 1);
  			if (DEFAULT($values->[$i]->[$j])){
  					substr($tmp_tmpl, $posi, 1, 'DEFAULT');
  			}
  	}
    $values_str.=$tmp_tmpl.',';
    my $values_i = [];
  	for(my $j=0; $j<@{$values->[$i]}; ++$j){
  			if (!DEFAULT($values->[$i]->[$j])){
  					push @$values_i, $values->[$i]->[$j];
  			}
  	}
    push @$bind_param,@$values_i;
#===end===
    $c++;
    if($c>=$max_count){
      my $s=$sql_str;
      chop($values_str);
      $s=~s/\%V/$values_str/g;
      $self->{dbh}->do($s,undef,@$bind_param);
#==3.0.7==
      if($self->{dbh}->err){
				my $err_detail;
				my $sys_err=defined($self->{dbh}->errstr)?"ErrString : ".$self->{dbh}->errstr."\n":'';
    		my $param="ParamInfo :\n"._dump([$s,@$bind_param])."\n";
		    my $caller='';
		    for(my $i=0;;$i++){
		      my $ra_caller_info=[caller($i)];
		      if(scalar(@$ra_caller_info)==0){last;}
		      else{
		        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
		      }
		    }
		    $caller="CallerInfo:\n$caller";
		    $err_detail="$_pkg_name\:\:batch_insert\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_do_err\n$sys_err$param$caller\n";
    		return wantarray?(0,5,$err_detail,$_pkg_name):0;
			}
#===end===
      $values_str='';$c=0;$bind_param=[];
    }
  }

  if($c>0){
    my $s=$sql_str;
    chop($values_str);
    $s=~s/\%V/$values_str/g;
    $self->{dbh}->do($s,undef,@$bind_param);
#==3.0.7==
      if($self->{dbh}->err){
				my $err_detail;
				my $sys_err=defined($self->{dbh}->errstr)?"ErrString : ".$self->{dbh}->errstr."\n":'';
    		my $param="ParamInfo :\n"._dump([$s,@$bind_param])."\n";
		    my $caller='';
		    for(my $i=0;;$i++){
		      my $ra_caller_info=[caller($i)];
		      if(scalar(@$ra_caller_info)==0){last;}
		      else{
		        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
		      }
		    }
		    $caller="CallerInfo:\n$caller";
		    $err_detail="$_pkg_name\:\:batch_insert\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_do_err\n$sys_err$param$caller\n";
    		return wantarray?(0,5,$err_detail,$_pkg_name):0;
			}
#===end===
  }

#==3.0.7==
#  return 1;  
  return wantarray?(1,0,undef,$_pkg_name):1;
#===end===
}

#==3.0.4==
#===wang.yezhuo add start===

sub insert_one_row {
  my $self = shift;
  my ($sql, $filter, $rh_data, $ra) = @_;

  my $ra_param = build_array($filter, $rh_data, $ra);

  return $self->execute($sql, $ra_param);
}

sub update {
  my $self = shift;
  my ($sql, $filter, $rh_data, $ra_param) = @_;

  my ($item_str, $item_bind_param, $flag, $item_str2) = build_update($filter, $rh_data);

  return $self->execute($sql, [@$item_bind_param, @$ra_param], {ITEM => $item_str, COMMAITEM => $item_str2});
}

#===wang.yezhuo add end===
#===end===

sub die_to_file{
  my $file_path= shift;
  my ($err_pkg,$err_code,$err_detail,$record_time)=(undef,undef,undef,CORE::time);
  my $param_count=scalar(@_);
  if($param_count==1){
    ($err_detail)=@_;
  }elsif($param_count==3){
    ($err_code,$err_detail,$err_pkg)=@_;
  }elsif($param_count==4){
    ($err_code,$err_detail,$err_pkg,$record_time)=@_;
  }else{
#==3.0.3==
#   CORE::die "die_to_file param error;";
    CORE::die "$_pkg_name\:\:$_str_func_die_to_file\(\) param error;";
#===end===    
  }

  $_=[localtime($record_time)];
  my $prefix="#####".sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0])."\n";

  my $result=append_file($file_path,$prefix.$err_detail."\n");
  if($result){
    #log succ
    CORE::die;
  }else{
#==3.0.3==
#   CORE::die($_pkg_name.'::_lookup_err_code: param count should be 1');
    CORE::die("$_pkg_name\:\:$_str_func_die_to_file\(\) param count should be 1");
#===end===    
  }
}

#==3.0.1==
sub err_str{
    my $param_count=scalar(@_);
    if($param_count==1){
        return $_[0]->{err_str};
    }else{
      CORE::die("$_pkg_name\:\:$_str_func_err_str\(\) param count should be 1");
    }
}
#===end===

sub err_code{
  my $param_count=scalar(@_);
  if($param_count==1){
    return $_[0]->{err_code};
  }elsif($param_count==2){
    return defined($_[0]->{err_code})&&$_[0]->{err_code}==&_lookup_err_code($_[1]);
  }else{
#==3.0.3==
#   CORE::die($_pkg_name.'::_lookup_err_code: param count should be 1 or 2');
    CORE::die("$_pkg_name\:\:$_str_func_err_code\(\) param count should be 1 or 2");
#===end===
  }
}

sub _lookup_err_code{
  my $param_count=scalar(@_);
  if($param_count==1){
    local $_=$_[0];
    if(&is_id($_)){
      return int $_;
    }else{
      return $_mysql_error_code_map->{$_};
    }
  }else{
#==3.0.3==
#    CORE::die($_pkg_name.'::_lookup_err_code: param count should be 1');
    CORE::die("$_pkg_name\:\:$_str_func_lookup_err_code\(\) param count should be 1");
#===end===
  }
}

sub is_int{
  my $param_count=scalar(@_);
  my ($str,$num,$max,$min)=(exists $_[0]?$_[0]:$_,undef,undef,undef);
  if($param_count==1||$param_count==2||$param_count==3){
    eval{$num=int($str);};
    if($@){undef $@;return defined(&_name_false)?&_name_false:'';}
    if($num ne $str){return defined(&_name_false)?&_name_false:'';}
    if($param_count==1){
      $max=2147483648;$min=-2147483648;
    }elsif($param_count==2){
      $max=2147483648;$min=$_[1];
    }elsif($param_count==3){
      $max=$_[2];$min=$_[1];
    }else{
#==3.0.3==
#     CORE::die 'is_int: BUG!';
      CORE::die "$_pkg_name\:\:$_str_func_is_int\(\) BUG!";
#===end===
    }
    if((!defined($min)||$num>=$min)&&(!defined($max)||$num<$max)){
      return defined(&_name_true)?&_name_true:1;
    }else{
      return defined(&_name_false)?&_name_false:'';
    }
  }else{
#==3.0.3==
#   CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_int: param count should be 1, 2 or 3');
    CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'')."$_str_func_is_int\(\) param count should be 1, 2 or 3");
#===end===
  }
}

sub is_id{
  return is_int(shift,1,4294967296);
}

sub append_file{
  my ($file_path,$data)=@_;
  my $fh=FileHandle->new($file_path,'a');
  if(!defined($fh)){return undef};
  $fh->syswrite($data);
  $fh->close();
}

#==3.0.8==
#when set InactiveDestroy true, you should not explicitly call to the disconnect method
#DESTROY{
#  if(defined($_[0]->{dbh})){
#    $_[0]->{dbh}->disconnect();
#    undef $_[0]->{dbh};
#  }
#}
#===end===

sub execute{
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;
  
  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});;
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }
#==3.0.9==
  	my $tmp_tmpl = $sql_str;
  	my $posi = -1;
  	for(my $j=0; $j<@$bind_param; ++$j){
  			$posi = index($tmp_tmpl, '?', $posi + 1);
  			if (DEFAULT($bind_param->[$j])){
  					substr($tmp_tmpl, $posi, 1, 'DEFAULT');
  			}
  	}
    $sql_str=$tmp_tmpl;
    my $values_i = [];
  	for(my $j=0; $j<@$bind_param; ++$j){
  			if (!DEFAULT($bind_param->[$j])){
  					push @$values_i, $bind_param->[$j];
  			}
  	}
    $bind_param = $values_i;
#===end===
  
  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}
  $succ=$self->{dbh}->do($sql_str,undef,@$bind_param);
  if($self->{dbh}->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($self->{dbh}->errstr)?"ErrString : ".$self->{dbh}->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_do_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }
  return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub select {
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;

  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

  my $sth = $self->{dbh}->prepare($sql_str);
  $succ = $sth->execute(@$bind_param);
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.1==
    $self->{err_str}=$sth->errstr;
#===end===
    $self->{err_code}=$sth->err;
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

    $succ=$sth->fetchall_arrayref({});
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchall_arrayref_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }
  $sth->finish();
  if($unicode){_decode($succ,$dst_encoding);};
  return wantarray?($succ,0,undef,$_pkg_name):$succ;
}


sub select_row{
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;

  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

  my $sth = $self->{dbh}->prepare($sql_str);
  $succ = $sth->execute(@$bind_param);
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.1==
    $self->{err_str}=$sth->errstr;
#===end===
    $self->{err_code}=$sth->err;
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }

  $succ=$sth->fetchrow_hashref();
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchrow_hashref_err_a\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }elsif(!$succ){
    my ($err_code,$err_detail,$die_handler)=(1,'',$self->{die_handler});
    my $sys_err='';
    $sth->finish();
    my $param='';
    my $caller='';
    $err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_no_line\nHelpNote  : $_str_dbh_fetchrow_hashref_err_b\n$sys_err$param$caller\n";
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }
  $sth->finish();
  if($unicode){_decode($succ,$dst_encoding);};
  return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub select_one{
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;

  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
#==3.0.2==
#   return (undef,$err_code,$err_detail,$_pkg_name,undef);
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
#===end===
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
#==3.0.2==
#   return (undef,$err_code,$err_detail,$_pkg_name,undef);
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
#===end===
  }

  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}
  
  my $sth = $self->{dbh}->prepare($sql_str);
  $succ = $sth->execute(@$bind_param);
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.1==
    $self->{err_str}=$sth->errstr;
#===end===
    $self->{err_code}=$sth->err;
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
#==3.0.2==
#   return ($succ,$err_code,$err_detail,$_pkg_name,$succ);
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
#===end===
  }

  $succ=$sth->fetchrow_arrayref();
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchrow_arrayref_err_a\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }elsif(!$succ){
    my ($err_code,$err_detail,$die_handler)=(1,'',$self->{die_handler});
    my $sys_err='';
    $sth->finish();
    my $param='';
    my $caller='';
    $err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_no_line\nHelpNote  : $_str_dbh_fetchrow_arrayref_err_b\n$sys_err$param$caller\n";
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }
  $sth->finish();
  if($unicode){_decode($succ->[0],$dst_encoding);};
  return wantarray?($succ->[0],0,undef,$_pkg_name):$succ->[0];
}

sub select_col{
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;

  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

  my $sth = $self->{dbh}->prepare($sql_str);
  $succ = $sth->execute(@$bind_param);
  if(!$succ){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.1==
    $self->{err_str}=$sth->errstr;
#===end===
    $self->{err_code}=$sth->err;
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
  }

  $succ=$sth->fetchall_arrayref([0]);
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchall_arrayref_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }
  $sth->finish();
  for(my $i=scalar(@$succ);$i-->0;){
    $succ->[$i]=$succ->[$i]->[0];
  }
  if($unicode){_decode($succ,$dst_encoding);};
  return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub select_array{
  my $self=shift;
  my ($sql_str,$bind_param,$inline_param)=@_;
  if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
  }elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
    $inline_param=$bind_param;
    $bind_param=[];
  }else{
    $bind_param=[];
  }
  my $succ=1;

  my $once=($_ONCE==1||$self->{once}==1)?1:0;
  if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};
#==3.0.1==
  $self->{err_str}=undef if defined($self->{err_str});
#===end===
  $self->{err_code}=undef if defined($self->{err_code});

  if(!defined($sql_str)){
    my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_array\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  if(defined($inline_param)){
    $succ=_replace($sql_str,$inline_param);
  };

  if(!$succ){
    my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
    my $sys_err='';
    my $param="ParamInfo :\n"._dump([@_])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_array\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }  
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

  my $unicode=$self->{unicode};
  my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
  if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

  my $sth = $self->{dbh}->prepare($sql_str);
  $succ = $sth->execute(@$bind_param);
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.1==
    $self->{err_str}=$sth->errstr;
#===end===
    $self->{err_code}=$sth->err;
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_array\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }

    $succ=$sth->fetchall_arrayref();
  if($sth->err){
    my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
    my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
#==3.0.4==
    $self->{err_str}=$self->{dbh}->errstr;
    $self->{err_code}=$self->{dbh}->err;
#===end===
    $sth->finish();
    my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
    my $caller='';
    for(my $i=0;;$i++){
      my $ra_caller_info=[caller($i)];
      if(scalar(@$ra_caller_info)==0){last;}
      else{
        $caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
      }
    }
    $caller="CallerInfo:\n$caller";
    $err_detail="$_pkg_name\:\:$_str_func_select_array\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchall_arrayref_err\n$sys_err$param$caller\n";
    if($_DEBUG&&!$once){
      if(defined($die_handler)){
        $die_handler->execute($err_code,$err_detail,$_pkg_name);
      }else{
        CORE::die $err_detail;
      }
    }
    return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
  }
  $sth->finish();
  if($unicode){_decode($succ,$dst_encoding);};
  return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

#==3.0.9==
sub DEFAULT{
  my $code=1;
  if(scalar(@_)==0){
    return bless [$code,'DEFAULT'],'EasyDBAccess::CONSTANT';
  }elsif(scalar(@_)==1){
    return ref $_[0] eq 'EasyDBAccess::CONSTANT' && $_[0]->[0]==$code?1:'';
  }else{
    die 'EasyDBAccess::DEFAULT: param number should be 0 or 1';
  }
}
#===end===

1;


package _EasyDBAccess_EasyHandler;

our $_pkg_name=__PACKAGE__;
sub foo{1};

our $_type_value=1;
our $_type_sub=2;

sub new{
  my $param_count=scalar(@_);
  my $self = bless {},$_pkg_name;
  if($param_count==1){
    $self->{'type'}=$_type_value;
    $self->{'value'}='';
  }elsif($param_count==2){
    my ($class,$value)=@_;
    $self->{'type'}=$_type_value;
    $self->{'value'}=$value;
  }elsif($param_count==3){
    my($class,$sub,$param)=@_;
    $self->{'type'}=$_type_sub;
    $self->{'sub'}=$sub;
    $self->{'param'}=[@$param];
  }else{
    CORE::die $_pkg_name.'::new: param not fit';
  }
  return $self;
}

sub execute{
  my $self=shift;
  if($self->{'type'}==$_type_value){
    return $self->{'value'};
  }elsif($self->{'type'}==$_type_sub){
    return $self->{'sub'}->(@{$self->{'param'}},@_);
  }else{
    CORE::die $_pkg_name.'::execute: not a valid type;';
  }
}

1;

__END__




=pod
		
=head1 NAME

EasyDBAccess - Perl Database Access Interface

=head1 SYNOPSIS

  use EasyDBAccess;
  
  if(defined(&EasyDBAccess::foo)){
    print "lib is included";
  }else{
    print "lib is not included";
  }
  
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
  my $dba=EasyDBAccess->new({socket=>'/tmp/mysql.sock',usr=>'root',pass=>'passwd',database=>'test_db'});
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db',encoding=>'gbk'});
      
  #disable die in next operation 
  EasyDBAccess->once();
  my ($dba,$err_code)=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
  if($err_code==3){
    print "Connect Error";
  }elsif($err_code==0){
    print "Connect Succ";
  }else{
    CORE::die 'BUG';
  }

  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{err_file=>'\var\log\logfile'});
      
  my $die_handler=EasyHandler->new(\&die_to_file,['\var\log\logfile']);
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{die_handler=>$die_handler});


  my $dbh=$dba->dbh();

  EasyDBAccess->once();
  $dba->once();

  $re=$dba->select_one('select id from person limit 0,1');
  #$re=1
  ($re,$err_code)=$dba->select_one('select id from person limit 0,1'); 
  #$re=1,$err_code=0
  ($re,$err_code)=$dba->select_one('select id from person2 limit 0,1');
  #table person2 doesn't exist, will die
  
  $dba->once();
  ($re,$err_code,$err_detail)=$dba->select_one('select id from person2 limit %start_pos,%count',{start_pos=>0,count=>1});
  #won't die, because we have do "$dba->once()" before it 
  if($err_code==0){
    print "no error, id is $re";
  }elsif($err_code==5){
    #execute error
    if($dba->err_code()==1146){
      print 'table not exist';
    }else{
    #other error
      CORE::die $err_detail;
    }
  }
  
  ($re,$err_code)=$dba->execute('insert into person values (?,?)',[3,'Bob']);
  #1, affected_rows
  ($re,$err_code)=$dba->select('select * from person');
  #[{id=>1,name=>'tom'},{id=>2,name=>'gates'}]
  ($re,$err_code)=$dba->select_array('select * from person');
  #[[1,'tom'],[2,'gates']]
  ($re,$err_code)=$dba->select_row('select * from person');
  #{id=>1,name=>'tom'}
  ($re,$err_code)=$dba->select_col('select id from person');
  #[1,2]
  ($re,$err_code)=$dba->select_one('select id from person');
  #1, first line first column
  
  ($re,$err_code)=$dba->select_one('select name from person where id=3');
  #select_row, select_one can cause NO_LINE error
  if($err_code==0){
    print "no error, name is $re";
  }elsif($err_code==1){
    #no line
    print "there is 0 row in result set";
  }else{
    print "other error";
  }
  
  
  $id=$dba->id('key1');#1
  $id=$dba->id('key2');#1
  $id=$dba->id('key1');#2
  $id=$dba->id('key1');#3
  
  $sid=$dba->sid();
  #446d40ffd9890184
  $sid_info=$dba->sid_info('446d40ffd9890184');
  #{"sid" => 3649634692, "comment" => undef, "record_time" => 1148010751}
  
  #will insert a record to note table
  $sid->note('hello world');

I<The synopsis above only lists the major methods and parameters.>

=head1 sample database

  use this table as sample table in document
  
  test_db.person

  +----+-------+
  | id | name  |
  +----+-------+
  |  1 | tom   |
  |  2 | gates |
  +----+-------+

=head1 globe option

you can edit begin part of code of this file(EasyDBAccess.pm) to set some globe option
you can also overload in runtime

  e.g EasyDBAccess::$_DEBUG=0;

=over 4

=item $_DEBUG

default is true

if you set $_DEBUG=false then no "DIE" (not recommend)

=item $_SETNAMES

do "SET NAMES" when dbi connected

default is true

if you set $_SETNAMES=false then not do "SET NAMES" when dbi connected

=item $_HIDE_CONN_PARAM

when "DIE", this module will throw out param infomation, this is dangerous when connect DB fail, 
		it may throw out user name as password

default is false

if you set $_HIDE_CONN_PARAM=false, then don't throw connection param infomarion

if you ser $_HIDE_CONN_PARAM=true,  then throw connection param infomarion if connect to DB fail (strongly not recommend)

=back

=head1 return value of function

return value can be in scalar mode and array mode
  
  #scalar mode
  $re=$dba->select_one('select 1'); #$re=1
  
  #array mode
  ($re,$err_code,$err_detail,$_pkg_name)=$dba->select_one('select 1'); 
  #$re=1,$err_code=0,$err_detail=undef,$_pkg_name=EasyDBAccess
  
  #if you don't need all result
  ($re,$err_code)=$dba->select_one('select 1');
  
Extra Rule: if $err_code!=0 then $re=undef
  
nearly all function use this design of return value

=head1 error handling

when you use this module, you  will cause some error, for example, db connect failed and some other error 

so in summary, there are 5 kind of runtime error (we don't discuss error cause by mistake usage of module)

=head2 DIE

some error will will triger "DIE"(we name it) to happen, and some will not

"DIE" is a action will do when error happen, the default behavior of "DIE" is I<CORE::die $err_detail>

and you can overload this behavior by set "die_handler" in "new" function

=head2 ERR_CODE

=over 4

=item NO_ERR 0 

$err_code=0 when there is no error

=item NO_LINE  1
 
when you assume there will be at least one line in result,
for example, when you call $dba->serlect_row or $dba->select_one, but there is no record in record set, then will cause NO_LINE error

=item PARAM_ERR 2
    
u have some error in param value, for example sql string is null

=item CONN_ERR 3

connect to db fail

=item PREPARE_ERR  4

prepare sql error, in fact, this error is impossible

=item EXEC_ERR 5

execute sql error

=back

we use var "$err_code" to store ERR_CODE

when error (2,3,5) happens , by default, module will triger "DIE", 
you need to use "once" function to temporary disable it if you want to handler it

other error (1) won't triger "DIE" ( refer to L<error handling & "DIE" & "once"> )

=head2 die_handler

you can overload "DIE" behavior by set "die_handler" in "new" function,

you can assign an instance of EasyHandler(recommend, but you need use EasyHandler Module), 

or an instance of _EasyDBAccess_EasyHandler(no need use extra module) to key "die_handler" in construct param

refer to L<error handling & "DIE" & "once"> 

=head1 parameter reference

  $dba->select($sql_str,$bind_param,$inline_param);
  
  e.g $dba->select('select * from person where id=?,name=? limit %start_pos,%count',[10,'qian'],{start_pos=>10,count=>20});


=over 4

=item $sql_str

sql string may contain some symbol like '?' and '%'
    
? will function with $bind_param
% will do string replace on string start with "%"


=item $bind_param

an array_ref

internal implement:

  $sth->execute(@$bind_param)

=item $inline_param

an hash_ref

internal implemnt:

  while(my($k,$v)=each %{$inline_param}){
    if(!defined($v)){return 0;}
    $_[0]=~s/\Q%$k\E/$v/g;
  }  

=back

=head1 basic function

=head2 foo - check whether this module is be used

  if(defined(&EasyDBAccess::foo)){
    print "lib is included";
  }else{
    print "lib is not included";
  }

=head2 new - new a instance

  $dba/($dba,$err_code)=EasyDBAccess->new($conn_param,$ext_option);
  $dba/($dba,$err_code)=EasyDBAccess->new($param);

B<$param = $conn_param + $ext_option>

$param= merge of $conn_param & $ext_option, sometimes you need to put param in separate hash_ref,so do this design

$param is a hash_ref has below option

  type: only support 'mysql' yet, default 'mysql'
  host: mysql server address, default'127.0.0.1'
  port: mysql server service port, default is 3306
  socket: use socket to connect mysql, set socket path to this
  usr : mysql user name, default 'root'
  pass: mysql auth password, default ''
  encoding: mysql charset (when mysql ver>=4.1), default 'UTF8', please check ther reference of 'SET NAMES'
  version:  mysql database version, default auto detect, if set, then please at least specify one digit after  '.', e.g. '3.23','4.1'
  database: default database, if not set, then no default database
      
the below option is to set what should do when error occur(default is CORE::die)
    
  die_handler: set a EasyHandler to this to handler error, will do this handler when 
  err_file: an internal die_handler, set file name to this, then will log into file when die

B<e.g>

  #normal use
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
    
  #use socket
  my $dba=EasyDBAccess->new({socket=>'/tmp/mysql.sock',usr=>'root',pass=>'passwd',database=>'test_db'});
    
  #use other encoding than utf8
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db',encoding=>'gbk'});
      
  #do something when connect fail
  EasyDBAccess->once();  #disable die in next operation 
  my ($dba,$err_code)=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
  if($err_code==3){
    print "Connect Error";
  }elsif($err_code==0){
    print "Connect Succ";
  }else{
    CORE::die 'BUG';
  }

  #write err log to file
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{err_file=>'\var\log\logfile'});

  #costomer die 
  my $die_handler=EasyHandler->new(\&die_to_file,['\var\log\logfile']);
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{die_handler=>$die_handler});

=head2 close - close database connection

  disconnect db 

  $dba->close();

=head2 dbh - get dbh

  get the dbh 
  
  my $dbh=$dba->dbh();

=head2 type - return database type

  return database type,always 'mysql' up to now
  
  print $dba->type();

=head2 once - disable DIE in next operation
    
  EasyDBAccess->once();
  $dba->once();

B<e.g>

  EasyDBAccess->once();  #disable die in next operation 
  my ($dba,$err_code)=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
  if($err_code==3){
    print "Connect Error";
  }elsif($err_code==0){
    print "Connect Succ";
  }else{
    CORE::die 'BUG';
  }
  
=head2 err_code err_str - return database error code and info of last db operator

  $dba->err_code();#1146,if no error, return undef
  $dba->err_str();
    
  $dba->once();
  ($rc,$err_code,$err_detail)=$dba->execute('insert into hello values(1,2,3)');
  if($err_code==5){#execute error
    if($dba->err_code()==1146){
      print 'table not exist';
      print $dba->err_str();
    }else{
      CORE::die $dba->err_str();
    }
  }

=head2 execute - execute command

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->execute($sql_str,$bind_param,$inline_param);

  return result of $dbh->do if succ, in most case ,this will be "affected rows"
  if execute error, $rc return undef

=head2 select - return result as array_ref of hash_ref

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->select($sql_str,$bind_param,$inline_param);
  
  return result as array_ref of hash_ref ([{id=>1,name=>'hello'},...]) 

=head2 select_array - return result as array_ref of array_ref

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->select_select_array($sql_str,$bind_param,$inline_param);

  return result as array_ref of array_ref ([[1,'hello'],...]) 

=head2 select_row - return first row of result set as hash

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->select_row($sql_str,$bind_param,$inline_param);
    
  return first row of result set as hash ({id=>1,name=>'hello'})
  if no row in result set, then $rc=undef, $err_code=1 but won't cause a die

=head2 select_col - return first column of result set as array_ref

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->select_row($sql_str,$bind_param,$inline_param);
  
  return first column of result set as array_ref( [1,2,3,...] )

=head2 select_one - return first row first column of result set scalar

  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->select_one($sql_str,$bind_param,$inline_param);

  return first row first column of result set scalar( 1 )
  if no row in result set, then $rc=undef, $err_code=1 but won't cause a die

=head1 additional function

=head2 batch_insert - insert many record into table at once

  insert many record into table at once
  
  $rc/($rc,$err_code,$err_detail,$_pkg_name)=$dba->batch_insert($sql_str,$values_tmpl,$values,$max_count);
    
  $max_count: max record insert per time, the default value for $max_count is 1
  return result of $dbh->do if succ, in most case ,this will be "affected rows"
  if execute error, $rc return undef

B<e.g>

  $dba->batch_insert('insert into person values %V','(?,?)',[[1,'tom'],[2,'gates'],[3,'bush']],100);

=head2 build_array - build data array

  build data array, always for insert

  ($ra,$err_code)/$ra = EasyDBAccess::build_array($filter,$rh,$ra);
  
  when you want to find a value from hash, but there is no such key in hash, then will use value undef instead, and will set $err_code=1

B<e.g>

  my $param={name=>'tom',age=>23,other_key=>'hello'};
  my $filter=[qw/? name age/];
  my $id=$dba->id('person');
  my $record=&EasyDBAccess::build_array($filter,$param,[$id]);
  $dba->execute('insert into person values (?,?,?)',$record);

=head2 build_update - build data for update

  build data for update, update some items on record

  ($str2,$ra_bind_param,$count,$str)/$str=EasyDBAccess::build_update($filter,$hash);

B<e.g>

  my $param={name=>'jack',other_key=>'hello'};
  my $filter=[qw/name age/];
  my ($str2,$ra_bind_param,$count,$str)=EasyDBAccess::build_update($filter,$param);  
  # $str2='name=?',$ra_bind_param=['jack'],$count=1,$str='name=?,'
  if($count>0){
    $dba->execute("update person set $str2 where id=?",[@$ra_bind_param,3]);
  }
      
  my $param={name=>'jack', age=>23, other_key=>'hello'};
  my $filter=[qw/name age/];
  my ($str2,$ra_bind_param,$count,$str)=EasyDBAccess::build_update($filter,$param);  
  # $str2='name=?,age=?',$ra_bind_param=['jack',23],$count=1,$str='name=?,age=?,'
  if($count>0){
    $dba->execute("update person set $strgender=1 where id=?",[@$ra_bind_param,3]);
  }
  
=head2 insert_one_row - execute command from binding data

  execute command from binding data, always for insert

  $rc/($rc,$err_code,$err_detail,$_pkg_name)==EasyDBAccess::insert_one_row($sql, $filter, $rh_data, $ra);
  
B<e.g>

  my $sql='insert into person values (?,?)';
  my $filter=[qw/name ?/];
  my $param={name=>'tom',age=>23,other_key=>'hello'};
  my $ra=[23]
  my $record=&EasyDBAccess::insert_one_row($sql,$filter,$record,$ra);
  
=head2 update - execute command from inline data

  execute command from binding data, always for update

  $rc/($rc,$err_code,$err_detail,$_pkg_name)==EasyDBAccess::update($sql, $filter, $rh_data, $ra_param);
  
B<e.g>

  my $sql='update person set %ITEM, SCORE=\'A\' where name=?';
  #my $sql='update person set %COMMAITEM SCORE=\'A\' where name=?';
  #COMMAITEM is ITEM with a comma
  my $filter=[qw/age/];
  my $rh_data={name=>'tom',age=>24};
  my $ra_param=['tom'];
  my $record=&EasyDBAccess::update($sql, $filter, $rh_data, $ra_param);

=head1 utility function

=head2 id - id generator

  to use this function, you must create table RES

    CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL ,PRIMARY KEY (ATTRIB))

  $id=$dba->id('key1');#1
  $id=$dba->id('key2');#1
  $id=$dba->id('key1');#2
  $id=$dba->id('key1');#3

=head2 sid - session id generator

  to use this function, you must create table SID
  
    CREATE TABLE SID(RECORD_TIME INT UNSIGNED NOT NULL, SID INT UNSIGNED NOT NULL,COMMENT VARCHAR(255) DEFAULT NULL,
    		PRIMARY KEY(RECORD_TIME,SID))

  $sid=$dba->sid();    #446d40ffd9890184
  $sid_info=$dba->sid_info('446d40ffd9890184'); #{"sid" => 3649634692, "comment" => undef, "record_time" => 1148010751}
  
  internal of sid:
      
  sid_string=hex(2^16*record_time+ ramdon_number)
    
  sid_string: return value of $dba->sid()
  record_time: record_time in $sid_info
  ramdon_number: sid in $sid_info

=head2 note - write some memo to table

  to use this function, you must create table NOTE

    CREATE TABLE NOTE(TEXT TEXT NOT NULL, RECORD_TIME INT UNSIGNED NOT NULL)

  $dba->note('something to note');

  you can read this note via database

=head1 example

=head2 error handling  DIE  once

B<this will make an CONN_ERR, it will triger "DIE">

  EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'wrong passwd',database=>'test_db'});

B<if you don't want to triger "DIE", you can use "once" to temporary disable it>

  EasyDBAccess->once();  #disable "DIE" in next operation 
  my ($dba,$err_code)=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});

B<another example to show usage of "once">

  $dba->once();
  $dba->select(undef);

B<if you want handler this error>

  EasyDBAccess->once();  #disable "DIE" in next operation 
  my ($dba,$err_code)=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'});
  if($err_code==3){
    print "Connect Error";
  }elsif($err_code==0){
    print "Connect Succ";
  }else{
    CORE::die 'BUG';
  }

B<this will make an PARAM_ERR, it will triger "DIE">

  $dba->select(undef);

B<this will make an EXEC_ERR, it will triger "DIE">

  $dba->execute('wrong sql');
  $dba->execute('insert into hello values(1,2,3)'); #table hello doesn't exist
  $dba->execute('insert into person values (1,'Buffett');#ER_DUP_ENTRY

B<this will make an NO_LINE, not all error will triger "DIE", NO_LINE won't triger "DIE">

  ($re,$err_code)=$dba->select_one('select name from person where id=3'); #select_row, select_one can cause NO_LINE error
  if($err_code==0){
    print "no error, name is $re";
  }elsif($err_code==1){#no line
    print "there is 0 row in result set";
  }else{
    print "other error";
  }

B<if you want handler error by database error code>

  $dba->once();
  ($rc,$err_code,$err_detail)=$dba->execute('insert into hello values(1,2,3)');
  if($err_code==5){#execute error
    if($dba->err_code()==1146){
      print 'table not exist';
    }else{
      CORE::die $err_detail;#other error
    }
  }

B<customize die_handler>

  sub die_to_file{
    my $file_path= shift;
    my ($err_pkg,$err_code,$err_detail,$record_time)=(undef,undef,undef,CORE::time);
    my $param_count=scalar(@_);
    if($param_count==1){
      ($err_detail)=@_;
    }elsif($param_count==3){
      ($err_code,$err_detail,$err_pkg)=@_;
    }elsif($param_count==4){
      ($err_code,$err_detail,$err_pkg,$record_time)=@_;
    }else{
      CORE::die($_pkg_name.'::die_to_file: param error');
    }
  
    $_=[localtime($record_time)];
    my $prefix="#####".sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0])."\n";
  
    my $result=append_file($file_path,$prefix.$err_detail."\n");
    if($result){
      #log succ
      CORE::die $err_detail;
    }else{
      CORE::die($_pkg_name.'::die_to_file: append to file failed');
    }
  }

  my $die_handler=EasyHandler->new(\&die_to_file,['\var\log\logfile']);
  #my $die_handler=_EasyDBAccess_EasyHandler->new(\&die_to_file,['\var\log\logfile']);#this one is OK, too
  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{die_handler=>$die_handler});

B<system integrated an alternative die_handler beside "CORE::die", this die_handler called "die_to_file", it write $err_detail to log_file before "CORE::die">

B<sample code show how to use it>

  my $dba=EasyDBAccess->new({host=>'127.0.0.1',usr=>'root',pass=>'passwd',database=>'test_db'},{err_file=>'\var\log\logfile'});


=head1 COPYRIGHT

The EasyDBAccess module is Copyright (c) 2003-2005 QIAN YU.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

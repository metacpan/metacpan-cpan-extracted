package EasyMail;
use strict;
use warnings(FATAL=>'all');

our $VERSION = '2.5.2';

#===================================
#===Module  : 43f01b295f6fcfca
#===Version : 43f01b600bc33f65
#===================================

#===================================
#===Module  : Framework::EasyMail
#===File    : lib/Framework/EasyMail.pm
#===Comment : a lib to send email
#===Require : File::Basename MIME::Base64 FileHandle IO::Socket::INET Time::Local Encode
#===================================

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 9097939            ===
#===Homepage: www.fishlib.cn     ===
#===================================

#=======================================
#===Author  : huang.shuai            ===
#===Email   : huang.shuai@adways.net ===
#===MSN     : huang.shuai@adways.net ===
#=======================================

#BUG
# * Return-Path is not function in sendmail daemon(not qmail daemon), for further help contact author

#Future Request:

#===2.5.2(2008-12-08): fix bug "http://rt.cpan.org/Ticket/Display.html?id=34032",thanks to "Ursetti, Jerry" find this bug 
#===2.5.1(2008-07-16): fix bug when traslate charset from utf8 to iso-2022-jp
#        (2008-05-08): fix bug on dst = 'un'
#===2.5.0(2008-03-12): add DIRECT send type,if you use DIRECT module "Net::DNS" is required
#===2.4.4(2007-10-10): modify X-Mailer, remove Thread-Index and X-MimeOLE, fix BCC bug
#===2.4.3(2006-08-28): fix parse mail list bugs
#===2.4.2(2006-08-17): fix filter bugs
#===2.4.1(2006-08-01): add email filter
#===2.4.0(2006-07-31): document format
#===2.3.0(2005-08-18): smtp support, non-ascii attachment file name support
#===2.0.1(2005-08-12): modified _sendmail, die if sendmail_path not valid 
#===2.0.0(2005-08-12): second version release, Simplify the first version, and add some function

use File::Basename;
use MIME::Base64;
use FileHandle;
use IO::Socket::INET;
use Time::Local;
use Encode;

sub foo{1};
sub _name_pkg_name{'EasyMail'}
sub _name_true{1;}
sub _name_false{'';}

my $_max_file_len = 100000000;

my $_all_ascii=&_name_true;

#===$str=trim($str)
#===delete blank before and after $str, return undef if $str is undef
sub trim($) {
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_=$_[0];
		unless(defined($_)){return undef;}
		s/^\s+//,s/\s+$//;
		return $_ ;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'trim: param count should be 1');
	}
}

#===$flag=is_email($id)
#===check whether a valid email address
sub is_email($){
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_=$_[0];
		if(!defined($_)){
			return defined(&_name_false)?&_name_false:'';
		}elsif(/^[a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/){
			return defined(&_name_true)?&_name_true:1;
		}else{
			return defined(&_name_false)?&_name_false:'';
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_email: param count should be 1');
	}
}

#===generate a unique mime_boundary string
sub gen_mime_boundary($){
	'------------06010007000403080202'.(shift);
}

#===guess file content type from it's name
sub guess_file_content_type($){
	my($filename)=@_;
	if(!defined($filename)){return undef;}
	my $map={
		'au' 	=> 'audio/basic',
		'avi'	=> 'video/x-msvideo',
		'class'	=> 'application/octet-stream',
		'cpt'	=> 'application/mac-compactpro',
		'dcr'	=> 'application/x-director',
		'dir'	=> 'application/x-director',
		'doc'	=> 'application/msword',
		'exe'	=> 'application/octet-stream',
		'gif'	=> 'image/gif',
		'gtx'	=> 'application/x-gentrix',
		'jpeg'	=> 'image/jpeg',
		'jpg'	=> 'image/jpeg',
		'js'	=> 'application/x-javascript',
		'hqx'	=> 'application/mac-binhex40',
		'htm'	=> 'text/html',
		'html'	=> 'text/html',
		'mid'	=> 'audio/midi',
		'midi'	=> 'audio/midi',
		'mov'	=> 'video/quicktime',
		'mp2'	=> 'audio/mpeg',
		'mp3'	=> 'audio/mpeg',
		'mpeg'	=> 'video/mpeg',
		'mpg'	=> 'video/mpeg',
		'pdf'	=> 'application/pdf',
		'pm'	=> 'text/plain',
		'pl'	=> 'text/plain',
		'ppt'	=> 'application/powerpoint',
		'ps'	=> 'application/postscript',
		'qt'	=> 'video/quicktime',
		'ram'	=> 'audio/x-pn-realaudio',
		'rtf'	=> 'application/rtf',
		'tar'	=> 'application/x-tar',
		'tif'	=> 'image/tiff',
		'tiff'	=> 'image/tiff',
		'txt'	=> 'text/plain',
		'wav'	=> 'audio/x-wav',
		'xbm'	=> 'image/x-xbitmap',
		'zip'	=> 'application/zip'
	};
	my ($base,$path,$type) = File::Basename::fileparse($filename,qr{\..*});
	if($type){$type=lc(substr($type,1))};
	$map->{$type} or 'application/octet-stream';
}

#===use base64 to encode header
sub _encode_b($$){
	my($str,$encoding)=@_;
	'=?'.$encoding.'?B?'.MIME::Base64::encode_base64($str,'').'?=';
}

#===cut the str into specified length
sub _my_chunk_split($$$){
	my ($str,$line_delimiter,$line_len)=@_;
	my $len=length($str);
	my $out='';
	while ($len>0){
		if ($len>=$line_len){
			$out.=substr($str,0,$line_len).$line_delimiter;
			$str=substr($str,$line_len);
			$len=$len-$line_len;
		}else{
			$out.=$str.$line_delimiter;
			$str='';
			$len=0;
		}
	}
	$out;
}

sub change_encoding($$$){
	if(defined(&utf8::is_utf8)&&utf8::is_utf8($_[0])){
		return Encode::encode($_[2],$_[0]);
	}elsif($_[0]=~/^[\040-\176\r\t\n]*$/){
		#no need to do anything if all ascii
		return $_[0];
	}elsif(defined($_[1])&&defined($_[2])&&($_[1] eq $_[2])){
		#no need to do anything if $src_encoding=$dst_encoding
		return $_[0];
	}elsif(defined($_[1])&&defined($_[2])&&($_[1] ne $_[2])){
        if ($_[1] eq 'utf8' and $_[2] eq 'iso-2022-jp') {
            eval {
                require Unicode::Japanese;
            };
            if ($@) {
                return Encode::encode($_[2],Encode::decode($_[1],$_[0]));
            } else {
                return Unicode::Japanese->new($_[0])->jis;
            }
        } else {
            return Encode::encode($_[2],Encode::decode($_[1],$_[0]));
        }
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: you must set src_encoding');
	}
}

#===encoder header
sub encode_header($$$$){
	my ($str,$src_encoding,$dst_encoding,$dst_encoding_txt)=@_;
	#change encoding
	$str=change_encoding($str,$src_encoding,$dst_encoding);
	if($str=~/^[\040-\176]*$/){
		#if all ascii, no need to encode
	}else{
		$str=_encode_b($str,$dst_encoding_txt);
		$_all_ascii=&_name_false;
	}
	$str;
}

#===gen header
sub gen_header($$$){
	my ($key,$value,$line_delimiter)=@_;
	return defined($value)?$key.': '.$value.$line_delimiter:'';
}

#===gen "Bill Gates" <gates@hotmail.com>
sub gen_email_name_pair($$$$$){
	my ($email,$name,$src_encoding,$dst_encoding,$dst_encoding_txt)=@_;
	if(!is_email($email)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: not a valid email address');
	}
	#if no from_name ,just return it
	if(!defined($name)){return ($email,$email);}
	#change encoding
	$name=encode_header($name,$src_encoding,$dst_encoding,$dst_encoding_txt);
	$name=~s/([\\\"])/\\$1/g;
	return ("\"$name\" <$email>",$email);
}

sub parse_email_name_pair($){
	my ($email_name_pair)=@_;
	my ($email,$name);
	my $type=ref $email_name_pair;
	if(($type eq '')&&(defined($email_name_pair))){
		local $_=$email_name_pair;
		s/^\s+//,s/\s+$//;
		if(/^[a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/){
			return ($_,undef);
		}elsif(/^([^\s](.*[^\s])?)[\s]+([a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})$/){
			return ($3,$1);
		}elsif(/^([a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})[\s]+([^\s](.*[^\s])?)$/){
			return ($1,$4);
		}elsif(/^[\"](.*)[\"][\s]*[\<][\s]*([a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})[\s]*[\>]$/){
			return ($2,$1);
		}elsif(/^([^\s](.*[^\s])?)[\s]*[\<][\s]*([a-zA-Z0-9\_\.\-]+\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})[\s]*[\>]$/){
			return ($3,$1);
		}else{
			return (undef,undef);		
		}
	}elsif($type eq 'ARRAY'){
		if((ref($email_name_pair->[0]) eq '')&& (ref($email_name_pair->[1]) eq '')){
			my ($A,$B)=(trim($email_name_pair->[0]),trim($email_name_pair->[1]));
			if(is_email($A)){
				if(defined($B) &&($B eq '')){$B =undef;}
				return ($A,$B);
			}elsif(is_email($B)){
				if(defined($A) &&($A eq '')){$A =undef;}
				return ($B,$A);
			}else{
				return (undef,undef);
			}
		}else{
			return (undef,undef);
		}
	}elsif($type eq 'HASH'){
		if((ref($email_name_pair->{email}) eq '')&& (ref($email_name_pair->{name}) eq '')){
			my ($A,$B)=(trim($email_name_pair->{email}),trim($email_name_pair->{name}));
			if(is_email($A)){
				if(defined($B) &&($B eq '')){$B =undef;}
				return ($A,$B);
			}else{
				return (undef,undef);
			}
		}else{
			return (undef,undef);
		}
	}else{
		return (undef,undef)
	}
}

sub gen_email_name_pair_list($$$$){
	my ($email_list,$src_encoding,$dst_encoding,$dst_encoding_txt)=@_;
	if(!defined($email_list)){return (undef,[]);}
	if((ref $email_list eq '')||(ref $email_list eq 'HASH')){
		my ($email,$name)=parse_email_name_pair($email_list);
		my ($_str,$_email)=gen_email_name_pair($email,$name,$src_encoding,$dst_encoding,$dst_encoding_txt);
		return ($_str,[$_email]);
	}elsif(ref $email_list eq 'ARRAY'){
		if(scalar(@$email_list)==2){
			my ($A,$B)=(trim($email_list->[0]),trim($email_list->[1]));
			#if $email_list= [$email,$email] then parse it as two email address
			if(((is_email($A))&&(!is_email($B)))||((!is_email($A))&&(is_email($B)))){
				my ($email,$name)=parse_email_name_pair($email_list);
				my ($_str,$_email)=gen_email_name_pair($email,$name,$src_encoding,$dst_encoding,$dst_encoding_txt);
				return ($_str,[$_email]);
			}
		}
	}else{
		#continue
	}
	if(scalar(@$email_list)==0){return (undef,[]);}
	my ($str,$ra_email)=('',[]);
	foreach (@$email_list) {
		my ($email,$name)=parse_email_name_pair($_);
		my ($_str,$_email)=gen_email_name_pair($email,$name,$src_encoding,$dst_encoding,$dst_encoding_txt);
		$str.="$_str,";
		push @$ra_email,$_email;
	}
	chop($str);
	return ($str,$ra_email);
}

#===used by gen_date
my $_short_month_name=
	['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
my $_short_day_name=
	['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
my $_time_zone_name_2=
	['-1200','-1100','-1000','-0900','-0800','-0700','-0600','-0500','-0400','-0300','-0200','-0100','+0000','+0100','+0200','+0300','+0400','+0500','+0600','+0700','+0800','+0900','+1000','+1100','+1200','+1300'];
sub gen_date(){
	my @now = localtime(time);
	my $sec = $now[0];
	my $min = $now[1];
	my $hr = $now[2];
	my $day = $now[3];
	my $mon = $now[4];
	my $yr = $now[5] + 1900;
	my $gm = Time::Local::timegm($sec,$min,$hr,$day,$mon,$yr);
	my $local = Time::Local::timelocal($sec,$min,$hr,$day,$mon,$yr);
	my $tz = int (($gm-$local)/3600);
	my $t=[localtime(CORE::time())];
	return sprintf('%03s, %02s %03s %04s %02s:%02s:%02s %05s',$_short_day_name->[$t->[6]],$t->[3],$_short_month_name->[$t->[4]],$t->[5]+1900,$t->[2],$t->[1],$t->[0],$_time_zone_name_2->[$tz+12]);
}

#=========================================

#===
sub gen_part_file($$$$$){
	my ($file,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter)=@_;
	my $str='';

	$str.="Content-Type: $file->{content_type};".$line_delimiter;
	my $file_name_str;
	if(defined($file->{file_name})){
		$file_name_str=encode_header($file->{file_name},$src_encoding,$dst_encoding,$dst_encoding_txt);
		$str.=" name=\"$file_name_str\"".$line_delimiter;
	}
	$str.="Content-Transfer-Encoding: base64".$line_delimiter;

	if(defined($file->{content_id})){
		$str.="Content-ID: <$file->{content_id}>".$line_delimiter;
	}

	$str.="Content-Disposition: $file->{content_disposion};".$line_delimiter;
	if(defined($file->{file_name})){
		$str.=" filename=\"$file_name_str\"".$line_delimiter;
	}

	$str.=$line_delimiter;
	$str.=_my_chunk_split(MIME::Base64::encode_base64($file->{file_bin},''),$line_delimiter,72);
	$str.=$line_delimiter;

	return $str;
}

sub parse_part_text($$$$$$){
	my ($type,$text,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter)=@_;
	$text=trim($text);
	if(!defined($text)){$text='';}
	#change encoding
	$text=change_encoding($text,$src_encoding,$dst_encoding);
	
	my $header_transfer_encoding;
	if($text=~/^[\000-\177]*$/){
		$header_transfer_encoding=gen_header('Content-Transfer-Encoding','7bit',$line_delimiter);
	}else{
		$header_transfer_encoding=gen_header('Content-Transfer-Encoding','8bit',$line_delimiter);
	}	
	
	my $header_content_type;
	if(($_all_ascii)&&($text=~/^[\040-\176\r\t\n]*$/)){
		#all ascii
	}else{
		$_all_ascii=&_name_false;
	}

	if($type eq 'html'){
		my $encoding=$_all_ascii?'us-ascii':$dst_encoding_txt;
		$header_content_type=gen_header('Content-Type',"text/html; charset=$encoding;",$line_delimiter);
	}elsif($type eq 'plain'){
		my $encoding=$_all_ascii?'us-ascii':$dst_encoding_txt;
		$header_content_type=gen_header('Content-Type',"text/plain; charset=$encoding;",$line_delimiter);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: BUG please report it:unknow type');
	}
	
	$text=~s/\r\n/\n/g;
	$text=~s/\r/\n/g;
	$text=~s/\n/$line_delimiter/g;
	$text.=$line_delimiter;
	$text.=$line_delimiter;
	return ($header_transfer_encoding,$header_content_type,$text);
}

sub sendmail($){
	my ($param)=@_;

	#===get sender & config	
	my $sender=EasyMail::Sender::get_sender($param);
	my $config=EasyMail::Sender::parse_sender($sender);
	
	my $line_delimiter=$config->{line_delimiter};
	my $hide_bcc_flag =$config->{hide_bcc};
	#======================
	
	#======================
	my $from_email;
	my $ra_to;
	my $ra_cc;
	my $ra_bcc;
	#======================

	#===temp variable
	my $str;
	#======================

	my $_mime_boundary= 100000;

	$_all_ascii=&_name_true;

	#===analyse attachment
	my $mixed_files=[];
	my $related_files=[];
	if(defined($param->{files})){
		foreach my $file(@{$param->{files}}){
			my ($f,$flag)=_process_file($file);
			if($flag==0){
				push @$mixed_files,$f;
			}elsif($flag==1){
				push @$related_files,$f;
			}
		}
	}

	my $src_encoding=$param->{src_encoding};
	#if all param is unicode ,may be no need to set src encoding

	my $dst=$param->{dst};
	if(!defined($dst)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: dst must be set in (un,jp,cn)');
	}

	my ($dst_encoding,$dst_encoding_txt);
	if($dst eq 'un'){
		$dst_encoding='utf8';$dst_encoding_txt='utf-8';
	}elsif($dst eq 'cn'){
		$dst_encoding='gbk';$dst_encoding_txt='gb2312';
	}elsif($dst eq 'jp'){
		$dst_encoding='iso-2022-jp';$dst_encoding_txt=$dst_encoding;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: dst must be set in (un,jp,cn)');
	}

	my $mail='';
	#Return-Path
	$mail.=gen_header('Return-Path',$param->{return_path},$line_delimiter);
	my ($email,$name)=parse_email_name_pair($param->{from});
	if(!defined($email)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: must spcify from email');
	}
	#From
	($str,$from_email)=gen_email_name_pair($email,$name,$src_encoding,$dst_encoding,$dst_encoding_txt);
	$mail.=gen_header('From',$str,$line_delimiter);
	if (defined($param->{mail_filter})){
			if (ref $param->{mail_filter} eq 'ARRAY'){
					$param->{to} = _filter_mail($param->{mail_filter}, $param->{to});
					$param->{cc} = _filter_mail($param->{mail_filter}, $param->{cc});
					$param->{bcc} = _filter_mail($param->{mail_filter}, $param->{bcc});
			}
	}

	($str,$ra_to)=gen_email_name_pair_list($param->{to},$src_encoding,$dst_encoding,$dst_encoding_txt);
	#To&CC
	$mail.=gen_header('To',$str,$line_delimiter);
	($str,$ra_cc)=gen_email_name_pair_list($param->{cc},$src_encoding,$dst_encoding,$dst_encoding_txt);
	$mail.=gen_header('CC',$str,$line_delimiter);
	if ((scalar(@$ra_to)==0) && (scalar(@$ra_cc)==0) ){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: to and cc must contains more than one valid email');
	}
	
	#BCC
	($str,$ra_bcc)=gen_email_name_pair_list($param->{bcc},$src_encoding,$dst_encoding,$dst_encoding_txt);
	if(!$hide_bcc_flag){$mail.=gen_header('BCC',$str,$line_delimiter);} 
	
	#Subject
	my $subject=$param->{subject};
	if(!defined($subject)){$subject='No Subject';}
	$mail.=gen_header('Subject',encode_header($subject,$src_encoding,$dst_encoding,$dst_encoding_txt),$line_delimiter);
	#Date
	$mail.=gen_header('Date',gen_date(),$line_delimiter);
	#MIME-Version
	$mail.=gen_header('MIME-Version','1.0',$line_delimiter);

	my $type;
	if(!defined($param->{type})){
		$type='plain';
	}elsif($param->{type} eq 'html'){
		$type='html';
	}elsif(($param->{type} eq 'plain')||($param->{type} eq 'text')||($param->{type} eq 'txt')){
		$type='plain';
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: please set type in (plain,html)');
	}

	my $text=$param->{body};
	if(!defined($text)){$text='';}
	
	my ($text_header_transfer_encoding,$text_header_content_type,$text_body)=parse_part_text($type,$text,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter);

	my $body;
	my ($header_transfer_encoding,$header_content_type);
	
	if(scalar(@$mixed_files)>=1){
		my $mime_boundary=gen_mime_boundary($_mime_boundary++);
		$header_content_type=gen_header('Content-Type','multipart/mixed;'.$line_delimiter.' boundary="'.$mime_boundary.'"',$line_delimiter);
		$header_transfer_encoding='';
		$body="This is a multi-part message in MIME format".$line_delimiter.$line_delimiter;
		$body.="--".$mime_boundary.$line_delimiter;
		if(scalar(@$related_files)>=1){
			my $mime_boundary=gen_mime_boundary($_mime_boundary++);
			$body.=gen_header('Content-Type','multipart/related;'.$line_delimiter.' boundary="'.$mime_boundary.'"',$line_delimiter);
			$body.=$line_delimiter;
			$body.="--".$mime_boundary.$line_delimiter;
			$body.=$text_header_content_type;
			$body.=$text_header_transfer_encoding;
			$body.=$line_delimiter;
			$body.=$text_body;
			foreach(@$related_files){
				$body.="--".$mime_boundary.$line_delimiter;
				$body.=gen_part_file($_,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter);
			}
			$body.="--".$mime_boundary."--".$line_delimiter.$line_delimiter;
		}else{
			$body.=$text_header_content_type;
			$body.=$text_header_transfer_encoding;
			$body.=$line_delimiter;
			$body.=$text_body;
		}
		foreach(@$mixed_files){
			$body.="--".$mime_boundary.$line_delimiter;
			$body.=gen_part_file($_,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter);
		}
		$body.="--".$mime_boundary."--".$line_delimiter;
	}elsif(scalar(@$related_files)>=1){
		my $mime_boundary=gen_mime_boundary($_mime_boundary++);
		$header_content_type=gen_header('Content-Type','multipart/related;'.$line_delimiter.' boundary="'.$mime_boundary.'"',$line_delimiter);
		$header_transfer_encoding='';
		$body="This is a multi-part message in MIME format".$line_delimiter.$line_delimiter;
		$body.="--".$mime_boundary.$line_delimiter;
		$body.=$text_header_content_type;
		$body.=$text_header_transfer_encoding;
		$body.=$line_delimiter;
		$body.=$text_body;
		foreach(@$related_files){
			$body.="--".$mime_boundary.$line_delimiter;
			$body.=gen_part_file($_,$src_encoding,$dst_encoding,$dst_encoding_txt,$line_delimiter);
		}
		$body.="--".$mime_boundary."--".$line_delimiter;
	}else{
		$header_content_type=$text_header_content_type;
		$header_transfer_encoding=$text_header_transfer_encoding;
		$body.=$line_delimiter;
		$body=$text_body;
	}
	#Content-Type
	$mail.=$header_content_type;
	#Transfer-Encoding
	$mail.=$header_transfer_encoding;
	#Other
	$mail.=gen_header('X-Mailer',_name_pkg_name(),$line_delimiter);
	$mail.=$line_delimiter;
	
	#Body
	$mail.=$body;
	
	my $m=EasyMail::Sender::get_mail($sender,$mail,$from_email,$ra_to,$ra_cc,$ra_bcc);
	EasyMail::Sender::sendmail($m);
}

sub _filter_mail($$){
		my ($ra_filter, $email_list) = @_;
		my $ra_filter_str = [];
		foreach(@$ra_filter){
				if (! /^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/){
						next;
				}
				push @$ra_filter_str, '@'.$_;
		}
		
		if((ref $email_list eq '')||(ref $email_list eq 'HASH')){
				my ($email,$name)=parse_email_name_pair($email_list);
				return undef if (!defined($email)); #==2.4.2==
				foreach (@$ra_filter_str){
						if (index($email, $_) != -1){return $email_list;}
				}
				return undef;
		}elsif(ref $email_list eq 'ARRAY'){
				if(scalar(@$email_list)==2){
						my ($A,$B)=(trim($email_list->[0]),trim($email_list->[1]));
						if(((is_email($A))&&(!is_email($B)))||((!is_email($A))&&(is_email($B)))){
								my ($email,$name)=parse_email_name_pair($email_list);
								foreach (@$ra_filter_str){
										if (index($email, $_) != -1){return $email_list;}
								}
								return undef;
						}
				}elsif(scalar(@$email_list)==0){return $email_list;}
		}else{
				return $email_list;
		}
		my $filter_email_list = [];
		foreach (@$email_list) {
				my $remain = 0;
				my ($email,$name)=parse_email_name_pair($_);
				foreach (@$ra_filter_str){
						if (index($email, $_) != -1){
								$remain = 1;
								last;
						}
				}
				if ($remain){
					push @$filter_email_list, $_;
				}
		}
		
		return $filter_email_list;
}

#please use simple char in file_path and file_name
sub _process_file($){
	my ($file)=@_;
	my $attachment={};
	if(defined($file->{file_bin})&&defined($file->{file_path})){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_process_file: file_bin and file_path can only set one');
	}elsif(defined($file->{file_path})){
		my $fh=FileHandle->new($file->{file_path},'r');
		if(!defined($fh)){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_process_file: open attach file failed');
		}
		my $buf;
		$fh->read($buf,$_max_file_len);
		$fh->close();
		$attachment->{file_bin}=$buf;
		undef $buf;
		if(defined($file->{file_name})){
			$attachment->{file_name}=trim($file->{file_name});
		}else{
			$attachment->{file_name}=File::Basename::basename(trim($file->{file_path}));
		}
	}elsif(defined($file->{file_bin})){
		$attachment->{file_bin}=$file->{file_bin};
		$attachment->{file_name}=trim($file->{file_name});
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_process_file: file_bin and file_path must set one');
	}

	#===if u don't set file_name please set content_type
	if(defined($file->{content_type})){
		$attachment->{content_type}=$file->{content_type};
	}elsif(defined($attachment->{file_name})){
		$attachment->{content_type}=guess_file_content_type($attachment->{file_name});
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_process_file: if u don\'t set file_name please set content_type');
	}

	if(defined($file->{content_id})){
		$attachment->{content_id}=$file->{content_id};
		$attachment->{content_disposion}='inline';
		delete $attachment->{file_name};
	}else{
		$attachment->{content_disposion}='attachment';
		#===attachment must have a file name
		if(!defined($attachment->{file_name})){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_process_file: please set file_name');
		}
	}
	return ($attachment,$attachment->{content_id}?1:0);
}

1;

package EasyMail::Sender;
use strict;
use warnings(FATAL=>'all');

sub foo{1};
sub _name_pkg_name{'EasyMail::Sender'}
sub _name_true{1;}
sub _name_false{'';}

#mail option
#SENDMAIL
#	sendmail_path
#	sendmail_use_close
#	sendmail_mail
#SMTPAUTHLOGIN | SMTPAUTHPLAIN | SMTPAUTHNONE
#	smtp_host
#	smtp_port
#	print_msg
#	smtp_mail
#	from
#	ra_to
#	ra_cc
#	ra_bcc
#	smtp_usr (SMTPAUTHLOGIN | SMTPAUTHPLAIN)
#	smtp_pass(SMTPAUTHLOGIN | SMTPAUTHPLAIN)
#
#DIRECT
#   

sub sendmail($){
	my $param_count=scalar(@_);
	if($param_count==1){
		if($_[0]->{type} eq 'SMTPAUTHLOGIN'){
			_smtp_AUTH_LOGIN($_[0]);
		}elsif($_[0]->{type} eq 'SMTPAUTHPLAIN'){
			_smtp_AUTH_PLAIN($_[0]);
		}elsif($_[0]->{type} eq 'SMTPAUTHNONE'){
			_smtp_AUTH_NONE($_[0]);
		}elsif($_[0]->{type} eq 'SENDMAIL'){
			_sendmail($_[0]);
		}elsif($_[0]->{type} eq 'DIRECT'){
			_direct_send($_[0]);
		}else{
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: unknow sender type ');
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: param count should be 1');
	}
}

sub get_sender($){
	my $param_count=scalar(@_);
	if($param_count==1){
		my $sender={};
		my $type=$_[0]->{sender_type};
		if(!defined($type)){$type='SENDMAIL';}
		if($type eq 'SENDMAIL'){
			$sender->{type}='SENDMAIL';
			$sender->{sendmail_path}=defined($_[0]->{sendmail_path})?$_[0]->{sendmail_path}:'sendmail';
			$sender->{sendmail_use_close}=((!defined($_[0]->{sendmail_use_close}))||($_[0]->{sendmail_use_close}))?&_name_true:&_name_false;
			return $sender;
		}elsif($type eq 'SMTPAUTHLOGIN'){
			$sender->{type}='SMTPAUTHLOGIN';
			$sender->{smtp_host}=defined($_[0]->{smtp_host})?$_[0]->{smtp_host}:'127.0.0.1';
			$sender->{smtp_port}=defined($_[0]->{smtp_port})?$_[0]->{smtp_port}:25;
			$sender->{print_msg}=(defined($_[0]->{print_msg})&&$_[0]->{print_msg})?&_name_true:&_name_false;
			$sender->{smtp_usr}=$_[0]->{smtp_usr};
			if(!defined($sender->{smtp_usr})){
				CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: smtp_usr must set');
			}
			$sender->{smtp_pass}=$_[0]->{smtp_pass};
			if(!defined($sender->{smtp_pass})){
				CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: smtp_pass must set');
			}
			return $sender;
		}elsif($type eq 'SMTPAUTHPLAIN'){
			$sender->{type}='SMTPAUTHPLAIN';
			$sender->{smtp_host}=defined($_[0]->{smtp_host})?$_[0]->{smtp_host}:'127.0.0.1';
			$sender->{smtp_port}=defined($_[0]->{smtp_port})?$_[0]->{smtp_port}:25;
			$sender->{print_msg}=(defined($_[0]->{print_msg})&&$_[0]->{print_msg})?&_name_true:&_name_false;
			$sender->{smtp_usr}=$_[0]->{smtp_usr};
			if(!defined($sender->{smtp_usr})){
				CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: smtp_usr must set');
			}
			$sender->{smtp_pass}=$_[0]->{smtp_pass};
			if(!defined($sender->{smtp_pass})){
				CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: smtp_pass must set');
			}
			return $sender;
		}elsif($type eq 'SMTPAUTHNONE'){
			$sender->{type}='SMTPAUTHNONE';
			$sender->{smtp_host}=defined($_[0]->{smtp_host})?$_[0]->{smtp_host}:'127.0.0.1';
			$sender->{smtp_port}=defined($_[0]->{smtp_port})?$_[0]->{smtp_port}:25;
			$sender->{print_msg}=(defined($_[0]->{print_msg})&&$_[0]->{print_msg})?&_name_true:&_name_false;
			return $sender;
		}elsif($type eq 'DIRECT'){
			$sender->{type}='DIRECT';
			#$sender->{smtp_host}=defined($_[0]->{smtp_host})?$_[0]->{smtp_host}:'127.0.0.1';
			#$sender->{smtp_port}=defined($_[0]->{smtp_port})?$_[0]->{smtp_port}:25;
			$sender->{print_msg}=(defined($_[0]->{print_msg})&&$_[0]->{print_msg})?&_name_true:&_name_false;
			return $sender;
		}else{
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: unknow sender type');
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: param count should be 1');
	}
}

sub get_mail($$$$$$){
	my $param_count=scalar(@_);
	if($param_count==6){
		my $type=$_[0]->{type};
		if($type eq 'SENDMAIL'){
			$_[0]->{sendmail_mail}=$_[1];
			return $_[0];
		}elsif($type eq 'SMTPAUTHLOGIN'){
			$_[0]->{smtp_mail}=$_[1];
			$_[0]->{from}=$_[2];
			$_[0]->{ra_to}=$_[3];
			$_[0]->{ra_cc}=$_[4];
			$_[0]->{ra_bcc}=$_[5];
			return $_[0];
		}elsif($type eq 'SMTPAUTHPLAIN'){
			$_[0]->{smtp_mail}=$_[1];
			$_[0]->{from}=$_[2];
			$_[0]->{ra_to}=$_[3];
			$_[0]->{ra_cc}=$_[4];
			$_[0]->{ra_bcc}=$_[5];
			return $_[0];
		}elsif($type eq 'SMTPAUTHNONE'){
			$_[0]->{smtp_mail}=$_[1];
			$_[0]->{from}=$_[2];
			$_[0]->{ra_to}=$_[3];
			$_[0]->{ra_cc}=$_[4];
			$_[0]->{ra_bcc}=$_[5];
			return $_[0];
		}elsif($type eq 'DIRECT'){
			$_[0]->{smtp_mail}=$_[1];
			$_[0]->{from}=$_[2];
			$_[0]->{ra_to}=$_[3];
			$_[0]->{ra_cc}=$_[4];
			$_[0]->{ra_bcc}=$_[5];
			return $_[0];
		}else{
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: unknow sender type');
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: param count should be 6');
	}
}

sub parse_sender($){
	my $type=$_[0]->{type};
	if(!defined($type)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: unknow sender type');
	}elsif($type eq 'SENDMAIL'){
		return {line_delimiter=>"\n",hide_bcc=>&_name_false}; 
	}elsif(($type eq 'SMTPAUTHLOGIN')||($type eq 'SMTPAUTHPLAIN')||($type eq 'SMTPAUTHNONE')||($type eq 'DIRECT') ){
		return {line_delimiter=>"\r\n",hide_bcc=>&_name_true}; 
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: unknow sender type');
	}
}

sub _direct_send {
    my ($mail) = @_;
    my $email = $mail->{'ra_to'}->[0];
    if ($email =~ /^[a-zA-Z0-9\_\.\-]+\@((?:[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6})$/){
        my $address = lc($1);
        require Net::DNS;
        my @mx = Net::DNS::mx($address);
        if (scalar(@mx)==0){
            CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: cannot parse mx record!');
        } else {
            $mail->{'ra_to'} = [$email];
            $mail->{'sender_type'} = 'SMTPAUTHNONE';
            $mail->{'smtp_host'} = $mx[0]->exchange;
	    $mail->{smtp_port}=25;
            _smtp_AUTH_NONE($mail);
            return;
        }
    }else{
	CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: BUG!');
    }
}

sub _smtp_AUTH_LOGIN($){
	my ($mail)=@_;
	my $smtp_host=defined($mail->{smtp_host})?$mail->{smtp_host}:'localhost';
	my $smtp_port=defined($mail->{smtp_port})?$mail->{smtp_port}:25;
	my $print_msg=defined($mail->{print_msg})?$mail->{print_msg}:0;
	my $sock=new IO::Socket::INET->new(PeerPort=>$smtp_port,Proto=>'tcp',PeerAddr=>$smtp_host);
	if(!defined($sock)){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: cannot connect to smtp server!');}
	
	_server_parse($sock, "220",$print_msg,__LINE__);
	_server_send($sock,"EHLO $mail->{smtp_host}\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"AUTH LOGIN\r\n",$print_msg,__LINE__);
	_server_parse($sock, "334",$print_msg,__LINE__);
	_server_send($sock,MIME::Base64::encode_base64($mail->{smtp_usr},'')."\r\n",$print_msg,__LINE__);
	_server_parse($sock, "334",$print_msg,__LINE__);
	_server_send($sock,MIME::Base64::encode_base64($mail->{smtp_pass},'')."\r\n",$print_msg,__LINE__);
	_server_parse($sock, "235",$print_msg,__LINE__);
	_server_send($sock,"MAIL FROM:  <$mail->{from}>\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	
	foreach my $to(@{$mail->{ra_to}}){
		_server_send($sock,"RCPT TO: <$to>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $cc(@{$mail->{ra_cc}}){
		_server_send($sock,"RCPT TO: <$cc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $bcc(@{$mail->{ra_bcc}}){
		_server_send($sock,"RCPT TO: <$bcc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	
	_server_send($sock,"DATA\r\n",$print_msg,__LINE__);
	_server_parse($sock, "354",$print_msg,__LINE__);
	_server_send($sock,$mail->{smtp_mail}."\r\n.\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"QUIT\r\n",$print_msg,__LINE__);
	_server_parse($sock, "221",$print_msg,__LINE__);
	$sock->shutdown(2);
}

sub _smtp_AUTH_PLAIN($){
	my ($mail)=@_;
	my $smtp_host=defined($mail->{smtp_host})?$mail->{smtp_host}:'localhost';
	my $smtp_port=defined($mail->{smtp_port})?$mail->{smtp_port}:25;
	my $print_msg=defined($mail->{print_msg})?$mail->{print_msg}:0;
	my $sock=new IO::Socket::INET->new(PeerPort=>$smtp_port,Proto=>'tcp',PeerAddr=>$smtp_host);
	if(!defined($sock)){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: cannot connect to smtp server!');}
	
	_server_parse($sock, "220",$print_msg,__LINE__);
	_server_send($sock,"EHLO $mail->{smtp_host}\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"AUTH PLAIN ".MIME::Base64::encode_base64(join("\0",$mail->{smtp_usr},$mail->{smtp_pass})),$print_msg,__LINE__);
	_server_parse($sock, "235",$print_msg,__LINE__);
	_server_send($sock,"MAIL FROM:  <$mail->{from}>\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);

	foreach my $to(@{$mail->{ra_to}}){
		_server_send($sock,"RCPT TO: <$to>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $cc(@{$mail->{ra_cc}}){
		_server_send($sock,"RCPT TO: <$cc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $bcc(@{$mail->{ra_bcc}}){
		_server_send($sock,"RCPT TO: <$bcc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	
	_server_send($sock,"DATA\r\n",$print_msg,__LINE__);
	_server_parse($sock, "354",$print_msg,__LINE__);
	_server_send($sock,$mail->{smtp_mail}."\r\n.\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"QUIT\r\n",$print_msg,__LINE__);
	_server_parse($sock, "221",$print_msg,__LINE__);
	$sock->shutdown(2);
}

sub _smtp_AUTH_NONE($){
	my ($mail)=@_;
	my $smtp_host=defined($mail->{smtp_host})?$mail->{smtp_host}:'localhost';
	my $smtp_port=defined($mail->{smtp_port})?$mail->{smtp_port}:25;
	my $print_msg=defined($mail->{print_msg})?$mail->{print_msg}:0;
	my $sock=new IO::Socket::INET->new(PeerPort=>$smtp_port,Proto=>'tcp',PeerAddr=>$smtp_host);
	if(!defined($sock)){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: cannot connect to smtp server!');}
	
	_server_parse($sock, "220",$print_msg,__LINE__);
	_server_send($sock,"EHLO $mail->{smtp_host}\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"MAIL FROM:  <$mail->{from}>\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);

	foreach my $to(@{$mail->{ra_to}}){
		_server_send($sock,"RCPT TO: <$to>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $cc(@{$mail->{ra_cc}}){
		_server_send($sock,"RCPT TO: <$cc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}
	foreach my $bcc(@{$mail->{ra_bcc}}){
		_server_send($sock,"RCPT TO: <$bcc>\r\n",$print_msg,__LINE__);
		_server_parse($sock, "250",$print_msg,__LINE__);
	}

	_server_send($sock,"DATA\r\n",$print_msg,__LINE__);
	_server_parse($sock, "354",$print_msg,__LINE__);
	_server_send($sock,$mail->{smtp_mail}."\r\n.\r\n",$print_msg,__LINE__);
	_server_parse($sock, "250",$print_msg,__LINE__);
	_server_send($sock,"QUIT\r\n",$print_msg,__LINE__);
	_server_parse($sock, "221",$print_msg,__LINE__);
	$sock->shutdown(2);
}

sub _sendmail($){
	my ($mail,$path,$use_close)=($_[0]->{sendmail_mail},$_[0]->{sendmail_path},$_[0]->{sendmail_use_close});
	$path=defined($path)?$path:'sendmail';
	eval{
		if(!open(MAIL, "| $path -t")){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: sendmail_path not valid');
		}
	};
	if($@){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: sendmail_path not valid');
	}
	print MAIL $mail;
	undef $mail;
	unless(defined($use_close)&&$use_close==0){close(MAIL);}
}

sub _server_parse($$$$){
	my ($socket, $response,$print_msg,$line)=@_;
	my $server_response;
	$socket->recv($server_response, 4096);
	if(!defined($server_response)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: couldn\'t get mail server response codes');
	}
	my @response_lines=split(/\015?\012/, $server_response, -1);
	my $code;
	while(1){
		my $response_line=shift @response_lines;
		if(!defined($response_line)){last;}
		if($print_msg){print $response_line."\n";}
		if($response_line=~ s/^(\d\d\d)(.?)//o){if($2 ne "-"){$code=$1;last;}}
	}
	#qian.yu
	if (!(defined($code) && defined($response) && ($code eq $response) )){ 
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'')."sendmail: couldn\'t get expected mail server response codes \nExpected: $response ,\n Server Response:\n $server_response ");
	}
};

sub _server_send($$$){
	my ($socket,$msg,$print_msg,$line)=@_;
	if($print_msg){
		print trim($msg)."\n";
	}
	if(!$socket->send($msg)){
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'sendmail: send command to server error');
	};
}

sub trim($) {
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_=$_[0];
		unless(defined($_)){return undef;}
		s/^\s+//,s/\s+$//;
		return $_ ;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'trim: param count should be 1');
	}
}

1;

__END__


=head1 NAME

EasyMail - Perl Send Mail Interface

=head1 SYNOPSIS

  use EasyMail;
  
  if(defined(&EasyMail::foo)){
    print "lib is included";
  }else{
    print "lib is not included";
  }
  
  my $email_from = {'email'=>'test@adways.net', 'name'=>'Test'};
  
  my $email_to = 'receiver@adways.net';
  
#	$email_name_pair is a variable specify a email and name
#		$name can be undef,set $name=undef if $name eq ''
#		$email_name_pair can be a string
#		A: "$email"
#		B: "$name $email" if not A
#		C: "$email $name" if not A,B
#		D: "\"$name\"<$email>" if not A,B,C
#		E: "$name<$email>" if not A,B,C,D
#		$email can be a array_ref
#		A: [$email,$name]
#		B: [$name,$email] if not A
#		$email can be a hash_ref
#		{email=>$email,name=>$name}
  
  my $email_cc = $email_to;
  my $email_bcc = [];
  
  my $ra_filters = ['adways.net'];
  
  my $file = {
			'file_path' => '/usr/local/src/test.txt', 
				#path to file 
			'file_bin' => undef, 
				#binary content of file
			'file_name' => undef, 
				#file name
			'content_type' => undef, 
				#content type
			'content_id' => undef
				#content_id, when u wanna embed picture in html email u need it

#			the rule of $file
#			1,you "must and  can only" set one of file_path and file_bin,or will throw an exception
#			2,if file_name set, {file_name}=file_name
#			3,if file_name not set and file_path set,then {file_name} will be generate by file_path
#			4,if file_name not set and file_path not set and content_id set,then no {file_name}
#			5,if content_type set，then {content_type}=content_type
#			6,if content_type not set and {file_name} set，then {content_type} will be generate by {file_name}
#			7,if content_id set,then consider this file as part of multi_related structure，else if content_id not set then consider this file as part of multi_mixed structure
  };
  
  my $mail = {
			'sender_type' => 'SMTPAUTHLOGIN', 
				# SENDMAIL | SMTPAUTHLOGIN | SMTPAUTHPLAIN | SMTPAUTHNONE 
				# default is 'SENDMAIL'
			'smtp_host' => '127.0.0.1', 
				# smtp host address default is 127.0.0.1 (if sender is smtp)
			'smtp_port' => 25, 
				# smtp host port (if sender is smtp)
			'smtp_usr' => 'admin', 
				# smtp author usr name (if needed)
			'smtp_pass' => 'password', 
				# smtp author usr pass (if needed)
			'sendmail_path' => '/usr/sbin', 
			 	# the path of sendmail, default is 'sendmail'(if needed)
			'type' => 'txt', 
				# can be 'html' 'plain' 'txt' 'text' default is 'plain'
				# 'txt' 'text' is alias for 'plain'
				# the recomend way you set mail as plain text mail is set it 'plain'
			'subject' => 'Test Mail', 
				# the mail subject, default is 'No Subject'
			'body' => 'This is a test.', 
				# the text content of mail, default is ''
			'files' => $file, 
				# files to be attach to the mail files=>[$file,$file,..], default is []
			'from' => $email_from, 
				# $email_name_pair
			'to' => $email_to, 
				# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
			'cc' => $email_cc, 
				# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
			'bcc' => $email_bcc, 
				# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
			'mail_filter' => $ra_filters, 
				# [$email_filter, $email_filter, ..], default is []
				# email_filter: only allow specified email to send ( for debug use)
			'return_path' => '/tmp/failmail', 
				#sendmail to this address if sendmail fail ,default is not set
			'src_encoding' => 'utf8', 
				#source mail encoding
			'dst' => 'un'
				# 'cn' || 'un' || 'jp'
				# 'cn' for gb2312 encoding, 'un' for utf8 encoding, 'jp' for iso-2022-jp encoding

#			extra rules:
#				from is must set
#				to and cc must contains more than one valid email
#				if (input is all unicode or input is all ascii){
#					src_encoding can be not set
#				}else{
#					src_encoding must set
#				}
#				dst must set
#				in to cc bcc, [$email,$email] is parse as two receiver email

	};

	EasyMail::sendmail($mail);
  
I<The synopsis above only lists the major methods and parameters.>

=head1 Basic Variables and Hash Options

=head2 $mail - all content of the mail

	$mail is a hash_ref with below options :
			
		sender_type
			# SENDMAIL | SMTPAUTHLOGIN | SMTPAUTHPLAIN | SMTPAUTHNONE | DIRECT
			# default is 'SENDMAIL'
		smtp_host
			# smtp host address default is 127.0.0.1 (if sender is smtp)
		smtp_port
			# smtp host address (if sender is smtp)
		smtp_usr
			# smtp author usr name (if needed)
		smtp_pass
			# smtp author usr pass (if needed)
		sendmail_path
		 	#the path of sendmail, default is 'sendmail'(if needed)
	
		type
			#can be 'html' 'plain' 'txt' 'text' default is 'plain'
			#'txt' 'text' is alias for 'plain'
			#the recomend way you set mail as plain text mail is set it 'plain'
		subject
			#the mail subject, default is 'No Subject'
		body
			#the text content of mail, default is ''
		files
			#files to be attach to the mail files=>[$file,$file,..], default is []
		from
			#$email_name_pair
		to
			# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
		cc
			# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
		bcc
			# $email_name_pair || [$email_name_pair,$email_name_pair,..], default is []
		return_path
			#sendmail to this address if sendmail fail ,default is not set
		src_encoding
			#source mail encoding
		dst
			# 'cn' || 'un' || 'jp'
			# 'cn' for gb2312 encoding, 'un' for utf8 encoding, 'jp' for iso-2022-jp encoding

	extra rules:
		from is must set
		to and cc must contains more than one valid email
		if (input is all unicode or input is all ascii){
			src_encoding can be not set
		}else{
			src_encoding must set
		}
		dst must set
		in to cc bcc, [$email,$email] is parse as two receiver email

=head2 $email_name_pair - the email-name pair

	$email_name_pair is a variable specify a email and name
			
		$name can be undef,set $name=undef if $name eq ''

		$email_name_pair can be a string:
			A: "$email"
			B: "$name $email" if not A
			C: "$email $name" if not A,B
			D: "\"$name\"<$email>" if not A,B,C
			E: "$name<$email>" if not A,B,C,D

		$email can be a array_ref:
			A: [$email,$name]
			B: [$name,$email] if not A

		$email can be a hash_ref:
			{email=>$email,name=>$name}

=head2 $file - the file attached
	
	$file is a hash_ref with below options :
		file_path
			#path to file 
		file_bin
			#binary content of file
		file_name
			#file name
		content_type
			#content type
		content_id
			#content_id, when u wanna embed picture in html email u need it

	the rule of $file:
		1,you "must and  can only" set one of file_path and file_bin,or will throw an exception
		2,if file_name set, {file_name}=file_name
		3,if file_name not set and file_path set,then {file_name} will be generate by file_path
		4,if file_name not set and file_path not set and content_id set,then no {file_name}
		5,if content_type set，then {content_type}=content_type
		6,if content_type not set and {file_name} set，then {content_type} will be generate by {file_name}
		7,if content_id set,then consider this file as part of multi_related structure，else if content_id not set then consider this file as part of multi_mixed structure


=head1 COPYRIGHT

The EasyMail module is Copyright (c) 2003-2008 QIAN YU.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


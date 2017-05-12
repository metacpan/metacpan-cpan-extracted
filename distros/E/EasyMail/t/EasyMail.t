use strict;
use warnings(FATAL=>'all');
use Time::Local;
use EasyMail;

#===export EasyTest Function
sub plan {&EasyTest::std_plan};
*ok = \&EasyTest::ok;
sub DIE {&EasyTest::DIE};
sub NO_DIE {&EasyTest::NO_DIE};
sub ANY {&EasyTest::ANY};
#==============================

plan(92);

my ($true,$false)=(1,'');

#EasyMail::trim, test 1-6
ok(&DIE, \&EasyMail::trim, []);
ok(undef, \&EasyMail::trim, [undef]);
ok("test", \&EasyMail::trim, ["test"]);
ok("test", \&EasyMail::trim, [" \t test"]);
ok("test", \&EasyMail::trim, ["  \rtest \n "]);
ok("test", \&EasyMail::trim, ["test \f "]);

#EasyMail::is_email, test 7-17
ok(&DIE, \&EasyMail::is_email, []);
ok($false, \&EasyMail::is_email, [undef]);
ok($true, \&EasyMail::is_email, ['_@0-A.zA']);
ok($true, \&EasyMail::is_email, ['0@0.zAktfG']);
ok($false, \&EasyMail::is_email, ['t@t.zAktfGa']);
ok($false, \&EasyMail::is_email, ['t@test.a']);
ok($true, \&EasyMail::is_email, ['__-.-b@0.0.com']);
ok($false, \&EasyMail::is_email, ['tadas']);
ok($false, \&EasyMail::is_email, ['test@a..com']);
ok($true, \&EasyMail::is_email, ['.-@test.com']);
ok($false, \&EasyMail::is_email, ['@test.com']);


#EasyMail::gen_mime_boundary, test 18
ok('------------0601000700040308020210023', \&EasyMail::gen_mime_boundary, [10023]);

#EasyMail::guess_file_content_type, test 19-59
ok(undef, \&EasyMail::guess_file_content_type, []);
ok('audio/basic', \&EasyMail::guess_file_content_type, ['\tmp\test.au']);
ok('video/x-msvideo', \&EasyMail::guess_file_content_type, ['\tmp\test.avi']);
ok('application/octet-stream', \&EasyMail::guess_file_content_type, ['\tmp\test.class']);
ok('application/mac-compactpro', \&EasyMail::guess_file_content_type, ['\tmp\test.cpt']);
ok('application/x-director', \&EasyMail::guess_file_content_type, ['\tmp\test.dcr']);
ok('application/x-director', \&EasyMail::guess_file_content_type, ['\tmp\test.dir']);
ok('application/msword', \&EasyMail::guess_file_content_type, ['\tmp\test.doc']);
ok('application/octet-stream', \&EasyMail::guess_file_content_type, ['\tmp\test.exe']);
ok('image/gif', \&EasyMail::guess_file_content_type, ['\tmp\test.gif']);
ok('application/x-gentrix', \&EasyMail::guess_file_content_type, ['\tmp\test.gtx']);
ok('image/jpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.jpeg']);
ok('image/jpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.jpg']);
ok('application/x-javascript', \&EasyMail::guess_file_content_type, ['\tmp\test.js']);
ok('application/mac-binhex40', \&EasyMail::guess_file_content_type, ['\tmp\test.hqx']);
ok('text/html', \&EasyMail::guess_file_content_type, ['\tmp\test.htm']);
ok('text/html', \&EasyMail::guess_file_content_type, ['\tmp\test.html']);
ok('audio/midi', \&EasyMail::guess_file_content_type, ['\tmp\test.mid']);
ok('audio/midi', \&EasyMail::guess_file_content_type, ['\tmp\test.midi']);
ok('video/quicktime', \&EasyMail::guess_file_content_type, ['\tmp\test.mov']);
ok('audio/mpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.mp2']);
ok('audio/mpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.mp3']);
ok('video/mpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.mpeg']);
ok('video/mpeg', \&EasyMail::guess_file_content_type, ['\tmp\test.mpg']);
ok('application/pdf', \&EasyMail::guess_file_content_type, ['\tmp\test.pdf']);
ok('text/plain', \&EasyMail::guess_file_content_type, ['\tmp\test.pm']);
ok('text/plain', \&EasyMail::guess_file_content_type, ['\tmp\test.pl']);
ok('application/powerpoint', \&EasyMail::guess_file_content_type, ['\tmp\test.ppt']);
ok('application/postscript', \&EasyMail::guess_file_content_type, ['\tmp\test.ps']);
ok('video/quicktime', \&EasyMail::guess_file_content_type, ['\tmp\test.qt']);
ok('audio/x-pn-realaudio', \&EasyMail::guess_file_content_type, ['\tmp\test.ram']);
ok('application/rtf', \&EasyMail::guess_file_content_type, ['\tmp\test.rtf']);
ok('application/x-tar', \&EasyMail::guess_file_content_type, ['\tmp\test.tar']);
ok('image/tiff', \&EasyMail::guess_file_content_type, ['\tmp\test.tif']);
ok('image/tiff', \&EasyMail::guess_file_content_type, ['\tmp\test.tiff']);
ok('text/plain', \&EasyMail::guess_file_content_type, ['\tmp\test.txt']);
ok('audio/x-wav', \&EasyMail::guess_file_content_type, ['\tmp\test.wav']);
ok('image/x-xbitmap', \&EasyMail::guess_file_content_type, ['\tmp\test.xbm']);
ok('application/zip', \&EasyMail::guess_file_content_type, ['\tmp\test.zip']);
ok('application/octet-stream', \&EasyMail::guess_file_content_type, ['\tmp\test']);
ok('application/octet-stream', \&EasyMail::guess_file_content_type, ['\tmp\test.other']);

#EasyMail::change_encoding, test 60-62
ok('test', \&EasyMail::change_encoding, ['test', 'utf8', 'utf8']);
ok('test', \&EasyMail::change_encoding, ['test', 'gbk', 'utf8']);
ok('≤‚ ‘', \&EasyMail::change_encoding, ['≤‚ ‘', 'gbk', 'gbk']);

#EasyMail::encode_header, test 63
ok('test', \&EasyMail::encode_header, ['test', 'utf8', 'utf8', 'utf8']);

#EasyMail::gen_header, test 64-65
ok("Key: Value\n", \&EasyMail::gen_header, ['Key', 'Value', "\n"]);
ok('', \&EasyMail::gen_header, ['Key', undef, "\n"]);

#EasyMail::gen_email_name_pair, test 66-67
ok(['"test" <mail@adways.net>', 'mail@adways.net'], \&EasyMail::gen_email_name_pair, ['mail@adways.net', 'test', 'utf8', 'utf8', 'utf8'], 1);
ok(['mail@adways.net', 'mail@adways.net'], \&EasyMail::gen_email_name_pair, ['mail@adways.net', undef, 'utf8', 'utf8', 'utf8'], 1);

#EasyMail::parse_email_name_pair, test 68-81
ok(['test@adways.net', undef], \&EasyMail::parse_email_name_pair, ['test@adways.net'], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, ['test  test@adways.net'], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, ['test@adways.net  test'], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, ['"test" <test@adways.net>'], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, ['test<test@adways.net>'], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, ['test'], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, [['test', 'test@adways.net']], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, [['test@adways.net', 'test']], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, [['test', 'test']], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, [['test@adways.net', ['test']]], 1);
ok(['test@adways.net', 'test'], \&EasyMail::parse_email_name_pair, [{'name'=>'test', 'email'=>'test@adways.net'}], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, [{'name'=>'test', 'email'=>'test'}], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, [{'name'=>['test'], 'email'=>'test@adways.net'}], 1);
ok([undef, undef], \&EasyMail::parse_email_name_pair, [], 1);

#EasyMail::gen_email_name_pair_list, test 82-88
ok([undef, []], \&EasyMail::gen_email_name_pair_list, [undef, 'utf8', 'utf8', 'utf8'], 1);
ok(['"test" <test@adways.net>', ['test@adways.net']], \&EasyMail::gen_email_name_pair_list, ['test<test@adways.net>', 'utf8', 'utf8', 'utf8'], 1);
ok(['"test" <test@adways.net>', ['test@adways.net']], \&EasyMail::gen_email_name_pair_list, [{'name'=>'test', 'email'=>'test@adways.net'}, 'utf8', 'utf8', 'utf8'], 1);
ok(['"test" <test@adways.net>', ['test@adways.net']], \&EasyMail::gen_email_name_pair_list, [['test', 'test@adways.net'], 'utf8', 'utf8', 'utf8'], 1);
ok(['"test" <test@adways.net>', ['test@adways.net']], \&EasyMail::gen_email_name_pair_list, [['test@adways.net', 'test'], 'utf8', 'utf8', 'utf8'], 1);
ok([undef, []], \&EasyMail::gen_email_name_pair_list, [[], 'utf8', 'utf8', 'utf8'], 1);
ok(['"test" <test@adways.net>,"test" <test@adways.net>,test@adways.net', 
		['test@adways.net', 'test@adways.net', 'test@adways.net']], 
	\&EasyMail::gen_email_name_pair_list, 
	[['test  test@adways.net', 'test<test@adways.net>', 'test@adways.net'], 'utf8', 'utf8', 'utf8'], 1);

#EasyMail::gen_date

#EasyMail::gen_part_file

#EasyMail::parse_part_text, test 89-92
ok(["Content-Transfer-Encoding: 7bit\n", "Content-Type: text/html; charset=us-ascii;\n", "\n\n"], \&EasyMail::parse_part_text, ['html', undef, 'utf8', 'utf8', 'utf8', "\n"], 1);
ok(["Content-Transfer-Encoding: 7bit\n", "Content-Type: text/html; charset=us-ascii;\n", "test\n\n"], \&EasyMail::parse_part_text, ['html', 'test', 'utf8', 'utf8', 'utf8', "\n"], 1);
ok(["Content-Transfer-Encoding: 7bit\n", "Content-Type: text/plain; charset=us-ascii;\n", "\n\n"], \&EasyMail::parse_part_text, ['plain', undef, 'utf8', 'utf8', 'utf8', "\n"], 1);
ok(["Content-Transfer-Encoding: 8bit\n", "Content-Type: text/html; charset=utf8;\n", '≤‚ ‘'."\n\n"], \&EasyMail::parse_part_text, ['html', '≤‚ ‘', 'utf8', 'utf8', 'utf8', "\n"], 1);

#EasyMail::sendmail, test 93-95
  my $email_from = {'email'=>'huang.shuai@adways.net', 'name'=>'Kylin Huang'};
  my $email_to = 'huang.shuai@adways.net';
  my $email_cc = [];
  my $email_bcc = [];
  my $email_filter = [];
  my $file = [];#{
#			'file_path' => '/usr/local/src/test.txt', 
#			'file_bin' => undef, 
#			'file_name' => undef, 
#			'content_type' => undef, 
#			'content_id' => undef
#  };
  my $mail = {
			'sender_type' => 'SMTPAUTHNONE', 
			'smtp_host' => '127.0.0.1', 
			'smtp_port' => 25, 
			'smtp_usr' => 'admin', 
			'smtp_pass' => 'password', 
			'sendmail_path' => '/usr/sbin', 
			'type' => 'txt', 
			'subject' => 'Test Mail', 
			'body' => 'This is a test.', 
			'files' => $file, 
			'from' => $email_from, 
			'to' => $email_to, 
			'cc' => $email_cc, 
			'bcc' => $email_bcc, 
			'mail_filter' => $email_filter,
			'return_path' => '/tmp/failmail', 
			'src_encoding' => 'utf8', 
			'dst' => 'un'
	};
#ok(&NO_DIE, \&EasyMail::sendmail, [$mail]);

  $email_to = ['huang.shuai@adways.net', 'sevchenko_hs@hotmail.com', 'qlz.fudan@gmail.com'];
  $mail = {
			'sender_type' => 'SMTPAUTHNONE', 
			'smtp_host' => '127.0.0.1', 
			'smtp_port' => 25, 
			'smtp_usr' => 'admin', 
			'smtp_pass' => 'password', 
			'sendmail_path' => '/usr/sbin', 
			'type' => 'txt', 
			'subject' => 'Test Mail', 
			'body' => 'This is a test.', 
			'files' => $file, 
			'from' => $email_from, 
			'to' => $email_to, 
			'cc' => $email_cc, 
			'bcc' => $email_bcc, 
			'mail_filter' => $email_filter,
			'return_path' => '/tmp/failmail', 
			'src_encoding' => 'utf8', 
			'dst' => 'un'
	};
#ok(&NO_DIE, \&EasyMail::sendmail, [$mail]);

  $email_filter = ['adways.net', 'gmail.com'];
  $mail = {
			'sender_type' => 'SMTPAUTHNONE', 
			'smtp_host' => '127.0.0.1', 
			'smtp_port' => 25, 
			'smtp_usr' => 'admin', 
			'smtp_pass' => 'password', 
			'sendmail_path' => '/usr/sbin', 
			'type' => 'txt', 
			'subject' => 'Test Mail', 
			'body' => 'This is a test.', 
			'files' => $file, 
			'from' => $email_from, 
			'to' => $email_to, 
			'cc' => $email_cc, 
			'bcc' => $email_bcc, 
			'mail_filter' => $email_filter,
			'return_path' => '/tmp/failmail', 
			'src_encoding' => 'utf8', 
			'dst' => 'un'
	};
#ok(&NO_DIE, \&EasyMail::sendmail, [$mail]);


1;

















package EasyTest;
use strict;
use warnings(FATAL=>'all');

#===================================
#===Module  : EasyTest
#===Comment : module for writing test script
#===================================

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 19937129           ===
#===Homepage: www.lua.cn         ===
#===================================

use Exporter 'import';
use Test qw();

our $bool_std_test;
our $plan_test_count;
our $test_count;
our $succ_test;
our $fail_test;
our ($true,$false);

BEGIN{
        our @EXPORT = qw(&ok &plan &std_plan &DIE &NO_DIE);
        $bool_std_test='';
        $plan_test_count=undef;
        $test_count=0;
        $succ_test=0;
        $fail_test=0;
        ($true,$false) = (1,'');
};

sub foo{1};
sub _name_pkg_name{__PACKAGE__;}

#===ok($result,$value); if $result same as $value test succ, else test fail
#===ok($result,$func,$ra_param);#same as ok($result,$func,$ra_param,0);
#===ok($ra_result,$func,$ra_param,1); test result in array  mode
#===ok($   result,$func,$ra_param,0); test result in scalar mode
sub ok{
        my $param_count=scalar(@_);
        if($param_count==2){
                if(&dump($_[0]) eq &dump($_[1])){
                        $test_count++;$succ_test++;
                        if($bool_std_test){
                                Test::ok($true);
                        }else{
                                print "ok $test_count\n";
                        }
                        return $true;
                }else{
                        $test_count++;$fail_test++;
                        if($bool_std_test){
                                Test::ok($false);
                        }else{
                                my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                print "not ok $test_count $caller_info\n";
                        }
                        return $false;
                }
        }elsif($param_count==4||$param_count==3){
                my $result;
                my $mode;
                if($param_count==3){
                        $mode=1;
                }elsif($param_count==4&&defined($_[3])&&$_[3]==0){
                        $mode=1;
                }elsif($param_count==4&&defined($_[3])&&$_[3]==1){
                        $mode=2;
                }else{#default
                        $mode=1;
                }
                if($mode==1){
                        eval{$result=$_[1]->(@{$_[2]});};
                }elsif($mode==2){
                        eval{$result=[$_[1]->(@{$_[2]})];};
                }else{
                        CORE::die 'BUG';
                }
                if($@){
                        undef $@;
                        if(DIE($_[0])){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }else{
                                $test_count++;$fail_test++;
                                if($bool_std_test){
                                        Test::ok($false);
                                }else{
                                        my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                        print "not ok $test_count $caller_info\n";
                                }
                                return $false;
                        }
                }else{
                        if ((defined $_[0]) && (defined $result)){
                            if (ref $_[0] ne 'ARRAY'){
                                if (ANY($_[0])){
                                    $_[0] = undef;
                                    $result = undef;
                                }
                            }else{
                                if($#{$_[0]} == $#$result){
                                    foreach(0 .. $#{$_[0]}){
                                        if(ANY($_[0][$_])){
                                            @{$_[0]}[$_] = undef;
                                            @$result[$_] = undef;
                                        }
                                    }
                                }
                            }
                        }
                        if(NO_DIE($_[0])){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }elsif(&dump($_[0]) eq &dump($result)){
                                $test_count++;$succ_test++;
                                if($bool_std_test){
                                        Test::ok($true);
                                }else{
                                        print "ok $test_count\n";
                                }
                                return $true;
                        }else{
                                $test_count++;$fail_test++;
                                if($bool_std_test){
                                        Test::ok($false);
                                }else{
                                        my $caller_info=sprintf('LINE %04s',[caller(0)]->[2]);
                                        print "not ok $test_count $caller_info\n";
                                }
                                return $false;
                        }
                }
        }else{
                CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'ok: param count should be 2, 3, 4');
        }
}

sub plan($){
        $plan_test_count=$_[0];
        print "plan to test $plan_test_count \n";
}

sub std_plan($){
        $plan_test_count=$_[0];
        $bool_std_test=1;
        Test::plan(tests=>$plan_test_count);
}

sub DIE{
        my $code=1;
        if(scalar(@_)==0){
                return bless [$code,'DIE'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
                die 'EasyTest::DIE: param number should be 0 or 1';
        }
}

sub NO_DIE{
        my $code=2;
        if(scalar(@_)==0){
                return bless [$code,'NO_DIE'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
                die 'EasyTest::NO_DIE: param number should be 0 or 1';
        }
}

sub ANY{
        my $code=3;
        if(scalar(@_)==0){
                return bless [$code,'ANY'],'Framework::EasyTest::CONSTANT';
        }elsif(scalar(@_)==1){
                return ref $_[0] eq 'Framework::EasyTest::CONSTANT' && $_[0]->[0]==$code?1:'';
        }else{
                die 'EasyTest::ANY: param number should be 0 or 1';
        }
}

END{
        if(!$bool_std_test){
                if(defined($plan_test_count)){
                        if($plan_test_count==($succ_test+$fail_test)&&$fail_test==0){
                                print "plan test $plan_test_count ,finally test $test_count, $succ_test succ,$fail_test fail,test successful!\n";
                        }else{
                                CORE::die "plan test $plan_test_count ,finally test $test_count, $succ_test succ,$fail_test fail,test failed!\n";
                        }
                }else{
                        print "finally test $test_count, $succ_test succ,$fail_test fail\n";
                }
        }
}

sub qquote {
        local($_) = shift;
        s/([\\\"\@\$])/\\$1/g;
        s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
        return qq("$_") unless
                /[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/;  # fast exit
        s/([\a\b\t\n\f\r\e])/{
                "\a" => "\\a","\b" => "\\b","\t" => "\\t","\n" => "\\n",
            "\f" => "\\f","\r" => "\\r","\e" => "\\e"}->{$1}/eg;
        s/([\0-\037\177])/'\\x'.sprintf('%02X',ord($1))/eg;
        s/([\200-\377])/'\\x'.sprintf('%02X',ord($1))/eg;
        return qq("$_");
}

sub qquote_bin{
        local($_) = shift;
        s/([\x00-\xff])/'\\x'.sprintf('%02X',ord($1))/eg;
        s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
        return qq("$_");
}

sub dump{
        my $max_line=80;
        my $param_count=scalar(@_);
        my ($flag,$str1,$str2);
        if($param_count==1){
                my $data=$_[0];
                my $type=ref $data;
                if($type eq 'ARRAY'){
                        my $strs=[];
                        foreach(@$data){push @$strs,&dump($_);}

                        $str1='[';$flag=0;
                        foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
                        if($flag==1){chop($str1);chop($str1);}
                        $str1.=']';

                        $str2='[';
                        foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
                        $str2.="\n]";

                        return length($str1)>$max_line?$str2:$str1;
                }elsif($type eq 'HASH'){
                        my $strs=[];
                        foreach(keys(%$data)){push @$strs,[qquote($_),&dump($data->{$_})];}

                        $str1='{';$flag=0;
                        foreach(@$strs){$str1.="$_->[0]\x20=>\x20$_->[1],\x20";$flag=1;}
                        if($flag==1){chop($str1);chop($str1);}
                        $str1.='}';

                        $str2='{';
                        foreach(@$strs){ $_->[1]=~s/\n/\n\x20\x20/g;$str2.="\n\x20\x20$_->[0]\x20=>\x20$_->[1],";}
                        $str2.="\n}";

                        return length($str1)>$max_line?$str2:$str1;
                }elsif($type eq 'SCALAR'||$type eq 'REF'){
                        return "\\".&dump($$data);
                }elsif($type eq ''){
                        $flag=0;
                        if(!defined($data)){return 'undef'};
                        eval{if($data eq int $data){$flag=1;}};
                        if($@){undef $@;}
                        if($flag==0){return qquote($data);}
                        elsif($flag==1){return $data;}
                        else{ die 'dump:BUG!';}
                }else{
                        return ''.$data;#===if not a simple type
                }
        }else{
                my $strs=[];
                foreach(@_){push @$strs,&dump($_);}

                $str1='(';
                $flag=0;
                foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
                if($flag==1){chop($str1);chop($str1);}
                $str1.=')';

                $str2='(';
                foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
                $str2.="\n)";

                return length($str1)>$max_line?$str2:$str1;
        }
}

1;

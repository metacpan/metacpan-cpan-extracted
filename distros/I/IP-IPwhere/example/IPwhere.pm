package IPwhere;
$Mojo::Webqq::Plugin::Pu::PRIORITY = 1;
use IP::IPwhere;
use IP::QQWry;
use Encode;

#This is pluge for Mojo::webqq,you must install
# all moduel needed:IP::QQWry and QQWry.Dat.

my $qqwry = IP::QQWry->new('QQWry.Dat');

sub gquery {

my ($ip)=shift;
my ($base,$info) = $qqwry->query($ip);
my $result;
$result="qqwry $ip:";
$result.=decode('gbk',$base);
$result.=decode('gbk',$info)."\n";
return $result;

}


my $re=qr([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]);
my $ipre=qr/($re\.){3}$re$/;

sub call {
    my $client = shift;
    $client->on(receive_message=>sub{
        my($client,$msg)=@_;
        return if not $msg->allow_plugin;
        return if $msg->content !~ /IPwhere\s*($ipre)/;
        my $arg= $1 if $msg->content=~ /IPwhere\s*($ipre)/;
        $reply= Encode::encode("utf8",squery($arg));
         $reply.=Encode::encode("utf8",gquery($arg));
        $client->reply_message($msg,$reply,sub{$_[1]->msg_from("bot")}) if $reply;
    });
}
1;

#!/usr/bin/perl -w
use strict;

my $VERSION = '0.08';

#----------------------------------------------------------
# Loader Variables

my $BASE;
BEGIN {
    $BASE = '../../cgi-bin';
}

#----------------------------------------------------------
# Library Modules

use lib ( "$BASE/lib", "$BASE/plugins" );
use utf8;

use Crypt::Lite;
use Digest::SHA1  qw(sha1_hex);
use HTML::Entities;
use JSON;
use WWW::Mechanize;

use Labyrinth::Globals;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

my %names;
my $config = "$BASE/config/settings.ini";

#----------------------------------------------------------
# Code

## Prepare data

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

my $yapc = $settings{icode};
my $key  = $settings{yapc_name};
my $api  = $settings{actapi_pass};
my $fmt  = $settings{actapi_users};

my $names = $settings{tutor_names};
for my $pattern (@$names) {
    my ($k,$v) = split('=',$pattern);
    $names{$k} = $v;
}


## Retrieve Act API data

my $url = sprintf $fmt, $yapc, $api;
$mech->get($url);
unless($mech->success) {
    print "FAIL: url=$url\n";
    exit;
}

#use Data::Dumper;
#print STDERR "content=".Dumper($mech->content());


## Process data

#my $data = from_json($mech->content(), {utf8 => 1});
my $data = from_json($mech->content());

#print STDERR "data=".Dumper($data);

my ($found,$saved,$reset,$total) = (0,0,0,0);

my %users;
for my $user (@$data) {
    for my $name (keys %names) {
        next    unless($user->{full_name} =~ /$name/);
        $user->{full_name} = $names{$name};
    }

    my $name = encode_entities($user->{full_name});
    my $nick = encode_entities($user->{nick_name});
    $users{$user->{email}} = 1;

    my @rows;
    @rows = $dbi->GetQuery('hash','FindUserByAct',$user->{user_id})  if($user->{user_id});
    @rows = $dbi->GetQuery('hash','FindUser',$user->{email})        unless(@rows);

    if(@rows) {
        if(!$rows[0]->{actuserid} || $rows[0]->{actuserid} == 0) {
            $dbi->DoQuery('UpdateActUser',$user->{user_id},$rows[0]->{userid});
        }

        if($rows[0]->{userid} > 2) {
            my @keys = $dbi->GetQuery('hash','GetUserCode',$rows[0]->{userid});
            $dbi->DoQuery('ConfirmUser',1,$rows[0]->{userid});
            #print "FOUND: $name <$user->{email}> => $keys[0]->{code}/$rows[0]->{userid}/$user->{userid}\n";
            $found++;
        }
        next;
    }

    my $str = $$ . $user->{email} . time();
    my $code = sha1_hex($crypt->encrypt($str, $key));

    $user->{user_id} ||= 0;
    my $userid = $dbi->IDQuery('NewUser',$user->{email},$nick,$name,$user->{email},$user->{user_id});
    $dbi->DoQuery('ConfirmUser',1,$userid);
    $dbi->DoQuery('SaveUserCode',$code,$userid);

    print "SAVED: $name <$user->{email}> => $code/$userid/$user->{user_id}\n";
    $saved++;
}

my @users = $dbi->GetQuery('hash','AllUsers');
#for my $user (@users) {
#    next    unless($user->{userid} > 2);
#    next    unless($user->{confirmed});
#    next    if($users{$user->{email}});
#    $dbi->DoQuery('ConfirmUser',0,$user->{userid});
#    print "RESET: $user->{realname} <$user->{email}>\n";
#    $reset++;
#}

print "FOUND: $found\n";
print "SAVED: $saved\n";
print "RESET: $reset\n";
print "TOTAL: ".(scalar @users)."\n";

__END__

=pod

Notes:

* userid == 1 is the guest user in the event of errors or no login
* userid == 2 is the master admin user

=cut

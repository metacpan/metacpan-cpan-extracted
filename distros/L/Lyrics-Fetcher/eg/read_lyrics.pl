#!/usr/bin/perl
#the dummest lyrics fetcher ever made. by reflog.

use Lyrics::Fetcher;
use MP3::Info;

if(not scalar(@ARGV)){ # nope. no args. let's check Xmms then.
use Xmms::Remote ();
my $remote = Xmms::Remote->new;
die "no xmms found" unless ($remote->is_running);
$mp3 = new MP3::Info (($remote->get_playlist_files)[0]->[$remote->get_playlist_pos]);
}else{ # ok we've got a param. is it a file that exists?
 if(-e $ARGV[0]){
 $mp3 = new MP3::Info ($ARGV[0]); 
 }else{
 die "no such file";
 }
}
# ok, all good, now if we have tags, we can try to find lyrics.
if($mp3->artist && $mp3->title){
$| = 1;
my(@fetchers) = Lyrics::Fetcher->available_fetchers();
foreach my $f (@fetchers){
    my($text) = Lyrics::Fetcher->fetch($mp3->artist,$mp3->title,$f);
    if($Lyrics::Fetcher::Error eq 'OK'){
        print "\n\n======== FOUND ON $f ======== \n\n";
	print $text;
	exit;
    }
}
}
else{
 die "no tags found!";
}
die "no lyrics found! :(";
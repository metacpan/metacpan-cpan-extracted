#!/usr/bin/perl -w
               
use MP3::Tag;

# define how autoinfo tries to get information
# default:
# MP3::Tag->config("autoinfo","ID3v2","ID3v1","filename");
# don't use ID3v2:
# MP3::Tag->config("autoinfo","ID3v1","filename");

while (<STDIN>) {
	chomp;
	if (my $mp3=MP3::Tag->new($_)) {
		print "$_ (Tags: ", join(", ",$mp3->get_tags),")\n";
		@info=$mp3->autoinfo;
		print "* Song: $info[0]\n";
		print "* Track: $info[1]\n";
		print "* Artist: $info[2]\n";
		print "* Album: $info[3]\n";
		print "* Comment: $info[4]\n";
	}
}

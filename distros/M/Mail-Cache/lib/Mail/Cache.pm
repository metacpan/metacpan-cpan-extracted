package Mail::Cache;

use warnings;
use strict;
use File::BaseDir qw/xdg_cache_home/;
use Email::Simple;


=head1 NAME

Mail::Cache - Caches mail info.

=head1 VERSION

Version 0.1.2

=cut

our $VERSION = '0.1.2';


=head1 SYNOPSIS

    use Mail::Cache;

    my $mc = Mail::Cache->new();

    #init for the module 'ZConf::Mail' for a IMAP account named 'foo@bar' for the box 'INBOX'
    $mc->init('ZConf::Mail', 'imap', 'foo@bar', 'INBOX');

    #populate a cache from a Mail::IMAPTalk object
    $imap->select('INBOX');
    my $sorted=$imap->sort('(subject)', 'UTF8', 'NOT', 'DELETED');
    my $int=0;
    while(defined($sorted->[$int])){
        my $headers=$imap->fetch($sorted->[$int], 'rfc822.header');
        my $size=$imap->fetch($sorted->[$int], 'rfc822.size');
        $mc->setUID($sorted->[$int], $headers->{$sorted->[$int]}{'rfc822.header'},
                    $size->{$sorted->[$int]}{'rfc822.size'});
        if($mc->{error}){
            print "Error!\n";
        }
        $int++;
    }

=head1 METHODS

=head2 new

=cut

sub new {
	my $home=xdg_cache_home.'/Mail::Cache/';

	my $self={error=>undef, errorString=>'', inline=>0,
			  home=>xdg_cache_home.'/Mail::Cache/', cache=>'Mail::Cache',
			  account=>'default', type=>'imap', box=>'INBOX'};
	bless $self;

	#make sure $self->{home} exists and if not try to create it
	if (! -e xdg_cache_home) {
		if (!mkdir(xdg_cache_home)) {
			$self->{error}=1;
			$self->{errorString}='Could not create xdg_cache_home,"'.xdg_cache_home.'"';
			warn('Mail-Cache new:1: '.$self->{errorString});
			return $self;
		}
	}
	if (! -e $self->{home}) {
		if (!mkdir($self->{home})) {
			$self->{error}=2;
			$self->{errorString}='Could not create xdg_cache_home."Mail::Cache", "'.
			                      $self->{home}.'"';
			warn('Mail-Cache new:2: '.$self->{errorString});
			return $self;
		}
	}

	return $self;
}

=head2 getAccount

This sets the account that is currently being worked with.

    my $account=$mc->getAccount;

=cut

sub getAccount{
	$_[0]->errorblank;
	return $_[0]->{account};
}

=head2 getBox

This gets the current mail box being used.

    my $box=$mc->getBox;

=cut

sub getBox{
	$_[0]->errorblank;
	return $_[0]->{box};
}

=head2 getCache

This gets the name of the current cache.

    my $cache=$mc->getCache;

=cut

sub getCache{
	$_[0]->errorblank;
	return $_[0]->{cache};
}

=head2 getDates

This fetches a parsed hash of the dates.

The returned hash has the UIDs as the keys and the value for
each hash entry is the the date from the header.

    my %dates=$mc->getDates;
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub getDates{
	my $self=$_[0];

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$self->{box}.'/';

	#make sure the directory and the size cache exist
	if (! -e $dir) {
		$self->{error}=15;
		$self->{errorString}='"'.$dir.'" does not exist';
		warn('Mail-Cache getDates:15: '.$self->{errorString});
		return undef;
	}
	if (! -e $dir.'.Date') {
		$self->{error}=16;
		$self->{errorString}='"'.$dir.'.Size" does not exist';
		warn('Mail-Cache getDates:16: '.$self->{errorString});
		return undef;
	}

	#read it into @dates
	open(GETDATESFH, $dir.'.Date');
	my @dates=<GETDATESFH>;
	close(GETDATESFH);

	#this is what will be returned
	my %toreturn;

	#go through each one
	my $int=0;
	while (defined($dates[$int])) {
		chomp($dates[$int]);

		my @linesplit=split(/\|/, $dates[$int], 2);

		#warn if a line is corrupt
		if (!defined($linesplit[1])) {
			warn('Mail-Cache getDates: line "'.$int.'" appears corrupt... '.$dates[$int]);
		}else {
			$toreturn{$linesplit[0]}=$linesplit[1];
		}

		$int++;
	}

	return %toreturn;
}

=head2 getSizes

This fetches a parsed hash of the subjects.

The returned hash has the UIDs as the keys and the value for
each hash entry is the the subject.

    my %subjects=$mc->getSizes;
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub getSizes{
	my $self=$_[0];

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$self->{box}.'/';

	#make sure the directory and the size cache exist
	if (! -e $dir) {
		$self->{error}=15;
		$self->{errorString}='"'.$dir.'" does not exist';
		warn('Mail-Cache getSizes:15: '.$self->{errorString});
		return undef;
	}
	if (! -e $dir.'.size') {
		$self->{error}=16;
		$self->{errorString}='"'.$dir.'.Size" does not exist';
		warn('Mail-Cache getSizes:16: '.$self->{errorString});
		return undef;
	}

	#read it into @sizes
	open(GETSIZES, $dir.'.size');
	my @sizes=<GETSIZES>;
	close(GETSIZES);

	#this is what will be returned
	my %toreturn;

	#go through each one
	my $int=0;
	while (defined($sizes[$int])) {
		chomp($sizes[$int]);

		my @linesplit=split(/\|/, $sizes[$int], 2);

		#warn if a line is corrupt
		if (!defined($linesplit[1])) {
			warn('Mail-Cache getSizes: line "'.$int.'" appears corrupt... '.$sizes[$int]);
		}else {
			$toreturn{$linesplit[0]}=$linesplit[1];
		}

		$int++;
	}

	return %toreturn;
}

=head2 getFroms

This fetches a parsed hash of the froms.

The returned hash has the UIDs as the keys and the value for
each hash entry is the the froms.

    my %sizes=$mc->getSizes;
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub getFroms{
	my $self=$_[0];

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$self->{box}.'/';

	#make sure the directory and the size cache exist
	if (! -e $dir) {
		$self->{error}=15;
		$self->{errorString}='"'.$dir.'" does not exist';
		warn('Mail-Cache getFroms:15: '.$self->{errorString});
		return undef;
	}
	if (! -e $dir.'.From') {
		$self->{error}=16;
		$self->{errorString}='"'.$dir.'.Size" does not exist';
		warn('Mail-Cache getFroms:16: '.$self->{errorString});
		return undef;
	}

	#read it into @froms
	open(GETFROMS, $dir.'.From');
	my @froms=<GETFROMS>;
	close(GETFROMS);

	#this is what will be returned
	my %toreturn;

	#go through each one
	my $int=0;
	while (defined($froms[$int])) {
		chomp($froms[$int]);

		my @linesplit=split(/\|/, $froms[$int], 2);

		#warn if a line is corrupt
		if (!defined($linesplit[1])) {
			warn('Mail-Cache getFroms: line "'.$int.'" appears corrupt... '.$froms[$int]);
		}else {
			$toreturn{$linesplit[0]}=$linesplit[1];
		}

		$int++;
	}

	return %toreturn;
}

=head2 getSubjects

This fetches a parsed hash of the sizes.

The returned hash has the UIDs as the keys and the value for
each hash entry is the the size.

    my %sizes=$mc->getSizes;
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub getSubjects{
	my $self=$_[0];

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$self->{box}.'/';

	#make sure the directory and the size cache exist
	if (! -e $dir) {
		$self->{error}=15;
		$self->{errorString}='"'.$dir.'" does not exist';
		warn('Mail-Cache getSubjects:15: '.$self->{errorString});
		return undef;
	}
	if (! -e $dir.'.Subject') {
		$self->{error}=16;
		$self->{errorString}='"'.$dir.'.Size" does not exist';
		warn('Mail-Cache getSubjects:16: '.$self->{errorString});
		return undef;
	}

	#read it into @subjects
	open(GETSUBJECTS, $dir.'.Subject');
	my @subjects=<GETSUBJECTS>;
	close(GETSUBJECTS);

	#this is what will be returned
	my %toreturn;

	#go through each one
	my $int=0;
	while (defined($subjects[$int])) {
		chomp($subjects[$int]);

		my @linesplit=split(/\|/, $subjects[$int], 2);

		#warn if a line is corrupt
		if (!defined($linesplit[1])) {
			warn('Mail-Cache getSubjects: line "'.$int.'" appears corrupt... '.$subjects[$int]);
		}else {
			$toreturn{$linesplit[0]}=$linesplit[1];
		}

		$int++;
	}

	return %toreturn;
}

=head2 getType

This gets the current type.

    my $type=$mc->getType;

=cut

sub getType{
	$_[0]->errorblank;
	return $_[0]->{type};
}

=head2 init

A short cut to calling the three different set methods.

    $mc->init($cache, $type, $account, $box);
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $cache=$_[1];
	my $type=$_[2];
	my $account=$_[3];
	my $box=$_[4];

	$self->errorblank;

	$self->setCache($cache);
	if ($self->{error}) {
		warn('Mail-Cache init: setCache failed');
		return undef;
	}

	$self->setType($type);
	if ($self->{error}) {
		warn('Mail-Cache init: setType failed');
		return undef;
	}

	$self->setAccount($account);
	if ($self->{error}) {
		warn('Mail-Cache init: setAccount failed');
		return undef;
	}

	$self->setBox($box);
	if ($self->{error}) {
		warn('Mail-Cache init: setBox failed');
		return undef;
	}

	return 1;
}

=head2 listUIDs

This gets a list of UIDs.

    my @uids=$mc->listUIDs;
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub listUIDs{
	my $self=$_[0];

	$self->errorblank;

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$self->{box}.'/';

	if (! -e $dir) {
		$self->{error}=15;
		$self->{errorString}='"'.$dir.'" does not exist';
		warn('Mail-Cache listUIDs:15: '.$self->{errorString});
		return undef;
	}

	opendir(LISTUIDS, $dir);
	my @uids=grep(!/^\./, readdir(LISTUIDS));
	closedir(LISTUIDS);

	return @uids;
}

=head2 removeUIDs

This removes a array of specified UIDs. This is used for cleaning it up.
See Mail::IMAPTalk::MailCache for a example of how to use this.

    $mc->removeUIDs(\@uids);

=cut

sub removeUIDs{
	my $self=$_[0];
	my @uids;
	if (defined($_[1])) {
		@uids=@{$_[1]};
	}

	$self->errorblank;

	#if nothing is given, no reason to go ahead with the rest
	if (!defined($uids[0])) {
		return 1;
	}

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
        	$self->{account}.'/'.$self->{box}.'/';

	#gets the subject cache
	open(SUBJECTREAD, '<', $dir.'/.Subject');
	my @subjectcache=<SUBJECTREAD>;
	close(SUBJECTREAD);

	#gets the from cache
	open(FROMREAD, '<', $dir.'/.From');
	my @fromcache=<FROMREAD>;
	close(FROMREAD);

	#gets the date cache
	open(DATEREAD, '<', $dir.'/.Date');
	my @datecache=<DATEREAD>;
	close(DATEREAD);

	#get the size cache
	open(SIZEREAD, '<', $dir.'/.size');
	my @sizecache=<SIZEREAD>;
	close(SIZEREAD);

	#process each one
	my $int=0;
	while (defined($uids[$int])) {
		my $uid=$uids[$int];

		my $process=1;

		if ($uid=~/^\./) {
			$process=0;
		}

		if ($uid=~/\//) {
			$process=0;
		}

		if ($uid=~/\\/) {
			$process=0;
		}

		#should never start with a . or match /
		if ($process) {
			#remove the old subject
			my $subjectremove='^'.quotemeta($uid).'\|';
			@subjectcache=grep(!/$subjectremove/, @subjectcache);
			
			#remove the old from
			my $fromremove='^'.quotemeta($uid).'\|';
			@fromcache=grep(!/$fromremove/, @subjectcache);
			
			#removes the old date
			my $dateremove='^'.quotemeta($uid).'\|';
			@datecache=grep(!/$dateremove/, @datecache);
			
			#removes the old size
			my $sizeremove='^'.quotemeta($uid).'\|';
			@sizecache=grep(!/$sizeremove/, @sizecache);

			#remove the header file if it exists
			if (-f $dir.'/'.$uid) {
				unlink($dir.'/'.$uid);
			}
		}

		$int++;
	}

	#write the subject info out
	open(SUBJECTWRITE, '>', $dir.'/.Subject');
	print SUBJECTWRITE join('', @subjectcache);
	close(SUBJECTWRITE);

	#write the from cache
	open(FROMWRITE, '>', $dir.'/.From');
	print FROMWRITE join('', @fromcache);
	close(FROMWRITE);

	#write the date cache
	open(DATEWRITE, '>', $dir.'/.Date');
	print DATEWRITE join('', @datecache);
	close(DATEWRITE);

	#write the size cache
	open(SIZEWRITE, '>', $dir.'/.size');
	print SIZEWRITE join('', @sizecache);
	close(SIZEWRITE);

	return 1;
}

=head2 setAccount

This sets the account that is currently being worked on. The
default is 'default'.

A value of '' or undef will set it back to the default.

=cut

sub setAccount{
	my $self=$_[0];
	my $account=$_[1];

	$self->errorblank;

	#handles resetting it if needed
	if (!defined($account)) {
		$account='default';
	}
	if ($account eq '') {
		$account='default'
	}

	#make sure it does not contain a '/'
	if ($account=~/\//) {
		$self->{error}=6;
		$self->{errorString}='Account name, "'.$account.'", contains a "/"';
		warn('Mail-Cache setAccount:6: '.$self->{errorString});
		return undef;
	}

	#attempts to create it if it does not exist
	my $dir=$self->{home}.$self->{cache}.'/'.$self->{type}.'/'.$account.'/';
	if (! -e $dir) {
		if (!mkdir($dir)){
			$self->{error}=7;
			$self->{errorString}='Faile to create the cache, "'.$dir.'/"';
			warn('Mail-Cache setAccount:7: '.$self->{errorString});
			return undef;
		}
	}

	$self->{account}=$account;

	return 1;
}

=head2 setBox

This sets the current box in use.

A value of '' or undef will set it back to the default,
'INBOX'.

=cut

sub setBox{
	my $self=$_[0];
	my $box=$_[1];

	$self->errorblank;


	#handles resetting it if needed
	if (!defined($box)) {
		$box='INBOX';
	}
	if ($box eq '') {
		$box='INBOX';
	}

	#make sure it does not contain a '/'
	if ($box=~/\//) {
		$self->{error}=13;
		$self->{errorString}='Box name, "'.$box.'", contains a "/"';
		warn('Mail-Cache setBox:13: '.$self->{errorString});
		return undef;
	}

	#attempts to create it if it does not exist
	my $dir=$self->{home}.$self->{cache}.'/'.$self->{type}.'/'.
	        $self->{account}.'/'.$box.'/';
	if (! -e $dir) {
		if (!mkdir($dir)){
			$self->{error}=14;
			$self->{errorString}='Faile to create the box, "'.$dir.'/"';
			warn('Mail-Cache setBox:14: '.$self->{errorString});
			return undef;
		}
	}

	if (! -e $dir.'/.Date') {
		open(CREATEDATE, '>', $dir.'/.Date');
		print CREATEDATE '';
		close(CREATEDATE);
	}
	if (! -e $dir.'/.From') {
		open(CREATEFROM, '>', $dir.'/.From');
		print CREATEFROM '';
		close(CREATEFROM);
	}
	if (! -e $dir.'/.Subject') {
		open(CREATESUBJECT, '>', $dir.'/.Subject');
		print CREATESUBJECT '';
		close(CREATESUBJECT);
	}
	if (! -e $dir.'/.size') {
		open(CREATESIZE, '>', $dir.'/.size');
		print CREATESIZE '';
		close(CREATESIZE);
	}

	$self->{box}=$box;

	return 1;
}

=head2 setCache

This sets the name cache.

A value of '' or undef will set it back to the default,
'Mail::Cache'.

    #set the cache name to ZConf::Mail
    $mc->setCache('ZConf::Mail');
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub setCache{
	my $self=$_[0];
	my $cache=$_[1];

	$self->errorblank;

	#handles resettting it if needed
	if (!defined($cache)) {
		$cache='Mail::Cache';
	}
	if ($cache eq '') {
		$cache='Mail::Cache';
	}

	#make sure it does not contain a '/'
	if ($cache=~/\//) {
		$self->{error}=3;
		$self->{errorString}='Cache name, "'.$cache.'", contains a "/"';
		warn('Mail-Cache setCache:3: '.$self->{errorString});
		return undef;
	}

	#attempts to create it if it does not exist
	if (! -e $self->{home}.$cache) {
		if (!mkdir($self->{home}.$cache)){
			$self->{error}=4;
			$self->{errorString}='Faile to create the cache, "'.$self->{home}.$cache.'/"';
			warn('Mail-Cache setCache:4: '.$self->{errorString});
			return undef;
		}
	}

	$self->{cache}=$cache;

	return 1;
}

=head2 setType

This sets what source of what is being cached. The default is 'imap'.

Regardless of what it is set to, it will be converted to lower case.

A value of '' or undef will set it back to the default.

    $mc->setType('imap');
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub setType{
	my $self=$_[0];
	my $type=$_[1];

	$self->errorblank;

	#handles resetting it if needed
	if (!defined($type)) {
		$type='imap';
	}
	if ($type eq '') {
		$type='imap'
	}

	#make sure we have it in lower case
	$type=lc($type);

	#make sure it does not contain a '/'
	if ($type=~/\//) {
		$self->{error}=5;
		$self->{errorString}='Type name, "'.$type.'", contains a "/"';
		warn('Mail-Cache setType:5: '.$self->{errorString});
		return undef;
	}

	#attempts to create it if it does not exist
	my $dir=$self->{home}.$self->{cache}.'/'.$type;
	if (! -e $dir) {
		if (!mkdir($dir)){
			$self->{error}=4;
			$self->{errorString}='Faile to create the cache, "'.$dir.'/"';
			warn('Mail-Cache setType:4: '.$self->{errorString});
			return undef;
		}
	}

	$self->{type}=$type;

	return 1;
}

=head2 setUID

This sets the cache for a message. If it does not already exist, it will be
added. If it does exist, it will be overwritten.

    $mc->setUID($uid, $headers, $size);
    if($mc->{error}){
        print "Error!\n";
    }

=cut

sub setUID{
	my $self=$_[0];
	my $uid=$_[1];
	my $headers=$_[2];
	my $size=$_[3];

	$self->errorblank;

	#make sure we have everything :)
	if (!defined($uid)) {
		$self->{error}=8;
		$self->{errorString}='No UID specified';
		warn('Mail-Cache setUID:8: '.$self->{errorString});
		return undef;
	}
	if (!defined($headers)) {
		$self->{error}=10;
		$self->{errorString}='No headers specified';
		warn('Mail-Cache setUID:10: '.$self->{errorString});
		return undef;
	}
	if (!defined($size)) {
		$self->{error}=11;
		$self->{errorString}='No UID specified';
		warn('Mail-Cache setUID:11: '.$self->{errorString});
		return undef;
	}

	#a UID should be just numberic and should definitely not begin with a /^\./ or /\|/
	if ($uid =~ /^\./) {
		$self->{error}=9;
		$self->{errorString}='The UID matches /^\./';
		warn('Mail-Cache setUID:9: '.$self->{errorString});
		return undef;
	}
	if ($uid =~ /^\|/) {
		$self->{error}=12;
		$self->{errorString}='The UID matches /^\|/';
		warn('Mail-Cache setUID:12: '.$self->{errorString});
		return undef;
	}

	my $es=Email::Simple->new($headers);

	my $subject=$es->header('Subject');
	if (!defined($subject)) {
		$subject='';
	}

	my $from=$es->header('From');
	if (!defined($from)) {
		$from='';
	}

	my $date=$es->header('Date');
	if (!defined($date)) {
		$date='';
	}

	my $dir=$self->{home}.'/'.$self->{cache}.'/'.$self->{type}.'/'.
            $self->{account}.'/'.$self->{box}.'/';

	#handles reading the subject cache removing any old entries and readding it
	my $subjectline=$uid.'|'.$subject."\n";
	my $subjectremove='^'.quotemeta($uid).'\|';
	open(SUBJECTREAD, '<', $dir.'/.Subject');
	my @subjectcache=grep(!/$subjectremove/, <SUBJECTREAD>);
	close(SUBJECTREAD);
	push(@subjectcache, $subjectline);
	open(SUBJECTWRITE, '>', $dir.'/.Subject');
	print SUBJECTWRITE join('', @subjectcache);
	close(SUBJECTWRITE);

	#handles reading the from cache reming any old entries and readding it
	my $fromline=$uid.'|'.$from."\n";
	my $fromremove='^'.quotemeta($uid).'\|';
	open(FROMREAD, '<', $dir.'/.From');
	my @fromcache=grep(!/$fromremove/, <FROMREAD>);
	close(FROMREAD);
	push(@fromcache, $fromline);
	open(FROMWRITE, '>', $dir.'/.From');
	print FROMWRITE join('', @fromcache);
	close(FROMWRITE);

	#handles reading the date cache reming any old entries and readding it
	my $dateline=$uid.'|'.$date."\n";
	my $dateremove='^'.quotemeta($uid).'\|';
	open(DATEREAD, '<', $dir.'/.Date');
	my @datecache=grep(!/$dateremove/, <DATEREAD>);
	close(DATEREAD);
	push(@datecache, $dateline);
	open(DATEWRITE, '>', $dir.'/.Date');
	print DATEWRITE join('', @datecache);
	close(DATEWRITE);

	#handles reading the date cache reming any old entries and readding it
	my $sizeline=$uid.'|'.$size."\n";
	my $sizeremove='^'.quotemeta($uid).'\|';
	open(SIZEREAD, '<', $dir.'/.size');
	my @sizecache=grep(!/$sizeremove/, <SIZEREAD>);
	close(SIZEREAD);
	push(@sizecache, $sizeline);
	open(SIZEWRITE, '>', $dir.'/.size');
	print SIZEWRITE join('', @sizecache);
	close(SIZEWRITE);

	#writes the headers to a file
	open(HEADERWRITE, '>', $dir.'/'.$uid);
	print HEADERWRITE $headers;
	close(HEADERWRITE);

	return 1;
}

=head2 errorblank

A internal functions that blanks any previous error.

=cut

sub errorblank{
	$_[0]->{error}=undef;
	$_[0]->{errorString}='';
}

=head1 CACHE LAYOUT

The cache exists under "xdg_cache_home.'/Mail::Cache/'". So the default
location would be "~/.cache/Mail::Cache/".

Under the cache home directory is the directories representing various caches.
If none is specified it is 'Mail::Cache'. This would make the directory,
"xdg_cache_home.'/Mail::Cache/Mail::Cache/'".

Under the cache directory is the type directory. The type should also always
be lower case. Any upper case characters will be converted to lowercase. The
default is 'imap', making the directory
"xdg_cache_home.'/Mail::Cache/Mail::Cache/imap/'".

Under the account directory is the type directory. The default is 'default',
making the directory "xdg_cache_home.'/Mail::Cache/Mail::Cache/imap/default/'".

Under the box directory is the account directory. The default is 'INBOX',
making the directory
"xdg_cache_home.'/Mail::Cache/Mail::Cache/imap/default/INBOX/'".

=head1 ERROR CODES

The error codes are stored in '$mc->{error}'. Any time it is true, an error is present. When
no error is present, it is undefined.

A description of the error can be found in '$mc->{errorString}'.

=head2 1

Could not create xdg_cache_home.

=head2 2

Could not create xdg_cache_home.'/Mail::Cache/'.

=head2 3

Cache name contains a '/'.

=head2 4

Failed to create xdg_cache_home.'/'.$cache.'/'.

=head2 5

Type contains a '/'.

=head2 6

Account contains a '/'.

=head2 7

Failed to create create xdg_cache_home.'/'.$cache.'/'.$account.'/'.

=head2 8

No UID specified.

=head2 9

UID matches /^\./.

=head2 10

No headers given.

=head2 11

Size is not specified.

=head2 12

UID matches /\|/.

=head2 13

Box name matches /\//.

=head2 14

Failed to create create xdg_cache_home.'/'.$cache.'/'.$account.'/'.$box.'/'.

=head2 15

"xdg_cache_home.'/'.$cache.'/'.$account.'/'.$box.'/'" does not exist.

=head2 16

"xdg_cache_home.'/'.$cache.'/'.$account.'/'.$box.'/.Size'"  does not exist.

=head2 17

The passed value for the headers was something other than a reference or a hash.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-cache at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-Cache>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::Cache


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-Cache>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-Cache>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-Cache>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-Cache/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mail::Cache

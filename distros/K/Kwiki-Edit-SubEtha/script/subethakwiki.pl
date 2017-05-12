#!/usr/bin/perl

# Kwiki <=> SubEthaEdit Bridge
# cf. http://www.apple.com/applescript/uiscripting/03.html

use FindBin;
use strict;
use constant TTL	=> 180;	# 3 mins time-to-live
use constant REFRESH	=> 15;	# push back every 15 secs
#use constant REPOS	=> 'file:///Users/subethakwiki/see/svn';
use constant REPOS	=> 'svn+ssh://www@blogs/home/ingy/kwiki.org/see/plugin/archive';

chdir $FindBin::Bin;
system("rm -rf repos");
system("svn co -r 0 ".+REPOS." repos");
system("killall SubEthaEdit");

# XXX - use applescript to set pref to UTF8 here!
system("open /Applications/SubEthaEdit.app");

chdir "$FindBin::Bin/repos";

my %ttl;
while (1) {
    system("osascript -e 'save documents of application \"SubEthaEdit\"'");
    system("svn cleanup");

    my @new = map { m{^A\s+edits/(.+)} ? $1 : () } `svn up`;
    if (@new) {
	print "New: @new\n" if @new;
	chdir "$FindBin::Bin/repos/pages";
	open_see(@new);
	chdir "$FindBin::Bin/repos";
    }

    my @lines = `svn ci -m autocommit`;
    my @modified = map { m{^Sending\s+pages/(.+)} ? $1 : () } @lines;

    if (@modified) {
	print "Modified: @modified\n";
    }

    $ttl{$_}++ foreach keys %ttl;
    @ttl{@new, @modified} = ();

    if ( my @expired = grep { ($ttl{$_} * REFRESH) >= TTL } keys %ttl ) {
	print "Expired: @expired\n";

	system("svn rm " . join(' ', map "edits/$_", @expired));
        chdir "$FindBin::Bin/repos/pages";
	close_see(@expired);
        chdir "$FindBin::Bin/repos";
	system("svn ci -m autocommit");
	delete @ttl{@expired};
    }

    sleep REFRESH;
}

sub open_see {
    system("open -a SubEthaEdit " . join(' ', map $_, @_));
    tell_see(map qq{
      click menu item "$_" of menu "Window"
      try
        click menu item "Announce" of menu "File"
        tell menu bar item "File"
          tell menu "File"
            tell menu item "Access Control"
              tell menu "Access Control"
                click menu item "Read/Write"
              end tell
            end tell
          end tell
        end tell
      end try
    }, @_);
}

sub close_see {
    tell_see(map qq{
      click menu item "$_" of menu "Window"
      try
        click menu item "Conceal" of menu "File"
        click menu item "Close" of menu "File"
      end try
    }, @_);
}

sub tell_see {
    open ETHA, ">$FindBin::Bin/script.osa" or die $!;
    print ETHA << ".";
tell application "SubEthaEdit"
  activate
  save documents
end tell
tell application "System Events"
  tell process "SubEthaEdit"
    tell menu bar 1
      @_
    end tell
  end tell
end tell
.
    close ETHA;
    system("osascript $FindBin::Bin/script.osa");
}


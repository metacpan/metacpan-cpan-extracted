#!/usr/bin/perl 

use strict;
use warnings;
require CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use ConfigPathes;
use DataAccess;
use DBI;
require Dotiac::DTL;

#Init CGI
my $cgi=new CGI;



my $dbh=$DataAccess::dbh;
$dbh->{FetchHashKeyName} = 'NAME_lc';

#Check if the tables exist.
my %tables;
my $tablesth = $dbh->table_info("","","","TABLE");
if ($tablesth) {
	while (my $table = $tablesth->fetchrow_arrayref("NAME_lc")) {
		$tables{$table->[2]}=1;
	}
}

#Generate tables if they don't exists.
$dbh->do("CREATE TABLE blog_entry (id INTEGER, date INTEGER , title CHAR(250), author CHAR(64) , content BLOB )") unless ($tables{blog_entry});
$dbh->do("CREATE TABLE blog_comments (id INTEGER, entry INTEGER, date INTEGER , author CHAR(200), mail CHAR(200) , content BLOB )") unless ($tables{blog_comments});


my $action=$cgi->param("action") || "";

if ($action eq "post") {
	#To make a new post

	if ($cgi->param("title") and $cgi->param("author") and $cgi->param("content")) {
		my $next=$dbh->selectrow_arrayref("SELECT MAX(id) FROM blog_entry");
		$next=$next->[0]+1;
		$dbh->do("INSERT INTO blog_entry (id, date, title, author, content) VALUES (?, ?, ?, ?, ?)",{},$next,time,$cgi->param("title"),$cgi->param("author"),$cgi->param("content"));
		print $cgi->redirect($cgi->url(-relative=>1)."?action=refresh&url=".$cgi->escape($cgi->url(-relative=>1)));
	}
	else {
		print $cgi->header();
		Dotiac::DTL->new(ConfigPathes::template("blog_new.html"))->print({ #get it and render it.
			cgi=>scalar($cgi->Vars), #All cgi variables, the template might need it.
			base_url=>"blog.pl", #This makes the templates reuseable.
			action=>"post"	#Also to make it reuseable
		});
	}
}
elsif ($action eq "view") {
	# Detailview of an entry with all the comments
	my $id=int($cgi->param("id")||0);
	my $entry = $dbh->selectrow_hashref("SELECT * FROM blog_entry WHERE id=? ORDER BY date DESC LIMIT",{},$id); #Get the data for that entry
	unless ($entry and %$entry) {
		print $cgi->header();
		Dotiac::DTL->new(ConfigPathes::template("blog_error.html"))->print({
					message=>"Unknown post",
					base_url=>"blog.pl"
				});
	}

	if ($cgi->param("author") and $cgi->param("content")) {
		my $next=$dbh->selectrow_arrayref("SELECT MAX(id) FROM blog_comments");
		$next=$next->[0]+1;
		#die $cgi->param("content");
		$dbh->do("INSERT INTO blog_comments (id, entry, date, author, mail, content) VALUES (?, ?, ?, ?, ?, ?)",{},$next,$id,time,$cgi->param("author"),($cgi->param("mail")||""),$cgi->param("content"));
		print $cgi->redirect($cgi->url(-relative=>1)."?action=refresh&url=".$cgi->escape($cgi->url(-relative=>1)."?id=$id&action=view"));
	}
	else {
		print $cgi->header();
		
		
		Dotiac::DTL->new(ConfigPathes::template("blog_view.html"))->print({ #get it and render it.
				cgi=>scalar($cgi->Vars), #All cgi variables, the template might need it.
				entry=>$entry,
				comments=>$dbh->selectall_arrayref("SELECT * FROM blog_comments WHERE entry = ? ORDER BY date DESC", {Slice=>{}}, $id), #Get the comments
				base_url=>"blog.pl", #This makes the templates reuseable.
				action=>"view"	#Also to make it reuseable
			});
	}
}
elsif ($action eq "delete_comment") {
	my $id=int($cgi->param("id")||0);
	$dbh->do("DELETE FROM blog_comments WHERE id = ?",{},$id);
	print $cgi->redirect($cgi->url(-relative=>1)."?action=refresh&url=".$cgi->escape($cgi->url(-relative=>1)."?id=$id&action=view"));
}
elsif ($action eq "refresh") {
	# Meta-refresh so the browser doesn't resend POST data on F5
	print $cgi->header();
	Dotiac::DTL->new(ConfigPathes::template("redirect.html"))->print({ #get it and render it.
			url=>($cgi->param("url") || $cgi->url(-relative=>1))
		});
}
else { #The normal overview page.
	print $cgi->header();

	#The current page the user is on
	my $page=int($cgi->param("page") || 0);

	#Get the data for the blog,
	my $blog = $dbh->selectall_arrayref("SELECT * FROM blog_entry ORDER BY date DESC LIMIT ". $page*10 .", ".($page*10+10), {Slice=>{}}); #Get the data for the blog

	# Get the comments for each entry: This is slow, but short. Join's would be better, but not every dbd driver supports those, sadly
	foreach my $e (@$blog) {
		$e->{comments}=$dbh->selectall_arrayref("SELECT id FROM blog_comments WHERE entry = ? ORDER BY date DESC ",{Slice=>{}},$e->{id}); #Get only the comment id, just for counting, the rest is useless in the overview.
	}
	
	#die Data::Dumper->Dump([$blog]);
	#Find out how many entries are there:
	my $count=$dbh->selectrow_arrayref("SELECT COUNT(*) FROM blog_entry");
	$count=$count->[0];
	#Get the amount of pages:
	my $pages=int(($count-1)/10); #0: 1 page, 1: 2 pages...
	if ($count == 0) { #No data at all
		Dotiac::DTL->new(ConfigPathes::template("blog_error.html"))->print({
				message=>"There are no entries in this blog",
				base_url=>"blog.pl"
			});
	}
	Dotiac::DTL->new(ConfigPathes::template("blog.html"))->print({ #get it and render it.
			cgi=>scalar($cgi->Vars), #All cgi variables, the template might need it.
			blog=>$blog,
			entry_count=>$count,
			page=>$page,
			pages=>$pages,
			base_url=>"blog.pl" #This makes the templates reuseable.
		});
}

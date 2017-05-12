package Kwiki::Comments;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use DBI;

our $VERSION = '0.06';

const class_id => 'comments';
const class_title => 'Kwiki Comments';
const cgi_class => 'Kwiki::Comments::CGI';
const css_file => 'comments.css';

sub register {
    my $registry = shift;
    $registry->add( action => 'comments' );
    $registry->add( action => 'comments_post' );
    $registry->add( wafl => comments => 'Kwiki::Comments::Wafl' );
}

sub dbinit {
    my $db = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",
			   { RaiseError => 1, AutoCommit => 1 });
    $dbh->do('CREATE TABLE comments (author,email,url,text)');
    $dbh->disconnect;
}

sub dbpath {
    my $page_id = $self->cgi->page_id || $self->pages->current_id;
    my $path = $self->plugin_directory;
    my $filename =  io->catfile($path,"$page_id.sqlt")->name;
    $self->dbinit($filename) unless -f $filename;
    return $filename;
}

sub db_connect {
    my $db  = $self->dbpath;
    DBI->connect("dbi:SQLite:dbname=$db","","",
                 { RaiseError => 1, AutoCommit => 1 });
}

sub load_comments {
    my @comments;
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare("SELECT * FROM comments");
    $sth->execute;
    while(my $data = $sth->fetchrow_hashref) {
	push @comments, $data;
    }
    $sth->finish;
    $dbh->disconnect;
    return \@comments;
}

sub add_comment {
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare("INSERT INTO comments values(?,?,?,?)");
    $sth->execute(@_);
    $sth->finish;
    $dbh->disconnect;
}

sub comments_post {
    my $cgi = $self->cgi;
    my $page_id = $cgi->page_id;
    $self->add_comment($cgi->author, $cgi->email, $cgi->url, $cgi->text);
    $self->redirect($page_id);
}

sub comments {
    $self->template_process('comments_form.html');
}

package Kwiki::Comments::Wafl;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my $friend = $self->hub->comments;
    my $content = $friend->template->process(
        'comments_display.html',comments => $friend->load_comments
       ) . $friend->template_process('comments_form.html');
}

package Kwiki::Comments::CGI;
use Kwiki::CGI '-base';

cgi 'author' => qw(-utf8);
cgi 'email';
cgi 'url';
cgi 'text' => qw(-utf8 -newlines);
cgi 'page_id';

package Kwiki::Comments;
__DATA__
=head1 NAME

Kwiki::Comments - Post comments to a page

=head1 DESCRIPTION

B<Kwiki::Comments> is a L<Kwiki> plugin that allow anyone to leave
comments to a Page, just like Slash comments or MT comments. To use
this plugin, simply install L<Kwiki>, and this module from CPAN, and
do:

    # echo 'Kwiki::Comments' >> plugins
    # kwiki -update

Currently you'll need to have L<DBD::SQLite> module installed to use
this module. Maybe in the future, we can support more kinds of database
back-end.

And now your site is ready to have comments. But, comments
are not shown automatically. You'll have to append this line:

    {comments}

To whatever pages that are allow comment.

The basic idea is that, some wiki pages can be protected, only admin
can edit them. On those protected pages, comments becomes the only way
for anybody to give feedbacks, but sometimes you don't even want a
feedback. That's why you'll need to clearly specify if you want
a comment form attach to the page, or not.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
__css/comments.css__
.comments-body {
	font-family:verdana, arial, sans-serif;
	color:#666;
	font-size:small;
	line-height:140%;
	padding-bottom:10px;
	padding-top:10px;
	border-bottom:1px dotted #999;
}
__template/tt2/comments_display.html__
<!-- BEGIN comments_display.html -->
<hr />
<div class="comments-display">
[% FOR post = comments %]
[% IF post.url %]
[% link = post.url %]
[% ELSIF post.email %]
[% link = "mailto:${post.email}" %]
[% ELSE %]
[% link = '' %]
[% END %]
<div class="comments-body">
<p>[% post.text %]</p>
<span class="comments-post">Posted by
[% IF link %]
    <a href="[% link %]">[% post.author%]</a>
[% ELSE %]
    [% post.author %]
[% END %]
</span>
</div>
[% END %]
</div>
<!-- END comments_display.html -->
__template/tt2/comments_form.html__
<!-- BEGIN comments_form.html -->
<hr />
<div class="comments-form">
<div class="comments-head">Post a comment</div>
<div class="comments-body">
<form method="post" action="[% script_name %]" name="comments_form">
<input type="hidden" name="action" value="comments_post" />
<input type="hidden" name="page_id" value="[% hub.pages.current_id %]" />
<label for="author">Name:</label><br />
<input id="author" name="author" /><br /><br />
<label for="email">Email Address:</label><br />
<input id="email" name="email" /><br /><br />
<label for="url">URL:</label><br />
<input id="url" name="url" /><br /><br />
<label for="text">Comments:</label><br />
<textarea id="text" name="text" rows="10" cols="50"></textarea><br /><br />
<input type="submit" id="submit" name="submit" />
</div>
</div>
<!-- END comments_form.html -->

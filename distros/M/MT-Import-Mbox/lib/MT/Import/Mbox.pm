# $Id: Mbox.pm,v 1.13 2005/12/03 19:10:27 asc Exp $
use strict;

package MT::Import::Mbox;
use base qw (MT::Import::Base);

$MT::Import::Mbox::VERSION = '1.01';

=head1 NAME

MT::Import::Mbox - import one or more mbox messages in to a Movable Type weblog

=head1 SYNOPSIS

 use strict;
 use MT::Import::Mbox;

 my $cfg = Config::Simple->new("/path/to/mbox.cfg");
 my $mt = MT::Import::Mbox->new($cfg);
 $mt->verbose(1);

 $mt->import_mbox("/path/to/mbox");
 $mt->rebuild();

=head1 DESCRIPTION

Import one or more mbox messages in to a Movable Type weblog.

=head1 MOTIVATION

I keep my email in a dated (YYYY/MM/DD) space. In a world where every
other way of organizing email messages kind of sucks, this one doesn't
necessarily suck any less but at least it's consistent.

The downside to doing things this way is that there aren't any email
clients that are capable of doing multi-folder searches. When I need
to find something I am reduced to using tools like grep which, despite
having a certain charm, is pretty painful.

Movable Type, with its built-in search and trackback widget seemed like
an interesting way to create a threaded read-only archive of my mail. I
could have built something from scratch (and I have) but MT was most
of the puzzle already completed.

The idea of using tags and comments for annotating an email was also
intriguing. Using custom X-headers to tag an email from Ted as "asshole"
is great until you need to reply to that message and forget to purge 
your personal notes.

Also I was curious to see if, and how, it could be done and I hadn't played
with the MT source in a couple years. 

=head1 EMAIL TO MT MAPPINGS

=over 4

=item * B<Threads>

Message threads are handled using Movable Type's trackback features.

=item * B<Authors>

Normalized email addresses are treated as Movable Type authors and
added to the database, as need.

=item * B<Categories>

Normalized email addresses are treated as the primary category for
a message/post. The message's 'directional' headers for are treated
as the secondary category. For example :

 + foo@example.com

   - From
   - Cc

=item * B<Attachments>

Multi-part MIME attachments are parsed using the Email::MIME package. In the
event that no attachments are found it returns the body of the orginal message
as a 'part', or attachment.

If only one attachment exists it is used to generate the body of the entry.

If the first attachment content-type is determined to be either plain-text 
or HTML it is used to generate the body of the entry.

All other attachments are written to disk. Attachments are written to disk as :

 /your/static/weblog/attachments/$YYYY/$MM/$DD/$MSG_ID/$FNAME

$YYYY is the four digit year for the message as determined by its 'Date' header.
$MM and $DD the two digit month and day respectively.

$MSG_ID is an MD5 digest of a normalized form of the message's Message-ID
header.

$FNAME is an MD5 digest of the attachment's body. If it is possible to 
determine the attachment's content-type then a suitable extension is
appended to $FNAME.

A messsage's headers are stored as a separate attachment in :

 /your/static/weblog/attachments/$YYYY/$MM/$DD/$MSG_ID/headers.txt

=back

=head1 SETUP

=head2 Versioning

This package is designed to be used with Movable Type 3.2

=head2 Templates

=over 4

=item * B<Master Archive Index> template.

You will need to copy and paste, or link to, the custom version
of this file located in :

 /path/to/MT-Import-Mbox-1.01/templates/archives.html

=item * B<Daily Archive> template

Ensure that it is enabled.

You will need to copy and paste, or link to, the custom version
of this file located in :

 /path/to/MT-Import-Mbox-1.01/templates/date-based-archive.html

=item * B<Monthly Archive> template

Ensure that it is enabled.

You will need to copy and paste, or link to, the custom version
of this file located in :

 /path/to/MT-Import-Mbox-1.01/templates/date-based-archive-monthly.html

=item * B<Category Archive> template

Ensure that it is enabled.

=item * B<Individual Entry Archive> template

You will need to copy and paste, or link to, the custom version
of this file located in :

 /path/to/MT-Import-Mbox-1.01/templates/individual-entry-archive.html

=back

I<Future releases may try to automate this process.>

=head2 Plugins

In order to rebuild your templates with bi-directional trackback
threading, you will need to install the B<MTPingUrls> plugin.

 cp /path/to/MT-Import-Mbox-1.01/plugins/pinged-by-entry \
    /path/to/your/cgi-bin/mt/plugins/

I<Future releases may try to automate this process.>

=head2 Permissions

Ensure that your MT installation is configured to allow both the
default CGI scripts B<and> the scripts using this library sufficient
permissions to create an modify files in your (MT) static archive.

=cut

use Digest::MD5 qw (md5_hex);

use Email::Folder;
use Email::Find;
use Email::MIME;

use File::Find::Rule;
use File::Temp qw (:POSIX);

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new()

=head1 CONFIG OPTIONS

=head2 mt

=over 4

=item * B<root>

String. I<required>

The path to your Movable Type installation.

=item * B<blog_id>

Int. I<required>

The numberic ID of the Movable Type weblog you are posting to.

=item * B<blog_ownerid>

Int. I<required>

The numberic ID of a Movable Type author with permissions to add
new authors to the Movable Type weblog you are posting to.

=item * B<author_password>

String.

The password to assign to any new authors you add to the Movable Type
weblog you are posting to.

Default is "I<none>".

=item * B<author_permissions>

Int.

The permissions set to grant any new authors you add to the Movable Type
weblog you are posting to.

Default is I<514>, or the ability to add new categories.

=back

=head2 importer

=over 4

=item * B<force>

Boolean.

Force a message to be reindexed, including any trackback pings and
attachments. If an entry matching the message id already exists in the
database it should only ever update or overwrite I<existing> data.

Default is I<false>

=item * B<verbose>

Boolean.

Enabled verbose logging.

Default is I<false>

=back

=head2 email

=over 4

=item * B<personal>

A comma-separated list of email addresses that when present in the B<From>
header will cause a message/post's primary category to be set as I<Sent>
rather than I<Received>

=back

=cut

# Defined in MT::Import::Base

sub init {
        my $self = shift;

        if (! $self->SUPER::init(@_)) {
                return 0;
        }

        my @personal = $self->{cfg}->param("email.personal");
        $self->{'__personal'} = \@personal;
        
        return 1;
}

=head1 OBJECT METHODS (you should care about)

=cut

=head2 $obj->import_mbox($path_to_mbox,%args)

Where I<%args> are whatever valid parameters you can pass to
the I<Email::Folder::Mbox> object constructor.

=cut

sub import_mbox {
        my $self = shift;
        my $mbox = shift;
        
        my $folder = Email::Folder->new($mbox,@_);
        
        while (my $msg = $folder->next_message()) {
                $self->import_msg($msg);
        }
        
        return 1;
}

=head2 $obj->import_msg(Email::Simple)

Returns an I<MT::Entry> object.

=cut

sub import_msg () {
        my $self = shift;
        my $msg  = shift;
        
        #
        
        my $msg_id = $self->mk_id($msg->header("Message-Id"));  
        
        my $entry = MT::Entry->load({blog_id  => $self->blog_id(),
                                     basename => $msg_id});
			     
        if (($entry) && (! $self->{cfg}->param("importer.force"))) {
                $self->log()->notice(sprintf("message %s already exists in the database with ID %d, skipping",
                                             $msg_id,$entry->id()));
                
                # FIX ME : rebuild?
                $self->imported($entry->id());
                return 1;
        }

        #

        my $reply  = $self->mk_id($msg->header("In-Reply-To"));

        my $author = $msg->header("From");
        my $first  = ($self->find_addrs($author))[0];

        $author    = $self->mk_author($first,$first);

        $entry ||= MT::Entry->new();
        $entry->title($msg->header("Subject"));

        my $parsed = Email::MIME->new($msg->as_string());
        my @parts  = $parsed->parts();

        #
        
        if (scalar(@parts)==1) {
                my $txt = $parts[0]->body();
                $txt .= $self->mk_head($msg);
                $self->set_entry_text($entry,$txt);
        }
        
        elsif ($self->mk_extension($parts[0]->content_type()) =~ /^(txt|html)$/) {
                my $first = shift @parts;
                
                my $txt = $first->body();
                $txt .= $self->mk_uploads_text($msg,@parts);
                $txt .= $self->mk_head($msg);

                $self->set_entry_text($entry,$txt);                
        }

        else {
                my $txt = $self->mk_uploads_text($msg,@parts);
                $txt   .= $self->mk_head($msg);
                
                $self->set_entry_text($entry,$txt);
        }

        #

        $entry->author_id($author->id());
        $entry->blog_id($self->blog_id());
    
        $entry->allow_pings(1);
        $entry->created_on($self->mk_date($msg->header("Date")));
    
        $entry->previous(1);
        $entry->next(1);
        
        $entry->basename($msg_id);
        $entry->status(MT::Entry::RELEASE());

        if (! $entry->save()) {
                $self->log()->error("Can't save entry for message $msg_id, $!");
                return 0;
        }
        
        $self->log()->info(sprintf("Created entry %d for message %s\n",
                                   $entry->id(),$msg_id));

        #

        my $tb = MT::Trackback->load({entry_id=>$entry->id()});

        if (! $tb) {
                $tb = MT::Trackback->new();
                $tb->blog_id($entry->blog_id());
                $tb->entry_id($entry->id());
                $tb->category_id(0);
                $tb->title($entry->title());
                $tb->description($entry->get_excerpt());
                $tb->url($entry->permalink());
                $tb->is_disabled(0);
                
                if (! $tb->save()) {
                        $self->log()->error("can not save trackback!, $!");
                }
        }
        
        #

        my $blog = MT::Blog->load($self->blog_id());
        $blog->touch();
        
        if (! $blog->save()) {
                $self->log()->error("Can't save , $!");
                return 0;
        }

        #

        my $from = $author->name();
        my $pri  = ($self->is_personal_address($from)) ? "Sent" : "Received";

        my $categories = $self->mk_categories($msg);
        
        if (scalar(@$categories)) {
                $pri = $self->mk_category($pri,0);
                $self->place_category($entry,$pri,1);

                foreach my $c (@$categories) {
                        $self->place_category($entry,$c,0);
                }
        }

        if ($reply) {
                $self->ping_for_reply($entry,$reply,$msg->header("From"));
        }
        
        #
        
        $self->imported($entry->id());
        return $entry;
}

sub is_personal_address {
        my $self = shift;
        my $addr = shift;

        return (grep /^$addr$/, @{$self->{'__personal'}}) ? 1 : 0;
}

sub upload_part {
        my $self = shift;
        my $msg  = shift;
        my $part = shift;
        
        if ($part->body() eq "This is a multi-part message in MIME format.") {
                return undef;
        }
        
        my ($root,$url) = $self->mk_upload_root($msg);
        
        my $fname = $part->filename();
        my $ext   = undef;
        
        if (! $fname) {
                
                $fname = md5_hex($part->body());
                
                if ($ext = $self->mk_extension($part->content_type())) {
                        $fname = sprintf("%s.%s",$fname,$ext);
                }
        }
        
        $url .= "/$fname";
        
        my $full_path = File::Spec->catfile($root,$fname);
                
        my $fh = tmpfile();
        $fh->print($part->body());

        my $uploaded = $self->upload_file(\*$fh,$full_path);

        if (! $uploaded) {
                $self->log()->error("failed to upload part, $!");
                return undef;
        }
        
        #
        
        return qq(<div class="mbox-attachment"><a href="$url">$fname</a></div>);
}

sub mk_id {
        my $self   = shift;
        my $msg_id = shift;
        
        $msg_id =~ s/^<//;
        $msg_id =~ s/>$//;
        return ($msg_id) ? md5_hex($msg_id) : undef;
}

sub mk_categories {
        my $self = shift;
        my $msg  = shift;

        my @cats = ();

        foreach my $header ("To","From","Cc","Bcc") {
                
                my @addrs = $self->find_addrs($msg->header($header));
                
                if (! @addrs) {
                        next;
                }
                
                foreach my $addr (@addrs) {
                        my $cat = $self->mk_category(lc($addr),0);
                        push @cats, $cat;
                        
                        $self->log()->info(sprintf("add category : %s (%d)\n",$cat->label(),$cat->id()));

                        my $rel = $self->mk_category($header,$cat->id());
                        push @cats, $rel;
                }
        }

        return \@cats;
}

sub find_addrs {
        my $self = shift;
        my $str  = shift;
        
        my %addrs = ();
        
        my $cb = sub {
                my $email = shift;
                if (my $fmt  = $email->format()) {
                        $addrs{ $fmt } ++;
                }
        };
        
        my $finder = Email::Find->new($cb);
        $finder->find(\$str);
        
        return keys %addrs;
}

sub mk_extension {
        my $self = shift;
        my $type = shift;
        
        if ($type =~ m!text/plain!) {
                return "txt";
        }
        
        elsif ($type =~ m!text/html!) {
                return "html";
        }
        
        elsif ($type =~ m!image/(.*)!) {
                return $1;
        }
        
        elsif ($type =~ m!application/(.*)!) {
                return $1;
        }
        
        else {
                return undef;
        }
}

sub mk_uploads_text {
        my $self = shift;
        my $msg  = shift;
        my @parts = @_;
        
        my $txt = "";
        
        map { 
                $txt .= $self->upload_part($msg,$_);
        } @parts;
        
        return $txt;
}

sub set_entry_text {
        my $self  = shift;
        my $entry = shift;
        my $txt   = shift;

        if (length($txt)>200) {
                my $excerpt = substr($txt,0,200);
                $entry->excerpt($excerpt);
                $entry->text($excerpt);
                $entry->text_more($txt);
        }

        else {
                $entry->text($txt);
        }

        return 1;
}

sub mk_head {
        my $self = shift;
        my $msg  = shift;
        
        my ($root,$url) = $self->mk_upload_root($msg);
        
        my $fname = "headers.txt";
        my $path  = File::Spec->catfile($root,$fname);
        
        open FH, ">$path";
        print FH $msg->_headers_as_string();
        close FH;
        
        return qq(<div class="mbox-headers"><a href="$url/$fname">$fname</a></div>);    
}

sub mk_upload_root {
        my $self = shift;
        my $msg  = shift;
        
        my $msg_id   = $self->mk_id($msg->header("Message-Id"));
        my $msg_date = $self->mk_date($msg->header("Date"));
        
        $msg_date =~ m!^(\d{4})(\d{2})(\d{2})!;
        my ($yyyy,$mm,$dd) = ($1,$2,$3);
        
        my $blog = MT::Blog->load($self->blog_id());
        my $fmgr = $blog->file_mgr();
        
        my $root = $blog->site_path();
        my $url  = $blog->site_url();
        
        $root = File::Spec->catdir($root,"attachments",$yyyy,$mm,$dd,$msg_id);
        $url  = "$url/attachments/$yyyy/$mm/$dd/$msg_id";
        
        $self->log()->debug("attachment root : $root\n");
        $self->log()->debug("attachment URL : $url\n");
        
        if ((! $fmgr->exists($root)) && (! $fmgr->mkpath($root))) {
                $self->log()->error("Failed to create '$root', $!");
        }
        
        return ($root,$url);
}

=head1 VERSION

1.01

=head1 DATE

$Date: 2005/12/03 19:10:27 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<MT::Import::Base>

http://pep.perl.org

http://www.movabletype.org

=head1 TO DO

Write message body to disk and store as an attachment Render the
static version using MTInclude. This should allow for better
searching and indexing by third-party tools.

=head1 BUGS

Probably, or at least a handful of special-cases. Patches
are welcome. Please report all bugs via :

L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2005 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

__END__

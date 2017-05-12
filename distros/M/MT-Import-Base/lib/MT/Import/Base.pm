# -*-cperl-*-

use strict;
package MT::Import::Base;

$MT::Import::Base::VERSION = '1.01';

=head1 NAME

MT::Import::Base - base class for importing "stuff" into Movable Type.

=head1 SYNOPSIS

 package MT::Import::Fubar;
 use base qw (MT::Import::Fubar);

=head1 DESCRIPTION

Base class for importing "stuff" into Movable Type.

=cut

use Date::Parse;
use Date::Format;

use File::Path;
use File::Spec;

use Log::Dispatch;
use Log::Dispatch::Screen;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Options are passed to MT::Import::Base using a Config::Simple object
or a valid Config::Simple config file. Options are grouped by "block".

=head2 importer

=over 4

=item * B<verbose>

Boolean.

Enable verbose logging for both this package and I<MT::Import::Mbox>

=item * B<force>

Boolean.

Force an entry to be reindexed, including any trackback pings and
attachments.

Default is I<false>

=back

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

=item * B<author_pass>

String.

The password to assign to any new authors you add to the Movable Type
weblog you are posting to.

Default is "I<none>".

=item * B<author_perms>

Int.

The permissions set to grant any new authors you add to the Movable Type
weblog you are posting to.

Default is I<514>, or the ability to add new categories.

=back

=cut

sub new {
        my $pkg  = shift;
        
        my $self = bless {}, $pkg;

        if (! $self->init(@_)) {
                return undef;
        }

        return $self;
}

sub init {
        my $self = shift;
        my $opts = shift;

        if (UNIVERSAL::isa($opts,"Config::Simple")) {
                $self->{cfg} = $opts;
        }
        
        else {
                my $cfg  = undef;
                
                eval {
                        $cfg = Config::Simple->new($opts);
                };
                
                if ($@) {
                        warn "$opts : $@";
                        return 0;
                }

                $self->{cfg} = $cfg;
        }
        
        #
        
        my $root = $self->{cfg}->param("mt.root");

        if (! -d $root) {
                warn "MT root ($root) is not a directory";
                return 0;
        }
        
        my $blog_id = $self->{cfg}->param("mt.blog_id");

        if (($blog_id !~ /^\d+$/) || ($blog_id < 1)) {
                warn "Blog ID ($blog_id) is not a positive integer";
                return 0;
        }

        my $blog_owner = $self->{cfg}->param("mt.blog_ownerid");

        if (($blog_owner !~ /^\d+$/) || ($blog_owner < 1)) {
                warn "Blog owner ID ($blog_owner) is not a positive integer";
                return 0;
        }

        #

        push @INC, File::Spec->catdir($root,"lib");
        push @INC, File::Spec->catdir($root,"extlib");

        eval {
                require MT;
                require MT::App::CMS;
                
                require MT::Entry;
                require MT::Author;
                require MT::Category;
                require MT::Permission;
                require MT::Placement;
                require MT::TBPing;
                require MT::Trackback;
                
                MT::Author->import(":constants");
        };
        
        if ($@) {
                warn "Failed to load a MT dependency, $@";
                return 0;
        }

        #

        my $app = MT::App::CMS->new(Config    => File::Spec->catfile($root,"mt.cfg"),
                                    Directory => $root);
    
        if (! $app) {
                warn "Failed to create MT application object, ".MT::App::CMS->errstr;
                return 0;
        }
        
        $self->{'__app'} = $app;
        
        #

        my $log_fmt = sub {
                my %args = @_;
                
                my $msg = $args{'message'};
                chomp $msg;
                
                my ($ln,$sub) = (caller(4))[2,3];
                $sub =~ s/.*:://;
                
                return sprintf("[%s][%s, ln%d] %s\n",
                               $args{'level'},$sub,$ln,$msg);
        };
        
        my $logger = Log::Dispatch->new(callbacks=>$log_fmt);
        my $error  = Log::Dispatch::Screen->new(name      => '__error',
                                                min_level => 'error',
                                                stderr    => 1);

        $logger->add($error);
        $self->{'__logger'} = $logger;

        $self->verbose($self->{cfg}->param("importer.verbose"));

        #
        
        $self->{'__imported'}  = [];

        #

        return 1;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->verbose($bool)

Returns true or false, indicating whether or not I<debug> events
would be logged.

=cut

sub verbose {
    my $self = shift;
    my $bool = shift;

    #

    if (defined($bool)) {

	$self->log()->remove('__verbose');

	if ($bool) {
	    my $stdout = Log::Dispatch::Screen->new(name      => '__verbose',
						    min_level => 'debug');
	    $self->log()->add($stdout);
	}
    }

    #

    return $self->log()->would_log('debug');
}

=head2 $obj->log()

Returns a I<Log::Dispatch> object.

=cut

sub log {
    my $self = shift;
    return $self->{'__logger'};
}

=head2 $obj->imported($id)

If I<$id> is defined, stores the ID in the object's internal
cache of entry's that have been imported.

Otherwise, the method returns a list or array reference of
imported entries depending on whether or not the method was
called in a I<wantarray> context.

=cut

sub imported {
        my $self = shift;
        my $id   = shift;
        
        if (! $id) {
                return (wantarray) ? @{$self->{'__imported'}} : $self->{'__imported'};
        }
        
        if (grep /^$id$/,@{$self->{'__imported'}}) {
                return 1;
        }
        
        push @{$self->{'__imported'}},$id;
        return 1;
}

=head2 $obj->rebuild()

Rebuild all of the entries returned by the object's I<imported>
method. Indexes are rebuilt afterwards.

Returns true or false.

=cut

sub rebuild {
        my $self = shift;
        
        foreach my $id ($self->imported()) {
                $self->rebuild_entry($id);
        }
        
        #
        
        $self->rebuild_indexes();
        return 1;
}

=head2 $obj->rebuild_indexes()

Rebuild all of the indexes for the blog defined B<mt.blog_id>.

Returns true or false.

=cut

sub rebuild_indexes {
        my $self = shift;
        $self->{'__app'}->rebuild_indexes(BlogID => $self->blog_id());
        return 1;
}

=head2 $obj->rebuild_entry($id)

Rebuild an individual entry. If the entry has neighbouring entries,
they will be added to the object's internal "imported" list.

Returns true or false.

=cut

sub rebuild_entry {
        my $self = shift;
        my $id   = shift;
        
        my $entry = MT::Entry->load($id);
        my $next  = undef;
        my $prev  = undef;
        
        if ($next = $entry->next()) {
                $next = $next->id();
                
                $self->imported($next);
        }
        
        if ($prev = $entry->previous()) {
                $prev = $prev->id();
                $self->imported($prev);
        }
        
        my $ok = $self->{'__app'}->rebuild_entry(Entry             => $id,
                                                 BuildDependencies => 0,
                                                 OldPrevious       => $next,
                                                 OldNext           => $prev);

        #
        
        if (! $ok) {
                $self->log()->error("failed to rebuild entry '$id', $!");
                return 0;
        }
        
        $self->log()->info(sprintf("rebuilt entry %d (%s)\n",$id,$entry->title()));
        return 1;
}

=head2 $obj->mk_category($label,$parent_id,$author_id)

If it does not already exist for the blog defined by B<mt.blog_id> creates
a new Movable Type category for I<$label>.

I<$parent_id> is the numeric ID for another MT category and is not required.

Returns a I<MT::Category> object on success or undef if there was
an error.

=cut

sub mk_category {
        my $self    = shift;
        my $label   = shift;
        my $parent  = shift;
        my $auth_id = shift;
        
        #
        
        $label =~ s/^\s+//;
        $label =~ s/\s+$//;
        
        $self->log()->debug("make category $label for ($parent)");

        my $cat = MT::Category->load({label   => $label,
                                      parent  => $parent,
                                      blog_id => $self->blog_id()});

        if (! $cat) {
                $cat = MT::Category->new();
                $cat->blog_id($self->blog_id());
                $cat->label($label);
                $cat->parent($parent);
                $cat->author_id($auth_id);
                
                if (! $cat->save()) {
                        $self->log()->error("failed to add category $label ($parent), $!");
                }
        }

        $self->log()->debug(sprintf("mk category '%s' (%s:%s)",$cat->label(),$cat->id(),$cat->parent()));
        return $cat;
}

=head2 $obj->mk_author($name,$email)

If it does not already exist for the blog defined by B<mt.blog_id> creates
a new Movable Type author for I<$name>.

Leading and trailing space will be trimmed from I<$name>.

Returns a I<MT::Author> object on success or undef if there was
an error.

=cut

sub mk_author {
        my $self  = shift;
        my $name  = shift;
        my $email = shift;

        $name =~ s/^\s+//;
        $name =~ s/\s+$//;
        $name = lc($name);

        my $author = MT::Author->load({name => $name,
                                       type => &MT::Author::AUTHOR()});
        
        if (! $author) {
                $author = MT::Author->new();
                $author->name($name);
                $author->email($email);
                $author->type(&MT::Author::AUTHOR);
                $author->set_password($self->{cfg}->param("mt.author_password"));
                $author->created_by($self->{cfg}->param("mt.blog_ownerid"));
                $author->type(1);
                
                if (! $author->save()) {
                        $self->log()->error("failed to add author $name, $!"); 
                }
        }

        my $pe = MT::Permission->load({blog_id   => $self->{cfg}->param("mt.blog_id"),
                                       author_id => $author->id()});
    
        if (! $pe) {
                $pe = MT::Permission->new();
                $pe->blog_id($self->{cfg}->param("mt.blog_id"));
                $pe->author_id($author->id());
                $pe->role_mask($self->{cfg}->param("mt.author_permissions"));
                $pe->save();
        }
    
        return $author;
}

=head2 $obj->place_category(MT::Entry, MT::Category, $is_primary)

If it does not already exist for the combined entry object and category
object creates a new Movable Type placement entry for the pair.

Returns a I<MT::Placement> object on success or undef if there was
an error.

=cut

sub place_category {
        my $self     = shift;
        my $entry    = shift;
        my $category = shift;
        my $primary  = shift;

        $primary ||= 0;

        $self->log()->debug(sprintf("place %s (%s) for %s",$category->label(),$category->id(),$entry->id()));

        my $pl = MT::Placement->load({entry_id    => $entry->id(),
                                      category_id => $category->id()});

        if ($pl) {
                $self->log()->debug("already placed with id");
                return $pl;
        }

        $pl = MT::Placement->new();
        $pl->entry_id($entry->id());
        $pl->blog_id($self->{cfg}->param("mt.blog_id"));
        $pl->is_primary($primary);
        $pl->category_id($category->id());
        
        if (! $pl->save()) {
                $self->log()->error(sprintf("can't save secondary placement for %s (%s), $!",
                                            $category->label(),$category->parent()));
        }

        return $pl;
}

=head2 $obg->mk_date($date_str)

Returns a MT specific datetime string.
=cut

sub mk_date {
        my $self = shift;
        my $str  = shift;
        my $time = str2time($str);
        my $dt   = time2str("%Y-%m-%d%H:%M:%S",$time);
        $dt      =~ s/(?:-|:)//g;
        return $dt;
}

=head2 $obj->upload_file(\*$fh, $path)

Wrapper method for storing an file outside of Movable Type using the
blog engine's file manager.

Returns true or false.

=cut

sub upload_file {
        my $self = shift;
        my $fh   = shift;
        my $dest = shift;

        $self->log()->debug("upload file to $dest");

        seek($fh,0,0);

        my $blog  = MT::Blog->load($self->blog_id());
        my $fmgr  = $blog->file_mgr();
        my $bytes = $fmgr->put($fh,$dest,"upload");
        
        if (! $bytes) {
                $self->log()->error("failed to upload part to $dest, ".$fmgr->errstr());
                return 0;
        }

        return 1;
}

=head2 $obj->blog_id() 

Wrapper method for calling $obj->{cfg}->param("mt.blog_id")

=cut

sub blog_id {
        my $self = shift;
        return $self->{cfg}->param("mt.blog_id");
}

sub purge {
        my $self = shift;
        my $blog = MT::Blog->load($self->blog_id());

        my @classes = qw(MT::Permission MT::Entry
                         MT::Category MT::Notification);

        foreach my $class (@classes) {
                eval "use $class;";
                my $iter = $class->load_iter({blog_id => $self->blog_id()});
                my @ids = ();
                
                # I'm not really sure why this needs to
                # happen this way (or, really, why it's
                # not black-boxed) but it's what MT::Blog
                # does so there you go...
                
                while (my $obj = $iter->()) {
                        push @ids, $obj->id;
                }
                
                for my $id (@ids) {
                        my $obj = $class->load($id);
                        print sprintf("%s remove %d\n",$class,$obj->id());
                        $obj->remove;
                }
        }
}

=head2 $obj->ping_for_reply(MT::Entry, $reply_basename, $from) 

Wrapper method pinging another entry.

The entry object is the post doing the pinging. I<$reply_basename> is the
post that is being pinged. I<$from> is a label indicating where the ping
is coming from.

The entry being pinged is fetched by where the entry's basename matches
I$<basename> and it's blog_id matches B<mt.blog_id>.

Returns true or false.

=cut

sub ping_for_reply {
        my $self  = shift;
        my $entry = shift;
        my $reply = shift;
        my $from  = shift;

        $self->log()->debug("reply is $reply");

        my $to_ping = MT::Entry->load({basename => $reply,
                                       blog_id  => $self->blog_id()});

        if (! $to_ping) {
                $self->log()->warning("can't locate entry for $reply");
                return 0;
        }

        $self->log()->debug("to ping : ".$to_ping->id());
                
        my $tb = MT::Trackback->load({entry_id=>$to_ping->id()});
        
        $self->log()->debug("tb is : ".$tb->id());
        
        if (! $tb) {
                $self->log()->warning("can't locate trackback entry for $reply");
                return 0;
        }
                        
        my $ping = MT::TBPing->new();
        $ping->blog_id($tb->blog_id());
        $ping->tb_id($tb->id());
        $ping->source_url($entry->permalink());
        $ping->ip($self->blog_id());
        $ping->visible(1);
        $ping->junk_status(0);
        
        $ping->title($entry->title());
        $ping->blog_name($from);
        
        if (! $ping->save()) {
                $self->log()->error("can not save ping, $!");
        }
        
        $self->log()->debug(sprintf("ping from %s to %s\n",
                                    $entry->permalink(),
                                    $to_ping->permalink()));
        
        my $blog = MT::Blog->load($ping->blog_id());
        $blog->touch();
        
        if (! $blog->save()) {
                # $self->log()->error();
        }
        
        $self->imported($to_ping->id());
        
        #
        
        my @pinged   = split("\n",$entry->pinged_urls());
        my $ping_url = $to_ping->permalink();
        
        if (! grep /^$ping_url$/,@pinged ) {
                push @pinged, $ping_url;
                $entry->pinged_urls(join "\n", @pinged);
                $entry->save();
        }
        
        $self->log()->debug(sprintf("pinged %d : %s\n",
                                    $entry->id(),
                                    join(";",split("\n",$entry->pinged_urls()))));
        
        return 1;
}

=head1 VERSION

1.01

=head1 DATE

$Date: 2005/12/03 18:46:21 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 BUGS

Please report all bugs via : http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2005 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;

# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::MH;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Dir';

use strict;
use warnings;
use filetest 'access';

use Mail::Box::MH::Index;
use Mail::Box::MH::Message;
use Mail::Box::MH::Labels;

use Carp;
use File::Spec       ();
use File::Basename   'basename';
use IO::Handle       ();

# Since MailBox 2.052, the use of File::Spec is reduced to the minimum,
# because it is too slow.  The '/' directory separators do work on
# Windows too.


my $default_folder_dir = exists $ENV{HOME} ? "$ENV{HOME}/.mh" : '.';

sub init($)
{   my ($self, $args) = @_;

    $args->{folderdir}     ||= $default_folder_dir;
    $args->{lock_file}     ||= $args->{index_filename};

    $self->SUPER::init($args);

    my $folderdir            = $self->folderdir;
    my $directory            = $self->directory;
    return unless -d $directory;

    # About the index

    $self->{MBM_keep_index}  = $args->{keep_index} || 0;
    $self->{MBM_index}       = $args->{index};
    $self->{MBM_index_type}  = $args->{index_type} || 'Mail::Box::MH::Index';
    for($args->{index_filename})
    {  $self->{MBM_index_filename}
          = !defined $_ ? "$directory/.index"          # default
          : File::Spec->file_name_is_absolute($_) ? $_ # absolute
          :               "$directory/$_";             # relative
    }

    # About labels

    $self->{MBM_labels}      = $args->{labels};
    $self->{MBM_labels_type} = $args->{labels_type} || 'Mail::Box::MH::Labels';
    for($args->{labels_filename})
    {   $self->{MBM_labels_filename}
          = !defined $_ ? "$directory/.mh_sequences"
          : File::Spec->file_name_is_absolute($_) ? $_   # absolute
          :               "$directory/$_";               # relative
    }

    $self;
}


sub create($@)
{   my ($thingy, $name, %args) = @_;
    my $class     = ref $thingy      || $thingy;
    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $directory = $class->folderToDirectory($name, $folderdir);

    return $class if -d $directory;

    if(mkdir $directory, 0700)
    {   $class->log(PROGRESS => "Created folder $name.");
        return $class;
    }
    else
    {   $class->log(ERROR => "Cannot create MH folder $name: $!");
        return;
    }
}

sub foundIn($@)
{   my $class = shift;
    my $name  = @_ % 2 ? shift : undef;
    my %args  = @_;
    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $directory = $class->folderToDirectory($name, $folderdir);

    return 0 unless -d $directory;
    return 1 if -f "$directory/1";

    # More thorough search required in case some numbered messages
    # disappeared (lost at fsck or copy?)

    return unless opendir DIR, $directory;
    foreach (readdir DIR)
    {   next unless m/^\d+$/;   # Look for filename which is a number.
        closedir DIR;
        return 1;
    }

    closedir DIR;
    0;
}

#-------------------------------------------

sub type() {'mh'}

#-------------------------------------------

sub listSubFolders(@)
{   my ($class, %args) = @_;
    my $dir;
    if(ref $class)
    {   $dir   = $class->directory;
        $class = ref $class;
    }
    else
    {   my $folder    = $args{folder}    || '=';
        my $folderdir = $args{folderdir} || $default_folder_dir;
        $dir   = $class->folderToDirectory($folder, $folderdir);
    }

    $args{skip_empty} ||= 0;
    $args{check}      ||= 0;

    # Read the directories from the directory, to find all folders
    # stored here.  Some directories have to be removed because they
    # are created by all kinds of programs, but are no folders.

    return () unless -d $dir && opendir DIR, $dir;

    my @dirs = grep { !/^\d+$|^\./ && -d "$dir/$_" && -r _ }
                   readdir DIR;

    closedir DIR;

    # Skip empty folders.  If a folder has sub-folders, then it is not
    # empty.
    if($args{skip_empty})
    {    my @not_empty;

         foreach my $subdir (@dirs)
         {   if(-f "$dir/$subdir/1")
             {   # Fast found: the first message of a filled folder.
                 push @not_empty, $subdir;
                 next;
             }

             opendir DIR, "$dir/$subdir" or next;
             my @entities = grep !/^\./, readdir DIR;
             closedir DIR;

             if(grep /^\d+$/, @entities)   # message 1 was not there, but
             {   push @not_empty, $subdir; # other message-numbers exist.
                 next;
             }

             foreach (@entities)
             {   next unless -d "$dir/$subdir/$_";
                 push @not_empty, $subdir;
                 last;
             }

         }

         @dirs = @not_empty;
    }

    # Check if the files we want to return are really folders.

    @dirs = map { m/(.*)/ && $1 ? $1 : () } @dirs;   # untaint
    return @dirs unless $args{check};

    grep { $class->foundIn("$dir/$_") } @dirs;
}

#-------------------------------------------

sub openSubFolder($)
{   my ($self, $name) = @_;

    my $subdir = $self->nameOfSubFolder($name);
    unless(-d $subdir || mkdir $subdir, 0755)
    {   warn "Cannot create subfolder $name for $self: $!\n";
        return;
    }

    $self->SUPER::openSubFolder($name, @_);
}

#-------------------------------------------

sub topFolderWithMessages() { 1 }

#-------------------------------------------


sub appendMessages(@)
{   my $class  = shift;
    my %args   = @_;

    my @messages = exists $args{message} ? $args{message}
                 : exists $args{messages} ? @{$args{messages}}
                 : return ();

    my $self     = $class->new(@_, access => 'r')
        or return ();

    my $directory= $self->directory;
    return unless -d $directory;

    my $locker   = $self->locker;
    unless($locker->lock)
    {   $self->log(ERROR => "Cannot append message without lock on $self.");
        return;
    }

    my $msgnr    = $self->highestMessageNumber +1;

    foreach my $message (@messages)
    {   my $filename = "$directory/$msgnr";
        $message->create($filename)
           or $self->log(ERROR =>
	           "Unable to write message for $self to $filename: $!\n");

        $msgnr++;
    }
 
    $self->labels->append(@messages);
    $self->index->append(@messages);

    $locker->unlock;
    $self->close(write => 'NEVER');

    @messages;
}

#-------------------------------------------


sub highestMessageNumber()
{   my $self = shift;

    return $self->{MBM_highest_msgnr}
        if exists $self->{MBM_highest_msgnr};

    my $directory    = $self->directory;

    opendir DIR, $directory or return;
    my @messages = sort {$a <=> $b} grep /^\d+$/, readdir DIR;
    closedir DIR;

    $messages[-1];
}

#-------------------------------------------


sub index()
{   my $self  = shift;
    return () unless $self->{MBM_keep_index};
    return $self->{MBM_index} if defined $self->{MBM_index};

    $self->{MBM_index} = $self->{MBM_index_type}->new
     ( filename  => $self->{MBM_index_filename}
     , $self->logSettings
     )

}

#-------------------------------------------


sub labels()
{   my $self   = shift;
    return $self->{MBM_labels} if defined $self->{MBM_labels};

    $self->{MBM_labels} = $self->{MBM_labels_type}->new
      ( filename => $self->{MBM_labels_filename}
      , $self->logSettings
      );
}

#-------------------------------------------

sub readMessageFilenames
{   my ($self, $dirname) = @_;

    opendir DIR, $dirname or return;

    # list of numerically sorted, untainted filenames.
    my @msgnrs
       = sort {$a <=> $b}
            map { /^(\d+)$/ && -f "$dirname/$1" ? $1 : () }
               readdir DIR;

    closedir DIR;

    @msgnrs;
}

#-------------------------------------------

sub readMessages(@)
{   my ($self, %args) = @_;

    my $directory = $self->directory;
    return unless -d $directory;

    my $locker = $self->locker;
    $locker->lock or return;

    my @msgnrs = $self->readMessageFilenames($directory);

    my $index  = $self->{MBM_index};
    unless($index)
    {   $index = $self->index;
        $index->read if $index;
    }

    my $labels = $self->{MBM_labels};
    unless($labels)
    {    $labels = $self->labels;
         $labels->read if $labels;
    }

    my $body_type   = $args{body_delayed_type};
    my $head_type   = $args{head_delayed_type};
    my @log         = $self->logSettings;

    foreach my $msgnr (@msgnrs)
    {
        my $msgfile = "$directory/$msgnr";

        my $head;
        $head       = $index->get($msgfile) if $index;
        $head     ||= $head_type->new(@log);

        my $message = $args{message_type}->new
         ( head       => $head
         , filename   => $msgfile
         , folder     => $self
         , fix_header => $self->{MB_fix_headers}
         );

        my $labref  = $labels ? $labels->get($msgnr) : ();
        $message->label(seen => 1, $labref ? @$labref : ());

        $message->storeBody($body_type->new(@log, message => $message));
        $self->storeMessage($message);
    }

    $self->{MBM_highest_msgnr}  = $msgnrs[-1];
    $locker->unlock;
    $self;
}
 
#-------------------------------------------

sub delete(@)
{   my $self = shift;
    $self->SUPER::delete(@_);

    my $dir = $self->directory;
    return 1 unless opendir DIR, $dir;
    IO::Handle::untaint \*DIR;

    # directories (subfolders) are not removed, as planned
    unlink "$dir/$_" for readdir DIR;
    closedir DIR;

    rmdir $dir;    # fails when there are subdirs (without recurse)
}

#-------------------------------------------


sub writeMessages($)
{   my ($self, $args) = @_;

    # Write each message.  Two things complicate life:
    #   1 - we may have a huge folder, which should not be on disk twice
    #   2 - we may have to replace a message, but it is unacceptable
    #       to remove the original before we are sure that the new version
    #       is on disk.

    my $locker    = $self->locker;
    $self->log(ERROR => "Cannot write folder $self without lock."), return
        unless $locker->lock;

    my $renumber  = exists $args->{renumber} ? $args->{renumber} : 1;
    my $directory = $self->directory;
    my @messages  = @{$args->{messages}};

    my $writer    = 0;
    foreach my $message (@messages)
    {
        my $filename = $message->filename;

        my $newfile;
        if($renumber || !$filename)
        {   $newfile = $directory . '/' . ++$writer;
        }
        else
        {   $newfile = $filename;
            $writer  = basename $filename;
        }

        $message->create($newfile);
    }

    # Write the labels- and the index-file.

    my $labels = $self->labels;
    $labels->write(@messages) if $labels;

    my $index  = $self->index;
    $index->write(@messages) if $index;

    $locker->unlock;

    # Remove an empty folder.  This is done last, because the code before
    # in this method will have cleared the contents of the directory.

    if(!@messages && $self->{MB_remove_empty})
    {   # If something is still in the directory, this will fail, but I
        # don't mind.
        rmdir $directory;
    }

    $self;
}

#-------------------------------------------


1;

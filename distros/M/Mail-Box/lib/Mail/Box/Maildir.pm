# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Maildir;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Dir';

use strict;
use warnings;
use filetest 'access';

use Mail::Box::Maildir::Message;

use Carp;
use File::Copy     'move';
use File::Basename 'basename';
use Sys::Hostname  'hostname';
use File::Remove   'remove';

# Maildir is only supported on UNIX, because the filenames probably
# do not work on other platforms.  Since MailBox 2.052, the use of
# File::Spec to create filenames has been removed: benchmarks showed
# that catfile() consumed 20% of the time of a folder open().  And
# '/' file separators work on Windows too!


my $default_folder_dir = exists $ENV{HOME} ? "$ENV{HOME}/.maildir" : '.';

sub init($)
{   my ($self, $args) = @_;

    croak "No locking possible for maildir folders."
       if exists $args->{locker}
       || (defined $args->{lock_type} && $args->{lock_type} ne 'NONE');

    $args->{lock_type}   = 'NONE';
    $args->{folderdir} ||= $default_folder_dir;

    return undef
        unless $self->SUPER::init($args);

    $self->acceptMessages if $args->{accept_new};
    $self;
}


sub create($@)
{   my ($thingy, $name, %args) = @_;
    my $class     = ref $thingy      || $thingy;
    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $directory = $class->folderToDirectory($name, $folderdir);

    if($class->createDirs($directory))
    {   $class->log(PROGRESS => "Created folder Maildir $name.");
        return $class;
    }
    else
    {   $class->log(ERROR => "Cannot create Maildir folder $name.");
        return undef;
    }
}

sub foundIn($@)
{   my $class = shift;
    my $name  = @_ % 2 ? shift : undef;
    my %args  = @_;
    my $folderdir = $args{folderdir} || $default_folder_dir;
    my $directory = $class->folderToDirectory($name, $folderdir);

    -d "$directory/cur";
}

sub type() {'maildir'}

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

    my @dirs;
    while(my $d = readdir DIR)
    {   next if $d =~ m/^(new|tmp|cur|\.\.?)$/;

        my $dir = "$dir/$d";
        push @dirs, $d if -d $dir && -r _;
    }

    closedir DIR;

    # Skip empty folders.

    @dirs = grep {!$class->folderIsEmpty("$dir/$_")} @dirs
        if $args{skip_empty};

    # Check if the files we want to return are really folders.

    @dirs = map { m/(.*)/ && $1 } @dirs;  # untaint
    return @dirs unless $args{check};

    grep { $class->foundIn("$dir/$_") } @dirs;
}

sub openSubFolder($@)
{   my ($self, $name) = (shift, shift);
    $self->createDirs($self->nameOfSubFolder($name));
    $self->SUPER::openSubFolder($name, @_);
}

sub topFolderWithMessages() { 1 }

my $uniq = rand 1000;


sub coerce($)
{   my ($self, $message) = (shift, shift);

    my $is_native = $message->isa('Mail::Box::Maildir::Message');
    my $coerced   = $self->SUPER::coerce($message, @_);

    my $basename  = $is_native ? basename($message->filename)
      : ($message->timestamp || time) .'.'. hostname .'.'. $uniq++;

    my $dir = $self->directory;
    my $tmp = "$dir/tmp/$basename";
    my $new = "$dir/new/$basename";

    if($coerced->create($tmp) && $coerced->create($new))
         {$self->log(PROGRESS => "Added Maildir message in $new") }
    else {$self->log(ERROR    => "Cannot create Maildir message file $new.") }

    $coerced->labelsToFilename unless $is_native;
    $coerced;
}

#-------------------------------------------


sub createDirs($)
{   my ($thing, $dir) = @_;

    $thing->log(ERROR => "Cannot create Maildir folder directory $dir: $!"), return
        unless -d $dir || mkdir $dir;

    my $tmp = "$dir/tmp";
    $thing->log(ERROR => "Cannot create Maildir folder subdir $tmp: $!"), return
        unless -d $tmp || mkdir $tmp;

    my $new = "$dir/new";
    $thing->log(ERROR => "Cannot create Maildir folder subdir $new: $!"), return
        unless -d $new || mkdir $new;

    my $cur = "$dir/cur";
    $thing->log(ERROR =>  "Cannot create Maildir folder subdir $cur: $!"), return
        unless -d $cur || mkdir $cur;

    $thing;
}


sub folderIsEmpty($)
{   my ($self, $dir) = @_;
    return 1 unless -d $dir;

    foreach (qw/tmp new cur/)
    {   my $subdir = "$dir/$_";
        next unless -d $subdir;

        opendir DIR, $subdir or return 0;
        my $first  = readdir DIR;
        closedir DIR;

        return 0 if defined $first;
    }

    opendir DIR, $dir or return 1;
    while(my $entry = readdir DIR)
    {   next if $entry =~
           m/^(?:tmp|cur|new|bulletin(?:time|lock)|seriallock|\..?)$/;

        closedir DIR;
        return 0;
    }

    closedir DIR;
    1;
}

sub delete(@)
{   my $self = shift;

    # Subfolders are not nested in the directory structure
    remove \1, $self->directory;
}

sub readMessageFilenames
{   my ($self, $dirname) = @_;

    opendir DIR, $dirname or return ();

    my @files;
    if(${^TAINT})
    {   # unsorted list of untainted filenames.
        @files = map { m/^([0-9][\w.:,=\-]+)$/ && -f "$dirname/$1" ? $1 : () }
                   readdir DIR;
    }
    else
    {   # not running tainted
        @files = grep /^([0-9][\w.:,=\-]+)$/ && -f "$dirname/$1", readdir DIR;
    }
    closedir DIR;

    # Sort the names.  Solve the Y2K (actually the 1 billion seconds
    # since 1970 bug) which hunts Maildir.  The timestamp, which is
    # the start of the filename will have some 0's in front, so each
    # timestamp has the same length.

    my %unified;
    m/^(\d+)/ and $unified{ ('0' x (10-length($1))).$_ } = $_
        for @files;

    map "$dirname/$unified{$_}",
        sort keys %unified;
}

sub readMessages(@)
{   my ($self, %args) = @_;

    my $directory = $self->directory;
    return unless -d $directory;

    #
    # Read all messages
    #

    my $curdir  = "$directory/cur";
    my @cur     = map +[$_, 1], $self->readMessageFilenames($curdir);

    my $newdir  = "$directory/new";
    my @new     = map +[$_, 0], $self->readMessageFilenames($newdir);
    my @log     = $self->logSettings;

    foreach (@cur, @new)
    {   my ($filename, $accepted) = @$_;
        my $message = $args{message_type}->new
         ( head      => $args{head_delayed_type}->new(@log)
         , filename  => $filename
         , folder    => $self
         , fix_header=> $self->{MB_fix_headers}
         , labels    => [ accepted => $accepted ]
         );

        my $body    = $args{body_delayed_type}->new(@log, message => $message);
        $message->storeBody($body) if $body;
        $self->storeMessage($message);
    }

    $self;
}
 

sub acceptMessages($)
{   my ($self, %args) = @_;
    my @accept = $self->messages('!accepted');
    $_->accept foreach @accept;
    @accept;
}

sub writeMessages($)
{   my ($self, $args) = @_;

    # Write each message.  Two things complicate life:
    #   1 - we may have a huge folder, which should not be on disk twice
    #   2 - we may have to replace a message, but it is unacceptable
    #       to remove the original before we are sure that the new version
    #       is on disk.

    my $writer    = 0;

    my $directory = $self->directory;
    my @messages  = @{$args->{messages}};

    my $tmpdir    = "$directory/tmp";
    die "Cannot create directory $tmpdir: $!"
        unless -d $tmpdir || mkdir $tmpdir;

    foreach my $message (@messages)
    {   next unless $message->isModified;

        my $filename = $message->filename;
        my $basename = basename $filename;

        my $newtmp   = "$directory/tmp/$basename";
        open my $new, '>', $newtmp
           or croak "Cannot create file $newtmp: $!";

        $message->write($new);
        close $new;

        unlink $filename;
        move $newtmp, $filename
            or warn "Cannot move $newtmp to $filename: $!\n";
    }

    # Remove an empty folder.  This is done last, because the code before
    # in this method will have cleared the contents of the directory.

    if(!@messages && $self->{MB_remove_empty})
    {   # If something is still in the directory, this will fail, but I
        # don't mind.
        rmdir "$directory/cur";
        rmdir "$directory/tmp";
        rmdir "$directory/new";
        rmdir $directory;
    }

    $self;
}


sub appendMessages(@)
{   my $class  = shift;
    my %args   = @_;

    my @messages = exists $args{message}  ?   $args{message}
                 : exists $args{messages} ? @{$args{messages}}
                 : return ();

    my $self     = $class->new(@_, access => 'a');
    my $directory= $self->directory;
    return unless -d $directory;

    my $tmpdir   = "$directory/tmp";
    croak "Cannot create directory $tmpdir: $!", return
        unless -d $tmpdir || mkdir $tmpdir;

    my $msgtype  = $args{message_type} || 'Mail::Box::Maildir::Message';

    foreach my $message (@messages)
    {   my $is_native = $message->isa($msgtype);
        my ($basename, $coerced);

        if($is_native)
        {   $coerced  = $message;
            $basename = basename $message->filename;
        }
        else
        {   $coerced  = $self->SUPER::coerce($message);
            $basename = ($message->timestamp||time).'.'. hostname.'.'.$uniq++;
        }

       my $dir = $self->directory;
       my $tmp = "$dir/tmp/$basename";
       my $new = "$dir/new/$basename";

       if($coerced->create($tmp) && $coerced->create($new))
            {$self->log(PROGRESS => "Appended Maildir message in $new") }
       else {$self->log(ERROR    =>
                "Cannot append Maildir message in $new to folder $self.") }
    }
 
    $self->close;

    @messages;
}

#-------------------------------------------


1;

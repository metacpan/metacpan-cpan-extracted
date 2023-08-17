# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Manager;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Mail::Box;

use List::Util   'first';
use Scalar::Util 'weaken';

# failed compilation will not complain a second time
# so we need to keep track.
my %require_failed;


my @basic_folder_types =
  ( [ mbox    => 'Mail::Box::Mbox'    ]
  , [ mh      => 'Mail::Box::MH'      ]
  , [ maildir => 'Mail::Box::Maildir' ]
  , [ pop     => 'Mail::Box::POP3'    ]
  , [ pop3    => 'Mail::Box::POP3'    ]
  , [ pops    => 'Mail::Box::POP3s'   ]
  , [ pop3s   => 'Mail::Box::POP3s'   ]
  , [ imap    => 'Mail::Box::IMAP4'   ]
  , [ imap4   => 'Mail::Box::IMAP4'   ]
  , [ imaps   => 'Mail::Box::IMAP4s'  ]
  , [ imap4s  => 'Mail::Box::IMAP4s'  ]
  );

my @managers;  # usually only one, but there may be more around :(

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    # Register all folder-types.  There may be some added later.

    my @new_types;
    if(exists $args->{folder_types})
    {   @new_types = ref $args->{folder_types}[0]
                   ? @{$args->{folder_types}}
                   : $args->{folder_types};
    }

    my @basic_types = reverse @basic_folder_types;
    if(my $basic = $args->{autodetect})
    {   my %types = map +($_ => 1), ref $basic ? @$basic : $basic;
        @basic_types = grep $types{$_->[0]}, @basic_types;
    }

    $self->{MBM_folder_types} = [];
    $self->registerType(@$_) for @new_types, @basic_types;

    $self->{MBM_default_type} = $args->{default_folder_type} || 'mbox';

    # Inventory on existing folder-directories.
    my $fd = $self->{MBM_folderdirs} = [ ];
    if(exists $args->{folderdir})
    {   my @dirs = $args->{folderdir};
        @dirs = @{$dirs[0]} if ref $dirs[0] eq 'ARRAY';
        push @$fd, @dirs;
    }

    if(exists $args->{folderdirs})
    {   my @dirs = $args->{folderdirs};
        @dirs = @{$dirs[0]} if ref $dirs[0];
        push @$fd, @dirs;
    }
    push @$fd, '.';

    $self->{MBM_folders} = [];
    $self->{MBM_threads} = [];

    push @managers, $self;
    weaken $managers[-1];

    $self;
}

#-------------------------------------------

sub registerType($$@)
{   my ($self, $name, $class, @options) = @_;
    unshift @{$self->{MBM_folder_types}}, [$name, $class, @options];
    $self;
}


sub folderdir()
{   my $dirs = shift->{MBM_folderdirs} or return ();
    wantarray ? @$dirs : $dirs->[0];
}


sub folderTypes()
{   my $self = shift;
    my %uniq;
    $uniq{$_->[0]}++ foreach @{$self->{MBM_folder_types}};
    sort keys %uniq;
}


sub defaultFolderType()
{   my $self = shift;
    my $name = $self->{MBM_default_type};
    return $name if $name =~ m/\:\:/;  # obviously a class name

    foreach my $def (@{$self->{MBM_folder_types}})
    {   return $def->[1] if $def->[0] eq $name || $def->[1] eq $name;
    }

    undef;
}

#-------------------------------------------


sub open(@)
{   my $self = shift;
    my $name = @_ % 2 ? shift : undef;
    my %args = @_;
    $args{authentication} ||= 'AUTO';

    $name    = defined $args{folder} ? $args{folder} : ($ENV{MAIL} || '')
        unless defined $name;

    if($name =~ m/^(\w+)\:/ && grep $_ eq $1, $self->folderTypes)
    {   # Complicated folder URL
        my %decoded = $self->decodeFolderURL($name);
        if(keys %decoded)
        {   # accept decoded info
            @args{keys %decoded} = values %decoded;
        }
        else
        {   $self->log(ERROR => "Illegal folder URL '$name'.");
            return;
        }
    }
    else
    {   # Simple folder name
        $args{folder} = $name;
    }

    # Do not show password in folder name
    my $type = $args{type};
    if(!defined $type) { ; }
    elsif($type eq 'pop3' || $type eq 'pop')
    {   my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
        my $srv  = $args{server_name} ||= 'localhost';
        my $port = $args{server_port} ||= 110;
        $args{folderdir} = $name = "pop3://$un\@$srv:$port";
    }
    elsif($type eq 'pop3s' || $type eq 'pops')
    {   my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
        my $srv  = $args{server_name} ||= 'localhost';
        my $port = $args{server_port} ||= 995;
        $args{folderdir} = $name = "pop3s://$un\@$srv:$port";
    }
    elsif($type eq 'imap4' || $type eq 'imap')
    {   my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
        my $srv  = $args{server_name} ||= 'localhost';
        my $port = $args{server_port} ||= 143;
        $args{folderdir} = $name = "imap4://$un\@$srv:$port";
    }
    elsif($type eq 'imap4s' || $type eq 'imaps')
    {   my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
        my $srv  = $args{server_name} ||= 'localhost';
        my $port = $args{server_port} ||= 993;
        $args{folderdir} = $name = "imap4s://$un\@$srv:$port";
    }

    unless(defined $name && length $name)
    {   $self->log(ERROR => "No foldername specified to open.");
        return undef;
    }
        
    $args{folderdir} ||= $self->{MBM_folderdirs}->[0]
        if $self->{MBM_folderdirs};

    $args{access} ||= 'r';

    if($args{create} && $args{access} !~ m/w|a/)
    {   $self->log(WARNING
           => "Will never create a folder $name without having write access.");
        undef $args{create};
    }

    # Do not open twice.
    if(my $folder = $self->isOpenFolder($name))
    {   $self->log(ERROR => "Folder $name is already open.");
        return undef;
    }

    #
    # Which folder type do we need?
    #

    my ($folder_type, $class, @defaults);
    if($type)
    {   # User-specified foldertype prevails.
        foreach (@{$self->{MBM_folder_types}})
        {   (my $abbrev, $class, @defaults) = @$_;

            if($type eq $abbrev || $type eq $class)
            {   $folder_type = $abbrev;
                last;
            }
        }

        $self->log(ERROR => "Folder type $type is unknown, using autodetect.")
            unless $folder_type;
    }

    unless($folder_type)
    {   # Try to autodetect foldertype.
        foreach (@{$self->{MBM_folder_types}})
        {   next unless $_;
            (my $abbrev, $class, @defaults) = @$_;
            next if $require_failed{$class};

            eval "require $class";
            if($@)
            {   $require_failed{$class}++;
                next;
            }

            if($class->foundIn($name, @defaults, %args))
            {   $folder_type = $abbrev;
                last;
            }
        }
     }

    unless($folder_type)
    {   # Use specified default
        if(my $type = $self->{MBM_default_type})
        {   foreach (@{$self->{MBM_folder_types}})
            {   (my $abbrev, $class, @defaults) = @$_;
                if($type eq $abbrev || $type eq $class)
                {   $folder_type = $abbrev;
                    last;
                }
            }
        }
    }

    unless($folder_type)
    {   # use first type (last defined)
        ($folder_type, $class, @defaults) = @{$self->{MBM_folder_types}[0]};
    }
    
    #
    # Try to open the folder
    #

    return if $require_failed{$class};
    eval "require $class";
    if($@)
    {   $self->log(ERROR => "Failed for folder default $class: $@");
        $require_failed{$class}++;
        return ();
    }

    push @defaults, manager => $self;
    my $folder = $class->new(@defaults, %args);
    unless(defined $folder)
    {   $self->log(WARNING =>
           "Folder does not exist, failed opening $folder_type folder $name.")
           unless $args{access} eq 'd';
        return;
    }

    $self->log(PROGRESS => "Opened folder $name ($folder_type).");
    push @{$self->{MBM_folders}}, $folder;
    $folder;
}


sub openFolders() { @{shift->{MBM_folders}} }


sub isOpenFolder($)
{   my ($self, $name) = @_;
    first {$name eq $_->name} $self->openFolders;
}

#-------------------------------------------


sub close($@)
{   my ($self, $folder, %options) = @_;
    return unless $folder;

    my $name      = $folder->name;
    my @remaining = grep {$name ne $_->name} @{$self->{MBM_folders}};

    # folder opening failed:
    return if @{$self->{MBM_folders}} == @remaining;

    $self->{MBM_folders} = [ @remaining ];
    $_->removeFolder($folder) foreach @{$self->{MBM_threads}};

    $folder->close(close_by_manager => 1, %options)
       unless $options{close_by_self};

    $self;
}

#-------------------------------------------


sub closeAllFolders(@)
{   my ($self, @options) = @_;
    $_->close(@options) for $self->openFolders;
    $self;
}

END { map defined $_ && $_->closeAllFolders, @managers }

#-------------------------------------------

sub delete($@)
{   my ($self, $name, %args) = @_;
    my $recurse = delete $args{recursive};

    my $folder = $self->open(folder => $name, access => 'd', %args)
        or return $self;  # still successful

    $folder->delete(recursive => $recurse);
}

#-------------------------------------------

sub appendMessage(@)
{   my $self     = shift;
    my @appended = $self->appendMessages(@_);
    wantarray ? @appended : $appended[0];
}

sub appendMessages(@)
{   my $self = shift;
    my $folder;
    $folder  = shift if !ref $_[0] || $_[0]->isa('Mail::Box');

    my @messages;
    push @messages, shift while @_ && ref $_[0];

    my %options = @_;
    $folder ||= $options{folder};

    # Try to resolve filenames into opened-files.
    $folder = $self->isOpenFolder($folder) || $folder
        unless ref $folder;

    if(ref $folder)
    {   # An open file.
        unless($folder->isa('Mail::Box'))
        {   $self->log(ERROR =>
                "Folder $folder is not a Mail::Box; cannot add a message.\n");
            return ();
        }

        foreach (@messages)
        {   next unless $_->isa('Mail::Box::Message') && $_->folder;
            $self->log(WARNING =>
               "Use moveMessage() or copyMessage() to move between open folders.");
        }

        return $folder->addMessages(@messages);
    }

    # Not an open file.
    # Try to autodetect the folder-type and then add the message.

    my ($name, $class, @gen_options, $found);

    foreach (@{$self->{MBM_folder_types}})
    {   ($name, $class, @gen_options) = @$_;
        next if $require_failed{$class};
        eval "require $class";
        if($@)
        {   $require_failed{$class}++;
            next;
        }

        if($class->foundIn($folder, @gen_options, access => 'a'))
        {   $found++;
            last;
        }
    }
 
    # The folder was not found at all, so we take the default folder-type.
    my $type = $self->{MBM_default_type};
    if(!$found && $type)
    {   foreach (@{$self->{MBM_folder_types}})
        {   ($name, $class, @gen_options) = @$_;
            if($type eq $name || $type eq $class)
            {   $found++;
                last;
            }
        }
    }

    # Even the default foldertype was not found (or nor defined).
    ($name, $class, @gen_options) = @{$self->{MBM_folder_types}[0]}
        unless $found;

    $class->appendMessages
      ( type     => $name
      , messages => \@messages
      , @gen_options
      , %options
      , folder   => $folder
      );
}



sub copyMessage(@)
{   my $self   = shift;
    my $folder;
    $folder    = shift if !ref $_[0] || $_[0]->isa('Mail::Box');

    my @messages;
    while(@_ && ref $_[0])
    {   my $message = shift;
        $self->log(ERROR =>
            "Use appendMessage() to add messages which are not in a folder.")
                unless $message->isa('Mail::Box::Message');
        push @messages, $message;
    }

    my %args = @_;
    $folder ||= $args{folder};
    my $share   = exists $args{share} ? $args{share} : $args{_delete};

    # Try to resolve filenames into opened-files.
    $folder = $self->isOpenFolder($folder) || $folder
        unless ref $folder;

    unless(ref $folder)
    {   my @c = $self->appendMessages(@messages, %args, folder => $folder);
        if($args{_delete})
        {   $_->label(deleted => 1) for @messages;
        }
        return @c;
    }

    my @coerced;
    foreach my $msg (@messages)
    {   if($msg->folder eq $folder)  # ignore move to same folder
        {   push @coerced, $msg;
            next;
        }
        push @coerced, $msg->copyTo($folder, share => $args{share});
        $msg->label(deleted => 1) if $args{_delete};
    }
    @coerced;
}



sub moveMessage(@)
{   my $self = shift;
    $self->copyMessage(@_, _delete => 1);
}

#-------------------------------------------

sub threads(@)
{   my $self    = shift;
    my @folders;
    push @folders, shift
       while @_ && ref $_[0] && $_[0]->isa('Mail::Box');
    my %args    = @_;

    my $base    = 'Mail::Box::Thread::Manager';
    my $type    = $args{threader_type} || $base;

    my $folders = delete $args{folder} || delete $args{folders};
    push @folders
     , ( !$folders               ? ()
       : ref $folders eq 'ARRAY' ? @$folders
       :                           $folders
       );

    $self->log(INTERNAL => "No folders specified.")
       unless @folders;

    my $threads;
    if(ref $type)
    {   # Already prepared object.
        $self->log(INTERNAL => "You need to pass a $base derived")
            unless $type->isa($base);
        $threads = $type;
    }
    else
    {   # Create an object.  The code is compiled, which safes us the
        # need to compile Mail::Box::Thread::Manager when no threads are needed.
        eval "require $type";
        $self->log(INTERNAL => "Unusable threader $type: $@") if $@;

        $self->log(INTERNAL => "You need to pass a $base derived")
            unless $type->isa($base);

        $threads = $type->new(manager => $self, %args);
    }

    $threads->includeFolder($_) foreach @folders;
    push @{$self->{MBM_threads}}, $threads;
    $threads;
}

#-------------------------------------------

sub toBeThreaded($@)
{   my $self = shift;
    $_->toBeThreaded(@_) foreach @{$self->{MBM_threads}};
}


sub toBeUnthreaded($@)
{   my $self = shift;
    $_->toBeUnthreaded(@_) foreach @{$self->{MBM_threads}};
}


sub decodeFolderURL($)
{   my ($self, $name) = @_;

    return unless
       my ($type, $username, $password, $hostname, $port, $path)
          = $name =~ m!^(\w+)\:             # protocol
                       (?://
                          (?:([^:@/]*)      # username
                            (?:\:([^@/]*))? # password
                           \@)?
                           ([\w.-]+)?       # hostname
                           (?:\:(\d+))?     # port number
                        )?
                        (.*)                # foldername
                      !x;

    $username ||= $ENV{USER} || $ENV{LOGNAME};
    $password ||= '';

    for($username, $password)
    {   s/\+/ /g;
        s/\%([A-Fa-f0-9]{2})/chr hex $1/ge;
    }

    $hostname ||= 'localhost';

    $path     ||= '=';

    ( type        => $type,     folder      => $path
    , username    => $username, password    => $password
    , server_name => $hostname, server_port => $port
    );
}

#-------------------------------------------

1;

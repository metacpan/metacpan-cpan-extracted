# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;
use warnings;

package Mail::Server::IMAP4::User;
use vars '$VERSION';
$VERSION = '3.002';

use base 'Mail::Box::Manage::User';


sub init($)
{   my ($self, $args) = @_;
    
    $self->SUPER::init($args) or return ();

    my $fn = $args->{indexfile};
    $self->{MSNU_indexfile}
        = defined $fn ? $fn : ($self->folderdir . '/index');

    $self;
}

#-------------------------------------------


sub indexFilename() { shift->{MSNU_indexfile} };

#-------------------------------------------


sub folderInfo($)
{   my $index = shift->index or return ();
    $index->folder(shift);
}

#-------------------------------------------


sub delete($)
{   my ($self, $name) = @_;
    my $index = $self->index->startModify or return 0;

    unless($self->_delete($index, $name))
    {   $self->cancelModification($index);
        return 0;
    }

    $index->write;
}

sub _delete($$)
{   my ($self, $index, $name) = @_;

    # First clean all subfolders recursively
    foreach my $subf ($index->subfolders($name))
    {   $self->_delete($index, $subf) or return 0;
    }

    # Already disappeared?  Shouldn't happen, but ok
    my $info  = $index->folder($name)
        or return 1;

    # Bluntly clean-out the directory
    if(my $dir = $info->{Directory})
    {   # Bluntly try to remove, but error is not set
        if(remove(\1, $dir) != 0 && -d $dir)
        {   $self->log(error => "Unable to remove folder $dir");
            return 0;
        }
    }

    # Remove (sub)folder from index
    $index->folder($name, undef);
    1;
}

#-------------------------------------------


sub create($@)
{   my ($self, $name) = (shift, shift);
    my $index   = $self->index->startModify or return undef;

    if(my $info = $index->folder($name))
    {   $self->log(WARNING => "Folder $name already exists, creation skipped");
        return $info;
    }

    my $uniq    = $index->createUnique;

    # Create the directory
    # Also in this case, we bluntly try to create it, and when it doesn't
    # work, we check whether we did too much. This may safe an NFS stat.

    my $dir     = $self->home . '/F' . $uniq;
    unless(mkdir $dir, 0750)
    {   my $rc = "$!";
        unless(-d $dir)   # replaces $!
        {   $self->log(ERROR => "Cannot create folder directory $dir: $rc");
            return undef;
        }
    }

    # Write folder name in directory, for recovery purposes.
    my $namefile = "$dir/name";
    unless(open NAME, '>:encoding(utf-8)', $namefile)
    {   $self->log(ERROR => "Cannot write name for folder in $namefile: $!");
        return undef;
    }

    print NAME "$name\n";

    unless(close NAME)
    {   $self->log(ERROR => "Failed writing folder name to $namefile: $!");
        return undef;
    }

    # Add folder to the index

    my $facts = $self->folder
     ( $name
     , Folder    => $name
     , Directory => $dir
     , Messages  => 0
     , Size      => 0
     );

   $self->write && $facts;
}

#-------------------------------------------


1;

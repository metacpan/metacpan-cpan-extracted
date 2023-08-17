# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Identity;
use vars '$VERSION';
$VERSION = '3.010';

use base qw/User::Identity::Item Mail::Reporter/;

use strict;
use warnings;

use Mail::Box::Collection;

# tests in tests/52message/30collect.t


sub type { "mailbox" }


sub new(@)
{   my $class = shift;
    unshift @_, 'name' if @_ % 2;
    $class->Mail::Reporter::new(@_);
}

sub init($)
{   my ($self, $args) = @_;

    $self->Mail::Reporter::init($args);
    $self->User::Identity::init($args);

    $self->{MBI_location}  = delete $args->{location};
    $self->{MBI_ftype}     = delete $args->{folder_type};
    $self->{MBI_manager}   = delete $args->{manager};
    $self->{MBI_subf_type} = delete $args->{subf_type}||'Mail::Box::Collection';
    $self->{MBI_only_subs} = delete $args->{only_subs};
    $self->{MBI_marked}    = delete $args->{marked};
    $self->{MBI_deleted}   = delete $args->{deleted};
    $self->{MBI_inferiors} = exists $args->{inferiors} ? $args->{inferiors} : 1;

    $self;
}

#-------------------------------------------


sub fullname(;$)
{   my $self   = shift;
    my $delim  = @_ && defined $_[0] ? shift : '/';

    my $parent = $self->parent or return $self->name;
    $parent->parent->fullname($delim) . $delim . $self->name;
}



sub location(;$)
{   my $self = shift;
    return ($self->{MBI_location} = shift) if @_;
    return $self->{MBI_location} if defined $self->{MBI_location};

    my $parent = $self->parent;
    unless(defined $parent)
    {   $self->log(ERROR => "Toplevel directory requires explicit location");
        return undef;
    }

    $self->folderType
         ->nameOfSubFolder($self->name, $parent->parent->location)
}



sub folderType()
{   my $self = shift;
    return $self->{MBI_ftype} if defined $self->{MBI_ftype};

    my $parent = $self->parent;
    unless(defined $parent)
    {   $self->log(ERROR => "Toplevel directory requires explicit folder type");
        return undef;
    }

    $parent->parent->folderType;
}



sub manager()
{    my $self = shift;
     return $self->{MBI_manager} if $self->{MBI_manager};
     my $parent = $self->parent or return undef;
     $self->parent->manager;
}



sub topfolder()
{   my $self = shift;
    my $parent = $self->parent or return $self;
    $parent->parent->topfolder;
}



sub onlySubfolders(;$)
{   my $self = shift;
    return($self->{MBI_only_subs} = shift) if @_;
    return $self->{MBI_only_subs} if exists $self->{MBI_only_subs};
    $self->parent ? 1 : ! $self->folderType->topFolderWithMessages;
}



sub marked(;$)
{   my $self = shift;
    @_ ? ($self->{MBI_marked} = shift) : $self->{MBI_marked};
}



sub inferiors(;$)
{   my $self = shift;
    @_ ? ($self->{MBI_inferiors} = shift) : $self->{MBI_inferiors};
}



sub deleted(;$)
{   my $self = shift;
    @_ ? ($self->{MBI_deleted} = shift) : $self->{MBI_deleted};
}
                                                                                
#-------------------------------------------


sub subfolders()
{   my $self = shift;
    my $subs = $self->collection('subfolders');
    return (wantarray ? $subs->roles : $subs)
        if defined $subs;

    my @subs;
    if(my $location = $self->location)
    {   @subs  = $self->folderType->listSubFolders
         ( folder    => $location
         );
    }
    else
    {   my $mgr   = $self->manager;
        my $top   = defined $mgr ? $mgr->folderdir : '.';

        @subs  = $self->folderType->listSubFolders
          ( folder    => $self->fullname
          , folderdir => $top
          );
    }
    @subs or return ();

    my $subf_type
      = $self->{MBI_subf_type} || ref($self->parent) || 'Mail::Box::Collection';

    $subs = $subf_type->new('subfolders');

    $self->addCollection($subs);
    $subs->addRole(name => $_) for @subs;
    wantarray ? $subs->roles : $subs;
}



sub subfolderNames() { map {$_->name} shift->subfolders }



sub folder(@)
{   my $self = shift;
    return $self unless @_ && defined $_[0];

    my $subs = $self->subfolders  or return undef;
    my $nest = $subs->find(shift) or return undef;
    $nest->folder(@_);
}



sub open(@)
{   my $self = shift;
    $self->manager->open($self->fullname, type => $self->folderType, @_);
}



sub foreach($)
{   my ($self, $code) = @_;
    $code->($self);

    my $subs = $self->subfolders or return ();
    $_->foreach($code) for $subs->sorted;
    $self;
}



sub addSubfolder(@)
{   my $self  = shift;
    my $subs  = $self->subfolders;

    if(defined $subs) { ; }
    elsif(!$self->inferiors)
    {   my $name = $self->fullname;
        $self->log(ERROR => "It is not permitted to add subfolders to $name");
        return undef;
    }
    else
    {   $subs = $self->{MBI_subf_type}->new('subfolders');
        $self->addCollection($subs);
    }

    $subs->addRole(@_);
}



sub remove(;$)
{   my $self = shift;

    my $parent = $self->parent;
    unless(defined $parent)
    {   $self->log(ERROR => "The toplevel folder cannot be removed this way");
        return ();
    }

    return $parent->removeRole($self->name)
        unless @_;

    my $name = shift;
    my $subs = $self->subfolders or return ();
    $subs->removeRole($name);
}



sub rename($;$)
{   my ($self, $folder, $newname) = @_;
    $newname = $self->name unless defined $newname;

    my $away = $self->remove;
    $away->name($newname);

    $folder->addSubfolder($away);
}

#-------------------------------------------


1;



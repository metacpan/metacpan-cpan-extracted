# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Manage::User;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Box::Manager';

use strict;
use warnings;

use Mail::Box::Collection     ();

#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return ();

    my $identity = $self->{MBMU_id} = $args->{identity};
    defined $identity or die;

    my $top     = $args->{folder_id_type}  || 'Mail::Box::Identity';
    my $coltype = $args->{collection_type} || 'Mail::Box::Collection';

    unless(ref $top)
    {   my $name = $args->{topfolder_name};
        $name    = '=' unless defined $name;   # MailBox's abbrev to top

        $top     = $top->new
         ( name        => $name
         , manager     => $self
         , location    => scalar($self->folderdir)
         , folder_type => $self->defaultFolderType
         , collection_type => $coltype
         );
    }

    $self->{MBMU_topfolder} = $top;
    $self->{MBMU_delim}     = $args->{delimiter} || '/';
    $self->{MBMU_inbox}     = $args->{inbox};

    $self;
}

#-------------------------------------------


sub identity() { shift->{MBMU_id} }

#-------------------------------------------


sub inbox(;$)
{   my $self = shift;
    @_ ? ($self->{MBMU_inbox} = shift) : $self->{MBMU_inbox};
}

#-------------------------------------------


# A lot of work still has to be done here: all moves etc must inform
# the "existence" administration as well.

#-------------------------------------------


sub topfolder() { shift->{MBMU_topfolder} }



sub folder($)
{   my ($self, $name) = @_;
    my $top  = $self->topfolder or return ();
    my @path = split $self->{MBMU_delim}, $name;
    return () unless shift @path eq $top->name;

    $top->folder(@path);
}



sub folderCollection($)
{   my ($self, $name) = @_;
    my $top  = $self->topfolder or return ();

    my @path = split $self->{MBMU_delim}, $name;
    unless(shift @path eq $top->name)
    {   $self->log(ERROR => "Folder name $name not under top.");
        return ();
    }

    my $base = pop @path;

    ($top->folder(@path), $base);
}



# This feature is thoroughly tested in the Mail::Box::Netzwert distribution

sub create($@)
{   my ($self, $name, %args) = @_;
    my ($dir, $base) = $self->folderCollection($name);

    unless(defined $dir)
    {   unless($args{create_supers})
        {   $self->log(ERROR => "Cannot create $name: higher levels missing");
            return undef;
        }

        (my $upper = $name) =~ s!$self->{MBMU_delim}$base!!
             or die "$name - $base";

        $dir = $self->create($upper, %args, deleted => 1);
    }

    my $id = $dir->folder($base);
    if(!defined $id)
    {   my $idopt= $args{id_options} || [];
        $id  = $dir->addSubfolder($base, @$idopt, deleted => $args{deleted});
    }
    elsif($args{deleted})
    {   $id->deleted(1);
        return $id;
    }
    elsif($id->deleted)
    {   # Revive! Raise the death!
        $id->deleted(0);
    }
    else
    {   # Bumped into existing folder
        $self->log(ERROR => "Folder $name already exists");
        return undef;
    }

    if(!defined $args{create_real} || $args{create_real})
    {   $self->defaultFolderType->create($id->location, %args)
           or return undef;
    }

    $id;
}

                                                                                

sub delete($)
{   my ($self, $name) = @_;
    my $id = $self->folder($name) or return ();
    $id->remove;

    $self->SUPER::delete($name);
}



sub rename($$@)
{   my ($self, $oldname, $newname, %args) = @_;

    my $old     = $self->folder($oldname);
    unless(defined $old)
    {   $self->log(WARNING
            => "Source for rename does not exist: $oldname to $newname");
        return ();
    }

    my ($newdir, $base) = $self->folderCollection($newname);
    unless(defined $newdir)
    {   unless($args{create_supers})
        {   $self->log(ERROR
               => "Cannot rename $oldname to $newname: higher levels missing");
            return ();
        }

        (my $upper = $newname) =~ s!$self->{MBMU_delim}$base!!
             or die "$newname - $base";

        $newdir = $self->create($upper, %args, deleted => 1);
    }

    my $oldlocation = $old->location;
    my $new         = $old->rename($newdir, $base);

    my $newlocation = $new->location;
    if($oldlocation ne $newlocation)
    {   require Carp;
        croak("Physical folder relocation not yet implemented");
# this needs a $old->rename(xx,yy) which isn't implemented yet
    }

    $self->log(PROGRESS => "Renamed folder $oldname to $newname");
    $new;
}

#-------------------------------------------


1;

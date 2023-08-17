# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Server::IMAP4::List;
use vars '$VERSION';
$VERSION = '3.008';


use strict;
use warnings;


sub new($)
{   my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $user = $self->{MSIL_user}  = $args{user};
    $self->{MSIL_folders} = $args{folders};
    $self->{MSIL_inbox}   = $args{inbox};
    $self->{MSIL_delim}   = exists $args{delimiter} ? $args{delimiter} : '/';
    $self;
}

#------------------------------------------


sub delimiter(;$)
{   my $delim = shift->{MSIL_delim};
    ref $delim ? $delim->(shift) : $delim;
}

#------------------------------------------


sub user() { shift->{MSIL_user} }

#------------------------------------------


sub folders()
{   my $self = shift;
    $self->{MSIL_folders} || $self->user->topfolder;
}

#------------------------------------------


sub inbox()
{   my $self = shift;
    $self->{MSIL_inbox} || $self->user->inbox;
}

#------------------------------------------


sub list($$)
{   my ($self, $base, $pattern) = @_;
    
    return [ '(\Noselect)', $self->delimiter($base), '' ]
       if $pattern eq '';

    my $delim  = $self->delimiter($base);
    my @path   = split $delim, $base;
    my $folder = $self->folders;

    while(@path && defined $folder)
    {   $folder = $folder->folder(shift @path);
    }
    defined $folder or return ();

    my @pattern = split $delim, $pattern;
    return $self->_list($folder, $delim, @pattern);
}

sub _list($$@)
{   my ($self, $folder, $delim) = (shift, shift, shift);

    if(!@_)
    {   my @flags;
        push @flags, '\Noselect'
           if $folder->onlySubfolders || $folder->deleted;

        push @flags, '\Noinferiors' unless $folder->inferiors;
        my $marked = $folder->marked;
        push @flags, ($marked ? '\Marked' : '\Unmarked')
            if defined $marked;

        local $" = ' ';

        # This is not always correct... should compose the name from the
        # parts... but in nearly all cases, the following is sufficient.
        my $name = $folder->fullname;
        for($name)
        {    s/^=//;
             s![/\\]!$delim!g;
        }
        return [ "(@flags)", $delim, $name ];
    }

    my $pat = shift;
    if($pat eq '%')
    {   my $subs = $folder->subfolders
             or return $self->_list($folder, $delim);
        return map { $self->_list($_, $delim, @_) } $subs->sorted;
    }

    if($pat eq '*')
    {   my @own = $self->_list($folder, $delim, @_);
        my $subs = $folder->subfolders or return @own;
        return @own, map { $self->_list($_, $delim, '*', @_) } $subs->sorted;
    }

    $folder = $folder->find(subfolders => $pat) or return ();
    $self->_list($folder, $delim, @_);
}

#------------------------------------------


1;

# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Collection;
use vars '$VERSION';
$VERSION = '3.010';

use base qw/User::Identity::Collection Mail::Reporter/;

use strict;
use warnings;

use Mail::Box::Identity;

use Scalar::Util    qw/weaken/;


sub new(@)
{   my $class = shift;
    unshift  @_,'name' if @_ % 2;
    $class->Mail::Reporter::new(@_);
}
                                                                                
sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'Mail::Box::Identity';

    $self->Mail::Reporter::init($args);
    $self->User::Identity::Collection::init($args);
                                                                                
    weaken($self->{MBC_manager})
       if $self->{MBC_manager}  = delete $args->{manager};
    
    $self->{MBC_ftype}    = delete $args->{folder_type};
    $self;
}

sub type() { 'folders' }

#------------------------------------------


sub manager()
{   my $self = shift;
    return $self->{MBC_manager}
        if defined $self->{MBC_manager};

    my $parent = $self->parent;
    defined $parent ? $self->parent->manager : undef;
}

#------------------------------------------


sub folderType()
{   my $self = shift;
    return($self->{MBC_ftype} = shift) if @_;
    return $self->{MBC_ftype} if exists $self->{MBC_ftype};

    if(my $parent = $self->parent)
    {   return $self->{MBC_ftype} = $parent->folderType;
    }

    undef;
}

#------------------------------------------

1;


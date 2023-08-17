# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Locker;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use Scalar::Util 'weaken';
use Devel::GlobalDestruction 'in_global_destruction';

#-------------------------------------------


my %lockers =
  ( DOTLOCK   => __PACKAGE__ .'::DotLock'
  , FCNTLLOCK => __PACKAGE__ .'::FcntlLock'
  , FLOCK     => __PACKAGE__ .'::Flock'
  , MULTI     => __PACKAGE__ .'::Multi'
  , MUTT      => __PACKAGE__ .'::Mutt'
  , NFS       => __PACKAGE__ .'::NFS'
  , NONE      => __PACKAGE__
  , POSIX     => __PACKAGE__ .'::POSIX'
  );

sub new(@)
{   my $class  = shift;

    return $class->SUPER::new(@_)
        unless $class eq __PACKAGE__;

    # Try to figure out which locking method we really want (bootstrap)

    my %args   = @_;
    my $method = !defined $args{method}       ? 'DOTLOCK'
               : ref $args{method} eq 'ARRAY' ? 'MULTI'
               :                                 uc $args{method};

    my $create = $lockers{$method} || $args{$method};

    local $"   = ' or ';
    confess "No locking method $method defined: use @{[ keys %lockers ]}"
        unless $create;

    # compile the locking module (if needed)
    eval "require $create";
    confess $@ if $@;

    $args{use} = $args{method} if ref $args{method} eq 'ARRAY';

    $create->SUPER::new(%args);
}

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    $self->{MBL_expires}  = $args->{expires}   || 3600;  # one hour
    $self->{MBL_timeout}  = $args->{timeout}   || 10;    # ten secs
    $self->{MBL_filename} = $args->{file}      || $args->{folder}->name;
    $self->{MBL_has_lock} = 0;

    $self->folder($args->{folder});
    $self;
}

#-------------------------------------------


sub timeout(;$)
{   my $self = shift;
    @_ ? $self->{MBL_timeout} = shift : $self->{MBL_timeout};
}

sub expires(;$)
{   my $self = shift;
    @_ ? $self->{MBL_expires} = shift : $self->{MBL_expires};
}

#-------------------------------------------


sub name {shift->notImplemented}

sub lockMethod($$$$)
{   confess "Method removed: use inheritance to implement own method."
}


sub folder(;$)
{   my $self = shift;
    @_ && $_[0] or return $self->{MBL_folder};

    $self->{MBL_folder} = shift;
    weaken $self->{MBL_folder};
}


sub filename(;$)
{   my $self = shift;
    $self->{MBL_filename} = shift if @_;
    $self->{MBL_filename};
}

#-------------------------------------------


sub lock($) { shift->{MBL_has_lock} = 1 }


sub isLocked($) {0}


sub hasLock() {shift->{MBL_has_lock}}


# implementation hazard: the unlock must be self-reliant, without
# help by the folder, because it may be called at global destruction
# after the folder has been removed.

sub unlock() { shift->{MBL_has_lock} = 0 }

#-------------------------------------------


sub DESTROY()
{   my $self = shift;
    return $self if in_global_destruction;

    $self->unlock if $self->hasLock;
    $self->SUPER::DESTROY;
    $self;
}

1;

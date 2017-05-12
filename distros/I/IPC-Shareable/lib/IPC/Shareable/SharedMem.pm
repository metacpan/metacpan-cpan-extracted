package IPC::Shareable::SharedMem;

use strict;
use constant DEBUGGING => ($ENV{SHM_DEBUG} or 0);
use IPC::SysV qw(IPC_RMID);

my $Def_Size = 1024;

sub _trace {
    require Carp;
    require Data::Dumper;
    my $caller = '    ' . (caller(1))[3] . " called with:\n";
    my $i = -1;
    my @msg = map {
        ++$i;
        '        ' . Data::Dumper->Dump( [ $_ ] => [ "\_[$i]" ]);
    }  @_;
    Carp::carp "IPC::SharedMem debug:\n", $caller, @msg;
}

sub _debug {
    require Carp;
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    my $caller = '    ' . (caller(1))[3] . " tells us that:\n";
    my @msg = map { '        ' . Data::Dumper::Dumper($_) } @_;
    Carp::carp "IPC::SharedMem debug:\n", $caller, @msg;
};

sub default_size {
    _trace @_                                                   if DEBUGGING;
    my $class = shift;
    $Def_Size = shift if @_;
    return $Def_Size;
}

sub new {
    _trace @_                                                   if DEBUGGING;
    my($class, $key, $size, $flags) = @_;
    defined $key or do {
        require Carp;
        Carp::croak "usage: IPC::SharedMem->new(KEY, [ SIZE,  [ FLAGS ] ])";
    };
    $size  ||= $Def_Size;
    $flags ||= 0;
    
    _debug "calling shmget() on ", $key, $size, $flags          if DEBUGGING;
    my $id = shmget($key, $size, $flags);
    defined $id or do {
        require Carp;
        Carp::carp "IPC::Shareable::SharedMem: shmget: $!\n";
        return undef;
    };

    my $sh = {
        _id    => $id,
        _size  => $size,
        _flags => $flags,
    };
    
    return bless $sh => $class;
}

sub id {
    _trace @_                                                   if DEBUGGING;
    my $self = shift;

    $self->{_id} = shift if @_;
    return $self->{_id};
}

sub flags {
    _trace @_                                                   if DEBUGGING;
    my $self = shift;

    $self->{_flags} = shift if @_;
    return $self->{_flags};
}

sub size {
    _trace @_                                                   if DEBUGGING;
    my $self = shift;

    $self->{_size} = shift if @_;
    return $self->{_size};
}

sub shmwrite {
    _trace @_                                                   if DEBUGGING;
    my($self, $data) = @_;

    _debug "calling shmwrite() on ", $self->{_id}, $data,
                                     0, $self->{_size}          if DEBUGGING;
    return shmwrite($self->{_id}, $data, 0, $self->{_size});
}

sub shmread {
    _trace @_                                                   if DEBUGGING;
    my $self = shift;

    my $data = '';
    _debug "calling shread() on ", $self->{_id}, $data,
                                   0, $self->{_size}            if DEBUGGING;
    shmread($self->{_id}, $data, 0, $self->{_size}) or return;
    _debug "got ", $data, " from shm segment $self->{_id}"      if DEBUGGING;
    return $data;
}

sub remove {
    _trace @_                                                   if DEBUGGING;
    my $self = shift;
    my $op = shift;
    my $arg = 0;

    return shmctl($self->{_id}, IPC_RMID, $arg);
}

1;

=head1 NAME

IPC::Shareable::SharedMem - Object oriented interface to shared memory

=head1 SYNOPSIS

 *** No public interface ***

=head1 WARNING

This module is not intended for public consumption.  It is used
internally by IPC::Shareable to access shared memory.  It will
probably be replaced soon by IPC::ShareLite or IPC::SharedMem (when
someone writes it).

=head1 DESCRIPTION

This module provides and object-oriented framework to access shared
memory.  Its use is intended to be limited to IPC::Shareable.
Therefore I have not documented an interface.

=head1 AUTHOR

Ben Sugars (bsugars@canoe.ca)

=head1 SEE ALSO

IPC::Shareable, IPC::SharedLite

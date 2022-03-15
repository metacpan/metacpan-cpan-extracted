package IPC::Shareable::SharedMem;

use warnings;
use strict;

use Carp qw(carp croak confess);
use IPC::SysV qw(IPC_RMID);

our $VERSION = '1.12';

use constant DEBUGGING => ($ENV{SHM_DEBUG} or 0);

my $default_size = 1024;

sub default_size {
    my $class = shift;
    $default_size = shift if @_;
    return $default_size;
}

sub new {
    my($class, $key, $size, $flags, $type) = @_;

    defined $key or do {
        confess "usage: IPC::SharedMem->new(KEY, [ SIZE,  [ FLAGS ] ])";
    };

    $size  ||= $default_size;
    $flags ||= 0;

    my $id = shmget($key, $size, $flags);

    defined $id or do {
        if ($! =~ /File exists/){
            croak "\nERROR: IPC::Shareable::SharedMem: shmget $key: $!\n\n" .
                  "Are you using exclusive, but trying to create multiple " .
                  "instances?\n\n";
        }
        return undef;
    };

    my $sh = {
        _id    => $id,
        _key   => $key,
        _size  => $size,
        _flags => $flags,
        _type  => $type,
    };

    return bless $sh => $class;
}
sub id {
    my $self = shift;

    $self->{_id} = shift if @_;
    return $self->{_id};
}
sub key {
    my $self = shift;

    $self->{_key} = shift if @_;
    return $self->{_key};
}
sub flags {
    my $self = shift;

    $self->{_flags} = shift if @_;
    return $self->{_flags};
}
sub size {
    my $self = shift;

    $self->{_size} = shift if @_;
    return $self->{_size};
}
sub type {
    my $self = shift;

    $self->{_type} = shift if @_;
    return $self->{_type};
}
sub shmwrite {
    my($self, $data) = @_;
    return shmwrite($self->{_id}, $data, 0, $self->{_size});
}
sub shmread {
    my $self = shift;

    my $data = '';
    shmread($self->{_id}, $data, 0, $self->{_size}) or return;
    return $data;
}
sub remove {
    my $to_remove = shift;

    my $id;

    if (ref $to_remove eq __PACKAGE__){
        $id = $to_remove->{_id};
    }

    my $arg = 0;

    my $ret = shmctl($id, IPC_RMID, $arg);
    return $ret;
}

1;

=head1 NAME

IPC::Shareable::SharedMem - Object oriented interface to shared memory

=for html
<a href="https://github.com/stevieb9/ipc-shareable/actions"><img src="https://github.com/stevieb9/ipc-shareable/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/ipc-shareable?branch=master'><img src='https://coveralls.io/repos/stevieb9/ipc-shareable/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

 *** No public interface ***

=head1 WARNING

This module is not intended for public consumption.  It is used
internally by IPC::Shareable to access shared memory.

=head1 DESCRIPTION

This module provides and object-oriented framework to access shared
memory.  Its use is intended to be limited to IPC::Shareable.
Therefore I have not documented an interface.

=head1 AUTHOR

Ben Sugars (bsugars@canoe.ca)

=head1 SEE ALSO

L<IPC::Shareable>, L<IPC::ShareLite>

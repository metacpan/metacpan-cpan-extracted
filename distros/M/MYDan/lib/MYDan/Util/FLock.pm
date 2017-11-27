package MYDan::Util::FLock;

=head1 NAME

MYDan::Util::FLock - flock

=head1 SYNOPSIS

 use MYDan::Util::FLock;

 my $lock = MYDan::Util::FLock->new( '/lock/file' );

 die "Locked by other processes.\n" unless $lock->lock();

 $lock->unlock();
 
=cut

use strict;
use warnings;
use Carp;
use Fcntl qw( :flock );

sub new
{
    my ( $class, $file, $self ) = splice @_, 0, 2;

    confess "open $file: $!" unless open $self->{fh}, '+>', $file;

    bless $self, ref $class || $class;
}

sub lock
{
    flock shift->{fh}, LOCK_EX | LOCK_NB;
}

sub unlock
{
    flock(shift->{fh}, LOCK_UN) or die "Cannot unlock $!\n";
}
 
1;

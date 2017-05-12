package IO::LockedFile::Flock;
use strict;
use Fcntl ':flock'; # import LOCK_* constants
use Carp;
use vars qw( @ISA );
@ISA = qw( IO::LockedFile );

######################
# lock
######################
sub lock {
    my $self = shift;

    my $lock_type = $self->is_writable() ? LOCK_EX : LOCK_SH;

    my $got_lock = 0;

    if ( ! $self->should_block() ) {
        $got_lock = flock( $self, $lock_type | LOCK_NB );
    }
    else {
        $got_lock =  flock($self, $lock_type)
            or croak( "Cannot lock: $!");
    }

    $self->SUPER::lock() if ($got_lock);
    return $got_lock;
}

######################
# unlock
######################
sub unlock {
    my $self = shift;
    flock($self, LOCK_UN);
#        or croak( ref( $self ) . ": Cannot unlock: $!");
    $self->SUPER::unlock;
}

1;


__END__

###########################################################################

=head1 NAME

IO::LockedFile::Flock Class implements the IO::LockedFile class for the 
Flock scheme.

=head1 SYNOPSIS

  See IO::LockedFile;

=head1 DESCRIPTION

This class implements the two methods lock and unlock for the Flock scheme.

=head1 AUTHORS

Rani Pinchuk, rani@cpan.org

Rob Napier, rnapier@employees.org

=head1 COPYRIGHT

Copyright (c) 2001-2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::File(3)>,
L<IO::LockedFile(3)>

=cut












package File::Monitor::Object::Linux;

use strict;
use warnings;
use Carp;
use File::Spec;
use Fcntl ':mode';

use File::Monitor::Delta;

use base qw(File::Monitor::Object);

use version; our $VERSION = qv('0.0.2');

# Items read from /proc/sys/fs/inotify/*
my %limits;

# Called during File::Monitor::Object loading to decide
# whether we can stand in for File::Monitor::Object.
# If we can we return the classname that should used
# instead of File::Monitor::Object. If we can't start
# up we return undef.
sub _stand_in {
    return;
    # eval "use Linux::Inotify2";
    # return if $@;
    # 
    # # for my $lim (qw(max_queued_events max_user_instances max_user_watches)) {
    # #     my $name = "/proc/sys/fs/inotify/$lim";
    # #     warn "Reading $name\n";
    # #     unless (open(my $lh, '<', $name)) {
    # #         die "Can't read $name ($!)\n";
    # #         next;
    # #     }
    # #         
    # #     defined(my $val = <$lh>) or return;
    # #     chomp($val);
    # #     $limits{$lim} = $val;
    # #     warn "$lim = $val\n";
    # #     close($lh);
    # # }
    # 
    # return __PACKAGE__;
}

sub _initialize {
    my $self = shift;
    my $args;

    $self->SUPER::_initialize( @_ );
}

1;

=head1 NAME

File::Monitor::Object::Linux - Monitor a Linux filesystem object for changes.

=head1 VERSION

This document describes File::Monitor::Object::Linux version 0.0.2

=head1 SYNOPSIS

Not used directly.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Faycal Chraibi originally registered the File::Monitor namespace and
then kindly handed it to me.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

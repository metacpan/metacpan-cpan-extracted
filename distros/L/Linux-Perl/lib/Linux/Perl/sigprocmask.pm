package Linux::Perl::sigprocmask;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::sigprocmask

=head1 SYNOPSIS

    # These all return the complete former signal mask (as numbers)
    # when called in list context.
    @oldlist = Linux::Perl::sigprocmask->block( 2, 'USR1' );

    Linux::Perl::sigprocmask->block( 2, 'USR1' );

    Linux::Perl::sigprocmask->unblock( 2, 'USR1' );

    Linux::Perl::sigprocmask->set( 2, 'USR1' );

=head1 DESCRIPTION

An implementation of the kernel’s logic to set the signal mask.

=cut

use parent 'Linux::Perl::Base';

use Linux::Perl;
use Linux::Perl::SigSet;

use constant {
    _SIG_BLOCK => 0,
    _SIG_UNBLOCK => 1,
    _SIG_SETMASK => 2,
};

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->block( @SIGNALS )

Add to the list of currently blocked signals.

The return in list context is the group of signals that,
prior to this function call, were blocked. (Signals are
referenced by number only.)

=cut

sub block {
    return $_[0]->_do(
        _SIG_BLOCK(),
        @_[ 1 .. $#_ ],
    );
}

#----------------------------------------------------------------------

=head2 I<CLASS>->unblock( @SIGNALS )

The inverse of C<block()>.

=cut

sub unblock {
    return $_[0]->_do(
        _SIG_UNBLOCK(),
        @_[ 1 .. $#_ ],
    );
}

#----------------------------------------------------------------------

=head2 I<CLASS>->set( @SIGNALS )

Like C<block()> and C<unblock()> but sets/clobbers the entire set
of blocked signals.

=cut

sub set {
    return $_[0]->_do(
        _SIG_SETMASK(),
        @_[ 1 .. $#_ ],
    );
}

#----------------------------------------------------------------------

sub _do {
    my ($class, $how, @signals) = @_;

    my $mask = Linux::Perl::SigSet::from_list(@signals);

    my $oldmask = "\0" x length($mask);

    my $arch_module = $class->_get_arch_module();

    Linux::Perl::call(
        $arch_module->NR_rt_sigprocmask(),
        0 + $how,
        $mask,
        $oldmask,
        length $mask,
    );

    return wantarray ? Linux::Perl::SigSet::to_list($oldmask) : undef;
}


1;

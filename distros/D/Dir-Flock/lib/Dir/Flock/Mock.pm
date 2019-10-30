package Dir::Flock::Mock;
use strict;
use warnings;
use Carp;
use File::Temp;
use Time::HiRes 1.92;
use Fcntl ':flock';
use Data::Dumper;    # when debugging is on

our $_DEBUG = $ENV{DEBUG} || $ENV{DIR_FLOCK_DEBUG} || 0;
our %LOCK;

### core functions

*Dir::Flock::lock = *lock;
*Dir::Flock::lock_ex = *lock_ex;
*Dir::Flock::lock_sh = *lock_sh;
*Dir::Flock::unlock = *unlock;

*_pid = *Dir::Flock::_pid;
*_validate_dir = *Dir::Flock::_validate_dir;

sub lock { goto &lock_ex }

sub lock_ex {
    my ($dir, $timeout) = @_;
    $Dir::Flock::errstr = "";
    return if !_validate_dir($dir);
    my $P = $_DEBUG && _pid();
    my $now = Time::HiRes::time;
    my $last_check = $now;
    my $expire = $now + ($timeout || 0);
    open my $fh, ">>", "$dir/_lock_";
    if (defined $timeout) {
        $_DEBUG && print STDERR "$P locking $dir\n";
        my $z = flock $fh, LOCK_EX | LOCK_NB;
        if ($z) {
            $_DEBUG && print STDERR "$P locked $dir\n";
            $LOCK{$dir}{_pid()} = $fh;
            return $z;
        }
        $_DEBUG && print STDERR "$P lock $dir failed\n";
        if (Time::HiRes::time > $expire) {
            $Dir::Flock::errstr =
                "timeout waiting for exclusive lock for '$dir'";
            $_DEBUG && print STDERR "$P lock $dir timed out\n";
            return;
        }
        Time::HiRes::sleep $Dir::Flock::PAUSE_LENGTH;
        redo;
    } else {
        local $! = 0;
        $_DEBUG && print STDERR "$P locking $dir\n";
        my $z = flock $fh, LOCK_EX;
        if ($z) {
            $LOCK{$dir}{_pid()} = $fh;
            $_DEBUG && print STDERR "$P locked $dir\n";
            return $z;
        }
        $Dir::Flock::errstr = "flock failed: $!";
        $_DEBUG && print STDERR "$P lock $dir failed\n";
        return;
    }
}

sub lock_sh {
    my ($dir, $timeout) = @_;
    $Dir::Flock::errstr = "";
    return if !_validate_dir($dir);
    my $P = $_DEBUG && _pid();
    my $now = Time::HiRes::time;
    my $last_check = $now;
    my $expire = $now + ($timeout || 0);
    open my $fh, ">>", "$dir/_lock_";
    if ($timeout) {
        my $z = flock $fh, LOCK_SH | LOCK_NB;
        if ($z) {
            $LOCK{$dir}{_pid()} = $fh;
            return $z;
        }
        if (Time::HiRes::time > $expire) {
            $Dir::Flock::errstr =
                "timeout waiting for exclusive lock for '$dir'";
            return;
        }
        Time::HiRes::sleep $Dir::Flock::PAUSE_LENGTH;
        redo;
    } else {
        local $! = 0;
        my $z = flock $fh, LOCK_SH;
        if ($z) {
            $LOCK{$dir}{_pid()} = $fh;
            return $z;
        }
        $Dir::Flock::errstr = "flock failed: $!";
        return;
    }
}

sub unlock {
    my ($dir) = @_;
    if (!defined $LOCK{$dir}) {
        return if __inGD();
        $Dir::Flock::errstr = "lock for '$dir' not held by " . _pid()
            . " nor any proc";
        carp "Dir::Flock::unlock: $Dir::Flock::errstr";
        return;
    }
    my $fh = delete $LOCK{$dir}{_pid()};
    if (!defined($fh)) {
        return if __inGD();
        $Dir::Flock::errstr = "lock for '$dir' not held by " . _pid();
        carp "Dir::Flock::unlock: $Dir::Flock::errstr";
        return;
    }
    $_DEBUG && print STDERR _pid()," unlocking $dir\n";
    my $z = flock $fh, LOCK_UN;
    close $fh;
    if (! $z) {
        return if __inGD();
        $Dir::Flock::errstr = "unlock called failed on dir '$dir'";
        carp "Dir::Flock::unlock: failed to unlock directory ",
            %{$LOCK{$dir}};
        return; 
    }
    $z;
}

sub __inGD() { goto &Dir::Flock::__inGD }

### flock semantics do not change in Dir::Flock::Mock

### scope semantics do not change in Dir::Flock::Mock

### block semantics do not change in Dir::Flock::Mock

### utilities

1;

=head1 NAME

Dir::Flock::Mock - builtin flock advisory file locking wrapped in Dir::Flock API



=head1 VERSION

0.03



=head1 SYNOPSIS

    use Dir::Flock;
    if (Dir_Flock_wont_work_for_some_reason()) {
        require Dir::Flock::Mock;
    }
    ...


=head1 DESCRIPTION

C<Dir::Flock> implements advisory locking of a directory for
supported systems. On supported systems (like MSWin32 or FAT32)
the normal L<flock|perlfunc/"flock"> scheme should work.
This module mocks the C<Dir::Flock> package on a foundation
of the builtin C<flock> function, so C<Dir::Flock> can be
deployed on the systems that otherwise can't use it as well
as the systems that need it.

To deploy C<Dir::Flock::Mock>, you should assess whether
it is needed, and then load this module with C<require>.

    use Dir::Flock;
    if (Dir_Flock_wont_work_here()) {
        require Dir::Flock::Mock;
    }

Loading this module has the effect of overloading all
the public function calls in C<Dir::Flock> with their
C<flock>-based C<Dir::Flock::Mock> versions. No
other changes to the C<Dir::Flock> function calls should
be necessary.

=head1 FUNCTIONS

See L<Dir::Flock|Dir::Flock/"FUNCTIONS"> for the set
of supported functions and their semantics.


=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>




=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019, Marty O'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

package IO::File::flock;
use strict;
use base qw(IO::File::Lockable);
use vars qw($VERSION);
use Fcntl qw(:flock);
$VERSION		= '0.31';
##### flock oop i/f
sub flock_	:method {CORE::flock(shift,shift)}
sub flock	:method {
	my $fh		= shift;
	my $lock	= shift;
	my $timeout	= shift || 0;
	return $fh	unless($fh->opened);
	return $fh->set_timeout($timeout => sub {flock_($fh,$lock);$fh});
}
##### flock easy i/f
sub lock_nb	:method {shift()->flock(LOCK_EX|LOCK_NB,@_)}
sub lock_sh	:method {shift()->flock(LOCK_SH,@_)}
sub lock_ex	:method {shift()->flock(LOCK_EX,@_)}
sub lock_un	:method {shift()->flock(LOCK_UN,@_)}
1;
__END__

=head1 NAME

IO::File::flock - extension of IO::File for flock

=head1 SYNOPSIS

    use IO::File::flock;
     or
    use IO::File::flock qw(:flock);# export LOCK_*

    # lock mode is automatically.
    $fh = new IO::File "> file" or die($!);
    # lock mode is LOCK_EX|LOCK_NB 
    $fh = new IO::File "file",'>','lock_nb' or die($!);
    # set timeout 5 second 
    $fh = new IO::File "file",'>','lock_ex',5;
    if($@ && $@ =~ /TIMEOUT/){
        #timeout
    }

    $fh->lock_ex(); # if write mode (w or a or +> or > or >> or +<) then default
    $fh->lock_sh(); # other then default

    $fh->lock_un(); # unlock
    $fh->lock_nb(); # get lock LOCK_EX|LOCK_NB
    $fh->flock(LOCK_EX|LOCK_NB); # == $fh->lock_nb()

=head1 DESCRIPTION

C<IO::File::flock> inherits from C<IO::File>.

=head1 CONSTRUCTOR

=over 4

=item new (FILENAME [,MODE [,LOCK_MODE [,TIMEOUT]]]);

creates a C<IO::File::flock>. 

=back

=head1 METHODS

=over 4

=item open(FILENAME [,MODE [,LOCK_METHOD [,TIMEOUT]]]);

=item flock(LOCK_MODE);

=item lock_ex([TIMEOUT]);

=item lock_sh([TIMEOUT]);

=item lock_un([TIMEOUT]);

=item lock_nb([TIMEOUT]);

=back

=head1 AUTHOR

Shin Honda (makoto[at]cpan.org,makoto[at]cpan.jp)

=head1 copyright

Copyright (c) 2003- Shin Honda. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<flock>,
L<Fcntl>,
L<IO::File>,
L<IO::File::Lockable>,

=cut

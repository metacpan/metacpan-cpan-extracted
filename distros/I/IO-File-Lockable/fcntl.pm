package IO::File::fcntl;
use strict;
use base qw(IO::File::Lockable);
use vars qw($VERSION);
use Fcntl;
$VERSION		= '0.31';
######################################################################
sub DESTROY :method {shift->fcntl_un}
sub fcntl_	:method {CORE::fcntl($_[0],$_[1],$_[2])}
##### override
sub lock_ex	:method {shift->fcntl_ex(@_)}
sub lock_sh	:method {shift->fcntl_sh(@_)}
sub lock_un	:method {shift->fcntl_un(@_)}
##### fcntl oop i/f
sub fcntl		:method {
	my $fh		= shift;
	my $lock	= shift;
	my $timeout = shift || 0;
	return $fh	unless($fh->opened);
	return $fh->set_timeout(
		$timeout => sub {fcntl_($fh,F_SETLKW,pack('ssx32',$lock,0));$fh}
	);
}
sub fcntl_sh :method {shift->fcntl(F_RDLCK,@_)}
sub fcntl_ex :method {shift->fcntl(F_WRLCK,@_)}
sub fcntl_un :method {shift->fcntl(F_UNLCK,@_)}
1;
__END__

=head1 NAME

IO::File::fcntl - extension of IO::File for fcntl

=head1 SYNOPSIS

    use IO::File::fcntl;

    my $fh = new IO::File::fcntl($filename);     # auto lock_(ex|sh)
    my $fh = new IO::File::fcntl($filename,'<'); # auto lock_ex
    my $fh = new IO::File::fcntl($filename,'>','lock_sh');
    my $fh = new IO::File::fcntl($filename,'<','lock_ex',60);
    etc,etc....

=head1 DESCRIPTION

C<IO::File::fcntl> inherits from C<IO::File::Lockable>.

=head1 CONSTRUCTOR

=over 4

=item new (FILENAME [,MODE [,LOCK_MODE [,TIMEOUT]]]);

creates a C<IO::File::fcntl>.

=back

=head1 METHODS

=over 4

=item $fh->open(FILENAME [,MODE [,LOCK_METHOD [,TIMEOUT]]]);

=item $fh->fcntl(LOCK_MODE,[TIMEOUT]);

=item $fh->lock_ex([TIMEOUT]);

=item $fh->lock_sh([TIMEOUT]);

=item $fh->lock_un([TIMEOUT]);

=item $fh->fcntl_ex([TIMEOUT]);

=item $fh->fcntl_sh([TIMEOUT]);

=item $fh->fcntl_un([TIMEOUT]);

=back

=head1 AUTHOR

Shin Honda (makoto[at]cpan.org,makoto[at]cpan.jp)

=head1 copyright

Copyright (c) 2004- Shin Honda. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Fcntl>,
L<IO::File>,
L<IO::File::Lockable>
L<IO::File::flock>

=cut

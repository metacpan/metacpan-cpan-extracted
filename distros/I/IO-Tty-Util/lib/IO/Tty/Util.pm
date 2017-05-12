package IO::Tty::Util ;

use strict ;
use IO::Handle ;
use IO::Select ;
use Carp ;

our $VERSION = '0.03' ;

require Exporter ;
our @ISA = qw(Exporter) ;
our @EXPORT_OK = qw( openpty login_tty forkpty passthru ) ;

require XSLoader ;
XSLoader::load('IO::Tty::Util', $VERSION) ;


sub import {
	my $class = shift ;

	foreach my $a (@_){
		if ($a eq "passthru"){
			shift ;
			my ($pid, $master) = forkpty(@_) ;
			croak("forkpty error: $!") unless $master ;
			passthru($master) ;
			exit() ;
		}
	}

	$class->export_to_level(1, $class, @_) ;
}


sub openpty {
	my ($rows, $cols) = @_ ;

	my ($master, $slave) = _openpty($rows, $cols) ;
	return () unless defined($master) ;

	return (IO::Handle->new_from_fd($master, "r+"), IO::Handle->new_from_fd($slave, "r+")) ;
}


sub login_tty {
	my $h = shift ;

	my $rc = _login_tty(fileno($h)) ;
	return ($rc == -1 ? 0 : 1) ;
}


sub forkpty {
	my ($rows, $cols, @cmd) = @_ ;

	my ($master, $slave) = openpty($rows, $cols) ;
    return () unless defined($master) ;

	my $pid = fork() ;
	return () unless defined($pid) ;

	if ($pid){
		close($slave) ;
		return ($pid, $master) ;
	}
	else {
		close($master) ;
		return () unless login_tty($slave) ;
		return (0) unless scalar(@cmd) ;
		exec(@cmd) or die("Can't exec '@cmd': $!") ;
	}
}


sub passthru {
	my $master = shift ;

	STDOUT->autoflush(1) ;
	$master->autoflush(1) ;
	my $select = new IO::Select($master, \*STDIN) ;
	while (1){
		my @ready = $select->can_read() ;
		foreach my $h (@ready){
	        my $buf = '' ;
	        my $rc = sysread($h, $buf, 4096) ;
			return if !$rc ; # pty seems to return error instead of EOF...

			my $out = ($h eq \*STDIN ? $master : \*STDOUT) ;
			# open(DEBUG, ">>/tmp/output") && print DEBUG "[$buf]\n" ;
			print $out $buf or croak("print error: $!") ;
        }
    }
}




1 ;
__END__
=head1 NAME

IO::Tty::Util - Perl bindings for libutil.so tty utility functions

=head1 SYNOPSIS

  use IO::Tty::Util qw(openpty login_tty forkpty) ;

  my ($master, $slave) = openpty(25, 80) ;
  my %ok = login_tty($slave) ;

  my ($pid, $master) = forkpty(25, 80, "/usr/bin/top") ;


=head1 DESCRIPTION

L<IO::Tty::Util> provides basic Perl bindings to the C<openpty> and C<login_tty> functions
found in C<libutil.so> and provides a Perl implementation of the C<forkpty> function.


=head1 FUNCTIONS

=over 4

=item openpty ( $ROWS, $COLS )

Opens a pseudo-tty. Returns returns the master and slave handles on success, or an empty
list on error.

=item login_tty ( $HANDLE )

Prepares for a login on tty handle HANDLE. Returns true on success or false on error.

=item forkpty ( $ROWS, $COLS, @COMMAND )

Combines C<openpty>, C<fork> and C<login_tty> to create a new process operating in a
pseudo-tty. Returns the pid and master handle on success, or an empty list on error.

=back

=head2 EXPORT

None by default. 



=head1 SEE ALSO

L<IO::Tty> provides a lower level interface to ttys.

I<openpty(3)>, I<login_tty(3)>, I<forkpty(3)>.


=head1 BUGS AND DEFICIENCIES

=over 4

=item Incomplete Support

The current implementation does not support passing the C<name> parameter or the 
C<struct termios> terminal properties parameter to C<openpty> and C<forkpty>.

=back


=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

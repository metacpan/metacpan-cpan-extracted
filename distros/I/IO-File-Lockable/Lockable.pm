package IO::File::Lockable;
use strict;
use base qw(IO::File);
use vars qw($VERSION);
use Carp;
$VERSION		= '0.34';
#####  override open method , add argument lock mode.
sub class		:method {ref($_[0]) || $_[0] || __PACKAGE__}
sub new 		:method {(shift()->class->SUPER::new())->init(@_)}
sub init		:method {shift()->open(@_)		if(@_ > 1);}
sub open		:method {
	my $fh		= shift;
	my $file	= shift || return;
	my $mode	= shift;
	$file		= IO::Handle::_open_mode_string($mode) . $file	if($mode);
	$fh->SUPER::open($file) or return;
	my $lock	= (defined $_[0]) ? $_[0]
				: ($file =~ /^(\+?>|\+<)/) ? 'lock_ex' : 'lock_sh';
	return $fh->$lock($_[1]);
}
sub lock_ex		:method {carp('please override lock_ex method.');$_[0]}
sub lock_sh		:method {carp('please override lock_sh method.');$_[0]}
sub lock_un		:method {carp('please override lock_un method.');$_[0]}
######################################################################
sub set_timeout :method {
	my $self		= shift;
	my $timeout 	= shift;
	my $sub 		= shift;
	my $result		= $timeout
		? eval {
			local $SIG{ALRM} = sub {die('TIMEOUT')};
			my $old	= alarm($timeout);
			my $r	= $sub->();
			alarm($old);
			return $r;
		}
		: eval {return $sub->()};
	if($@){carp($@);return;}
	return $result;
}
######################################################################
__END__

=head1 NAME

IO::File::Lockable - supply lock based methods for I/O File objects

=head1 SYNOPSIS

use base qw(IO::File::Lockable);

=head1 DESCRIPTION

C<IO::File::flock> inherits from C<IO::File>.

=head1 CONSTRUCTOR

=over 4

=item new (FILENAME [,OPEN_MODE [,LOCK_METHOD [,TIMEOUT]]]);

    my $fh = new IO::File::Lockable($filename);
    my $fh = new IO::File::Lockable($filename,'<');
    my $fh = new IO::File::Lockable($filename,'>','lock_sh');
    my $fh = new IO::File::Lockable($filename,'<','lock_ex',60);
    etc,etc....

=back

=head1 METHODS

=over 4

=item $fh->open(FILENAME [,MODE [,LOCK_MODE [,TIMEOUT]]]);

=item $fh->lock_ex([TIMEOUT]);

=item $fh->lock_sh([TIMEOUT]);

=item $fh->lock_un([TIMEOUT]);

=back

=head1 AUTHOR

Shin Honda (makoto[at]cpan.org,makoto[at]cpan.jp)

=head1 copyright

Copyright (c) 2004- Shin Honda. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::File>

=cut

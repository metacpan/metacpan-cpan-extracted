package IO::Capture::Sayfix;

use strict;
use warnings;

our $VERSION = 0.05;

use feature 'say';
use IO::Capture::Stdout;

my $capture 		= IO::Capture::Stdout->new();

$capture->start();
say 1;
$capture->stop();

if ( $capture->read() ne "1\n" ){		# bug found, work around
	no warnings 'redefine'; 
		
	*IO::Capture::Tie_STDx::PRINT = sub { 
		my $self = shift;
		push @$self, 
			join ( defined($,) ? $, : '', @_ ) 
			. ( defined($\) ? $\ : '' )
		;
		
	use warnings;
	};
};


1;
__END__

=head1 NAME

IO::Capture::Sayfix - Fix ::Tie_STDx vs say() issue

=head1 VERSION

This document describes IO::Capture::Sayfix version 0.05

=head1 SYNOPSIS

	use IO::Capture::Stderr;
	use IO::Capture::Sayfix;
    
=head1 DESCRIPTION

IO::Capture::Tie_STDx does not handle feature 'say' correctly. 
The bug has been reported to the author. Meanwhile, a fix is needed. 

IO::Capture::Sayfix works around this bug: 

	IO::Capture::Stdout is loaded, if it's not already. 
	'say' is captured
	if the capture doesn't include the trailing newline, 
		then the workaround is loaded. 

The hope is that this will play equally well with the current version
	and any future version that does or does not fix the 'say' bug. 

=head1 AUTHOR

Xiong Changnian  C<< <XIONG@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Xiong Changnian  C<< <XIONG@cpan.org> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

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

=cut

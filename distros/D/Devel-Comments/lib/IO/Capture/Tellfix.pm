package IO::Capture::Tellfix;

use strict;
#use warnings;

our $VERSION = 0.05;

use feature 'say';
use IO::Capture::Tie_STDx;

# test to see if the lack of TELL has been fixed
my $messages	;
my $good_tell	;
my $evalerr		;
tie  *STDOUT, "IO::Capture::Tie_STDx";
@$messages 		= <STDOUT>;

print 'foo';	# should move the tell up to 3

$good_tell	= eval{
	tell(*STDOUT)
};
$evalerr		= $@;
untie *STDOUT;

#print 'good_tell: >', $good_tell, '<, evalerr: >', $evalerr, '<', "\n";

if ( $good_tell != 3 or $evalerr ) {		# didn't work, must fix
	
	*IO::Capture::Tie_STDx::TELL = sub { 
		my $self = shift;
		return length ( join q{}, @$self );
	};
};

1;
__END__

=head1 NAME

IO::Capture::Tellfix - Fix ::Tie_STDx TELL() issue

=head1 VERSION

This document describes IO::Capture::Tellfix version 0.05

=head1 SYNOPSIS

	use IO::Capture::Stderr;
	use IO::Capture::Tellfix;
    
=head1 DESCRIPTION

IO::Capture::Tie_STDx does not implement a TELL() method. 
The bug has been reported to the author. Meanwhile, a fix is needed. 

IO::Capture::Tellfix works around this bug: 

	IO::Capture::Stdout is loaded, if it's not already. 
    tell(*STDOUT) is attempted
	if the tell fails, 
		then the workaround is loaded. 

The hope is that this will play equally well with the current version
	and any future version that does or does not fix the 'TELL' bug. 

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

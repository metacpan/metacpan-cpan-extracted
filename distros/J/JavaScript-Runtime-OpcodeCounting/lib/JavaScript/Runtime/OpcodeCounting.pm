package JavaScript::Runtime::OpcodeCounting;

use 5.006;
use strict;
use warnings;

use Carp qw(croak);

use JavaScript::Error::OpcodeLimitExceeded;

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('JavaScript::Runtime::OpcodeCounting', $VERSION);

sub _init {
	my $rt = shift;
	my $handler = jsr_init();
	$rt->_add_interrupt_handler($handler);
	$rt->{_OpcodeCounting} = $handler;
	1;
}

sub _destroy {
	my $rt = shift;
	jsr_destroy($rt->{_OpcodeCounting});
	delete $rt->{_OpcodeCounting};
	1;
}

sub set_opcount {
	my ($rt, $opcount) = @_;
	croak "opcount is negative" if $opcount < 0;
	jsr_set_opcount($rt->{_OpcodeCounting}, $opcount);
	1;
}

sub get_opcount {
	my $rt = shift;
	return jsr_get_opcount($rt->{_OpcodeCounting});
}

sub set_opcount_limit {
	my ($rt, $limit) = @_;
	croak "limit is negative" if $limit < 0;
	jsr_set_opcount_limit($rt->{_OpcodeCounting}, $limit);
	1;
}

sub get_opcount_limit {
	my $rt = shift;
	return jsr_get_opcount_limit($rt->{_OpcodeCounting});
}

1;
__END__
=head1 NAME

JavaScript::Runtime::OpcodeCounting - JavaScript::Runtime that counts how many opcodes that are executed

=head1 SYNOPSIS

  use JavaScript;
  use JavaScript::Runtime::OpcodeCounting;
  
  my $runtime = JavaScript::Runtime->new(qw(-OpcodeCounting));
  my $context = $runtime->create_context();

  $runtime->set_opcount(0);
  $runtime->set_opcount_limit(1000);
  $context->eval($some_javascript_code);
  print "Execution was aborted becuse we hit the limit" if $@ && $@->isa('JavaScript::Error::OpcodeLimitExceeded');
  print "Ran ", $runtime->get_opcount(), " opcodes";

=head1 DESCRIPTION

This module provides an extended JavaScript::Runtime class that keeps track on how many opcodes 
are executed by the runtime. It can also be set to abort execution when N number of opcodes have
been executed by setting an upper limit.

Currently both the counter and the limit are implemented as U32 values. If lots, and I mean *lots*, 
of opcodes are executed without resetting the counter it will eventually overflow.

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item get_opcount

Returns the number of opcodes that have been executed.

=item set_opcount ( $count )

Sets the internal counter to I<$count>.

=item get_opcount_limit

Returns the current limit before we abort execution.

=item set_opcount_limit ( $limit )

Sets the limit to I<$limit>. If set to 0 no abortion will occur.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item jsr_init

Sets the interrupt handler and populates I<PJS_Runtime/ext> with a PJS_Runtime_OpcodeCounting structure.

=item jsr_destroy

Removeds the interrupt handler and frees the memory occupied by the I<PJS_Runtime/ext> structure.

=item jsr_set_opcount

=item jsr_set_opcount_limit

Functions for setting counter and limit.

=item jsr_get_opcount

=item jsr_get_opcount_limit

Functions for getting counter and limit

=back

=end PRIVATE

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-javascript-runtime-opcodecounting@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Claes Jakobsson C<< <claesjac@cpan.org> >>. All rights reserved.

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

=cut

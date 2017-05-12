#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::PERL;
# ABSTRACT: extension to embed Perl within Befunge
$Language::Befunge::lib::PERL::VERSION = '5.000';

sub new { return bless {}, shift; }


# -- Perl embedding

#
# 0gnirts = E( 0gnirts )
#
# 'Eval' pops a 0gnirts string and performs a Perl eval() on it. The
# result of the call is pushed as a 0gnirts string back onto the stack.
#
sub E {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the perl string
    my $perl = $ip->spop_gnirts();
	my $return = eval $perl;
	
	$ip->spush( 0 ); # finish the string
	$ip->spush( map{ ord($_) } reverse split(//, $return) );
}


#
# val = I( 0gnirts )
#
# 'Int Eval' acts the same as 'E', except that the result of the call
# is converted to an integer and pushed as a single cell onto the stack. 
#
sub I {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the perl string
    my $perl = $ip->spop_gnirts();
	my $return = eval $perl;
	
	$ip->spush( int $return );
}


# -- Module information

#
# S
# 'Shelled' pushes a 0 on the stack, meaning that the Perl language is already
# loaded (e.g. the interpreter is written in Perl).
#
sub S {
    my ($self, $interp) = @_;
    $interp->get_curip->spush(0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::PERL - extension to embed Perl within Befunge

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The PERL fingerprint (0x5045524c) is designed to provide a basic, no-frills
interface to the Perl language.

After successfully loading PERL, the instructions E, I, and S take on new
semantics.

=head1 FUNCTIONS

=head2 new

Create a new PERL instance.

=head2 Module information

=over 4

=item S

C<Shelled> pushes a 0 on the stack, meaning that the Perl language is already
loaded (e.g. the interpreter is written in Perl).

=back

=head2 Perl embedding

=over 4

=item 0gnirts = E( 0gnirts )

C<Eval> pops a 0gnirts string and performs a Perl C<eval()> on it. The
result of the call is pushed as a 0gnirts string back onto the stack.

=item val = I( 0gnirts )

C<Int Eval> acts the same as C<E>, except that the result of the call
is converted to an integer and pushed as a single cell onto the stack. 

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/PERL.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

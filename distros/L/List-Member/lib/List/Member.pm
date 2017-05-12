package List::Member;

require 5.005_62;
use strict;
use warnings;
use Carp ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&member &nota_member);
our $VERSION = '0.044';
our $NEG = -1;

sub nota_member { return $NEG }

sub member {
	my $target = shift;
	Carp::croak 'No target in member/2 ' unless defined $target;
	if (ref $target eq 'Regexp'){
		for (0..$#_){
			return $_ if $_[$_] =~ $target;
		}
	} else {
		for (0..$#_){
			return $_ if $_[$_] eq $target;
		}
	}
	return $NEG;
}

1;

__END__

=head1 NAME

List::Member - PROLOG's member/2: return index of $x in @y.

=head1 SYNOPSIS

  use List::Member;
  my $target = 'bar';
  my @look_in = ('foo','baz','bar','etc');

  warn "It is a member of the list" if member('bar',@look_in) +1;
  warn "It is a member of the list" if member('bar',@look_in) >= 0;
  warn "It is a member of the list" if member(qr/ar$/,@look_in) +1;

  warn "It is not a member of list" if member('tikkumolam',@look_in) eq nota_member();

=head1 DESCRIPTION

A tiny routine to achieve the same effect as PROLOG's C<member/2>.

Returns the index of supplied scalar in supplied array, or returns the
value of the package's C<$NEG> scalar.  This can be over-ridden for the case
when the target is the same as the default C<-1>:

	$List::Member::NEG = 'not_a_member';

In the above case, the first two example calls in the POD would need to be
updated.

=head1 EXPORT

	member

=head1 CHANGES

In version 0.02, C<member> returned C<undef> but documented C<-1>.
The documentation was correct, and the code has been updated.

=head1 THANKS

Thanks to Benoit Thillaye du Boulay in France,
John Day and Michael D Black in Florida for pointing out bugs
in the documentation.

=head1 AUTHOR

Lee Goddard <lgoddard@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2000-2007 Lee Goddard. All Rights Reserved.

This module is made available under the same terms as Perl.

=head1 SEE ALSO

perl(1).

=cut


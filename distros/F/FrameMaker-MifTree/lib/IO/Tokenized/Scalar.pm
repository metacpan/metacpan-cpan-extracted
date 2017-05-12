package IO::Tokenized::Scalar;
use strict;
use base qw(IO::Scalar IO::Tokenized);
use vars qw($VERSION);

use Carp;

$VERSION = '0.05';

# new has the following synopsis:
# IO::Tokenized::Scalar->new([$tokens [,$filename]])

sub new {
  my $class = shift;
  my ($filename,@tokens) = @_;
  my $self = defined $filename ? IO::Scalar->new($filename): IO::Scalar->new();
  $self = IO::Tokenized->new($self,@tokens);
  bless $self,$class;
}

# redefine so that only opening for input is allowed
sub open {
  my $self = shift;
  my ($filename) = @_; #silently ignore other parameters
  $self->SUPER::open($filename,"r");
}

1;

__END__

=head1 NAME

IO::Tokenized::Scalar - Extension of IO::Scalar allowing tokenized input

=head1 SYNOPSIS

  my $fh = IO::Tokenized::Scalar->new();
  $fh->setparser([num => qr/\d+/],
                 [ident => qr/[a-z_][a-z0-9_]],
                 [op => qr![+*/-]!,\&opname]);

  $fh->open('tokenfile') || die "Can't open 'tokenfile': $1";

  while ($t = $fh->gettoken()) {
    ... do something smart...
  }

  $fh->close();

=head2 NOTE

This is a modified version of IO::Tokenized::File; it has just every
occurrence of IO::File replaced by IO::Scalar. The original package is
copyright Leo Cacciari; modification by Roel van der Steen
E<lt>roel-perl@st2x.netE<gt>.

=head1 DESCRIPTION

I<IO::Tokenized::Scalar> adds the methods provided by I<IO::Tokenized> to
I<IO::Scalar> objects. See L<IO::Tokenized> for details about how the tokens
are specified and returned.

=head1 METHODS

I<IO::Tokenized::Scalar> inherits both from I<IO::tokenized> and I<IO::Scalar>,
so that methods from both classes are available to I<IO::Tokenized::Scalar>
objects.

I<IO::Tokenized::Scalar> redefines the following methods:

=over

=item * C<new([$filename[,@tokens]])>

The C<new> method is redefined so as to call both C<IO::Scalar::new> (passing
to C<$filename> if it is defined) and C<IO::Tokenized::new> (passing to it the
C<@tokens> parameter).

=item * C<open($filename)>

The C<open> method from I<IO::Scalar> is redefined so that only opening for
input is allowed: requestes for other kind of opening are silently converted to
opening for input (this is a bug).

=back

=head1 SEE ALSO

L<IO::Tokenized> and L<IO::Scalar>.

=head1 AUTHOR

Leo Cacciari, E<lt>hobbit@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE AND LICENSE

Copyright 2003 by Leo Cacciari

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


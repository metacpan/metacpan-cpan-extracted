package IO::Tokenized::File;
use strict;
use base qw(IO::Tokenized IO::File);
use vars qw($VERSION);

use Carp;

$VERSION = '0.05';


# new has the following synopsis:
# IO::Tokenized::File->new([$tokens [,$filename]])

sub new {
  my $class = shift;
  my ($filename,@tokens) = @_;
  my $self = defined $filename ? IO::File->new($filename): IO::File->new();
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

IO::Tokenized::File - Extension of IO::File allowing tokenized input

=head1 SYNOPSIS

  my $fh = IO::Tokenized::File->new();
  $fh->setparser([num => qr/\d+/],
                 [ident => qr/[a-z_][a-z0-9_]],
                 [op => qr![+*/-]!,\&opname]);

  $fh->open('tokenfile') || die "Can't open 'tokenfile': $1";
  
  while ($t = $fh->gettoken()) {
    ... do something smart...
  }

  $fh->close();


=head1 DESCRIPTION

I<IO::Tokenized::File> adds the methods provided by I<IO::Tokenized> to 
I<IO::File> objects. See L<IO::Tokenized> for details about how the tokens are 
specified and returned.


=head1 METHODS

I<IO::Tokenized::File> inherits both from I<IO::tokenized> and
I<IO::File>, so that methods from both classes are available to
I<IO::Tokenized::File> objects.

I<IO::Tokenized::File> redefines the following methods:

=over

=item * C<new([$filename[,@tokens]])>

The C<new> method is redefined so as to call both
C<IO::File::new> (passing to C<$filename> if it is defined) and
C<IO::Tokenized::new> (passing to it the C<@tokens> parameter).

=item * C<open($filename)>

The C<open> method from I<IO::File> is redefined so that only opening
for input is allowed: requestes for other kind of opening are silently
converted to oepning for input (this is a bug).

=back

=head1 SEE ALSO

L<IO::Tokenized> and L<IO::File>.


=head1 AUTHOR

Leo Cacciari, E<lt>hobbit@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Leo Cacciari

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


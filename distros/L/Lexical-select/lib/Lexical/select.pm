package Lexical::select;
$Lexical::select::VERSION = '0.10';
#ABSTRACT: provides a lexically scoped currently selected filehandle

use strict;
use warnings;
use Symbol 'qualify_to_ref';

our @ISA    = qw[Exporter];
our @EXPORT = qw[lselect];

sub lselect {
  my $handle = qualify_to_ref(shift, caller);
  my $old_fh = CORE::select $handle;
  return bless { old_fh => $old_fh }, __PACKAGE__;
}

sub restore {
  my $self = shift;
  return if $self->{_restored};
  CORE::select delete $self->{old_fh};
  return $self->{_restored} = 1;
}

sub DESTROY {
  my $self = shift;
  $self->restore unless $self->{_restored};
}

q[select $old_fh];

__END__

=pod

=encoding UTF-8

=head1 NAME

Lexical::select - provides a lexically scoped currently selected filehandle

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use Lexical::select;

  open my $fh, '>', 'fubar' or die "Oh noes!\n";

  {
    my $lxs = lselect $fh;

    print "Something wicked goes to \$fh \n";

  }

  print "Back on STDOUT\n";

=head1 DESCRIPTION

Changing the currently selected filehandle with C<select> and changing it back to the previously selected filehandle
can be slightly tedious. Wouldn't it be great to have something handle this boilerplate, especially in lexical scopes.

This is where Lexical::select comes in.

Lexical::select provides the C<lselect> function. As demonstrated in the C<SYNOPSIS>, C<lselect> will change the currently
selected filehandle to the filehandle of your choice for the duration of the enclosing lexical scope.

It should be noted that the duration of the selected filehandle is limited to the lexical scope, not the effects of the
selected filehandle.

=head1 FUNCTIONS

Functions exported by default.

=over

=item C<lselect>

Takes one parameter, a C<filehandle> that will become the currently selected filehandle for the duration of the enclosing scope.

Returns an object, which provides the C<restore> method.

You can then either C<restore> the currently selected filehandle back manually or let the object fall out of
scope, which automagically restores.

=back

=head1 METHODS

=over

=item C<restore>

Explicitly restores the currently selected filehandle back to the original filehandle. This is called automagically
when the object is C<DESTROY>ed, for instance when the object goes out of scope.

=back

=head1 SEE ALSO

L<SelectSaver>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

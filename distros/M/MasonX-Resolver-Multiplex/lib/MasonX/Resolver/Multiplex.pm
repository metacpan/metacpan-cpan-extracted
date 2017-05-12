use strict;
use warnings;

package MasonX::Resolver::Multiplex;

our $VERSION = '0.001';

use Moose;
BEGIN { extends 'HTML::Mason::Resolver' }

# play nicely with Class::Container
sub validation_spec {
  my ($self) = @_;
  return {
    %{ $self->SUPER::validation_spec || {} },
    resolvers => 1,
  },
}

has resolvers => (
  is => 'rw',
  isa => 'ArrayRef[HTML::Mason::Resolver]',
  lazy => 1,
  auto_deref => 1,
  default => sub { [] },
);

sub get_info {
  my $self = shift;
  my @args = @_;
  for my $res ($self->resolvers) {
    my $src = $res->get_info(@args);
    return $src if $src;
  }
  return;
}

sub glob_path {
  my $self = shift;
  my @args = @_;
  for my $res ($self->resolvers) {
    my @paths = $res->glob_path(@args);
    return @paths if @paths;
  }
  return;
}

sub apache_request_to_comp_path {
  my $self = shift;
  my @args = @_;
  for my $res ($self->resolvers) {
    next unless $res->can('apache_request_to_comp_path');
    my $path = $res->apache_request_to_comp_path(@args);
    return $path if $path;
  }
  return;
}

1;
__END__

=head1 NAME

MasonX::Resolver::Multiplex - multiplex several Resolver objects

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

  use MasonX::Resolver::Multiplex;

  my $resolver = MasonX::Resolver::Multiplex->new(
    resolvers => [
      My::Custom::Resolver->new,
      HTML::Mason::Resolver::File->new,
    ],
  );

  my $interp = HTML::Mason::Interp->new(
    resolver => $resolver,
    # ... other options
  )

=head1 DESCRIPTION

Use this Resolver subclass when you want to combine the behavior of other
Resolver subclasses, such as in the L</SYNOPSIS>.

This class delegates methods to its contained C<resolvers>.  Each method is
called on each resolver in order; the first to return a true value 'wins'.

Delegated methods:

=over

=item * get_info

=item * glob_path

=item * apache_request_to_comp_path (if present)

=back

=head1 SEE ALSO

L<HTML::Mason>
L<HTML::Mason::Resolver>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-masonx-resolver-multiplex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MasonX-Resolver-Multiplex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MasonX::Resolver::Multiplex


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MasonX-Resolver-Multiplex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MasonX-Resolver-Multiplex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MasonX-Resolver-Multiplex>

=item * Search CPAN

L<http://search.cpan.org/dist/MasonX-Resolver-Multiplex>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Hans Dieter Pearcey.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

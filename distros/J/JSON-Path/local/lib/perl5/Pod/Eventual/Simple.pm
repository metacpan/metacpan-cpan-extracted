use strict;
use warnings;
package Pod::Eventual::Simple;
{
  $Pod::Eventual::Simple::VERSION = '0.094001';
}
use Pod::Eventual;
BEGIN { our @ISA = 'Pod::Eventual' }
# ABSTRACT: just get an array of the stuff Pod::Eventual finds


sub new {
  my ($class) = @_;
  bless [] => $class;
}

sub read_handle {
  my ($self, $handle, $arg) = @_;
  $self = $self->new unless ref $self;
  $self->SUPER::read_handle($handle, $arg);
  return [ @$self ];
}

sub handle_event {
  my ($self, $event) = @_;
  push @$self, $event;
}

BEGIN {
  *handle_blank  = \&handle_event;
  *handle_nonpod = \&handle_event;
}

1;

__END__

=pod

=head1 NAME

Pod::Eventual::Simple - just get an array of the stuff Pod::Eventual finds

=head1 VERSION

version 0.094001

=head1 SYNOPSIS

  use Pod::Eventual::Simple;

  my $output = Pod::Eventual::Simple->read_file('awesome.pod');

This subclass just returns an array reference when you use the reading methods.
The arrayref contains all the Pod events and non-Pod content.  Non-Pod content
is given as hashrefs like this:

  {
    type       => 'nonpod',
    content    => "This is just some text\n",
    start_line => 162,
  }

For just the POD events, grep for C<type> not equals "nonpod"

=for Pod::Coverage new

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

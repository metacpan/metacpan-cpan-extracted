package Global::Context::Terminal;
{
  $Global::Context::Terminal::VERSION = '0.003';
}
use Moose::Role;
# ABSTRACT: the origin of a request


use namespace::autoclean;

has uri => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_string { $_[0]->uri }

1;

__END__

=pod

=head1 NAME

Global::Context::Terminal - the origin of a request

=head1 VERSION

version 0.003

=head1 OVERVIEW

Global::Context::Terminal is a role.

Terminal objects represent the source machine (or other locator) of a request,
like an IP address, hostname, or other identifier.  They have only one required
attribute, C<uri>, which must be a string.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

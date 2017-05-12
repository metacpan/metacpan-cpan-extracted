use 5.006;    # our
use strict;
use warnings;

package MetaPOD::Role::Format;

our $VERSION = 'v0.4.0';

# ABSTRACT: Base role for common format routines

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo::Role qw( requires );
use Carp qw( croak );
use version 0.77;


























sub supported_versions { return qw( v1.0.0 ) }











sub _supported_versions {
  my $class = shift;
  return map { version->parse($_) } $class->supported_versions;
}













sub supports_version {
  my ( $class, $version ) = @_;
  return [ $class->supported_versions ]->[-1] if not defined $version;
  if ( $version !~ /^v/msx ) {
    croak q{Version specification does not begin with a 'v'};
  }
  my $v = version->parse($version);
  for my $supported ( $class->supported_versions ) {
    return $supported if $supported == $v;
  }
  croak "Version $v not supported. Supported versions: " . join q{,}, $class->supported_versions;
}

requires 'add_segment';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Role::Format - Base role for common format routines

=head1 VERSION

version v0.4.0

=head1 METHODS

=head2 C<supported_versions>

Returns a list of string versions supported by this class, or the consuming role.

    my ( @versions ) = $role->supported_versions

Each B<SHOULD> be in C<dotted decimal> format, and each B<SHOULD> be preceded with a C<v>

By default, returns

    v1.0.0

=head2 C<supports_version>

Determine if the class supports the given version or not

    $class->supports_version('v1.0.0');

C<version> B<MUST> be preceded with a C<v> and B<MUST> be in dotted decimal form.

Default implementation compares values given verses the results from C<< $class->_supported_versions >>

=head1 PRIVATE METHODS

=head2 C<_supported_versions>

Returns a list of C<version> objects that represent an enumeration of all supported versions

The default implementation just wraps L</supported_versions> with C<< version->parse() >>

    my (@vobs) = $role->_supported_versions;

=begin MetaPOD::JSON v1.1.0

{
    "namespace": "MetaPOD::Role::Format",
    "interface": "role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

package MetaPOD::Format::JSON;
BEGIN {
  $MetaPOD::Format::JSON::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::VERSION = '0.3.0';
}

# ABSTRACT: Reference implementation of a C<JSON> based MetaPOD Format


use Moo;
use Carp qw( croak );
use version 0.77;

with 'MetaPOD::Role::Format';

use MetaPOD::Format::JSON::v1;
use MetaPOD::Format::JSON::v1_1;

my $dispatch_table = [
  {
    version => version->parse('v1.0.0'),
    handler => 'MetaPOD::Format::JSON::v1'
  },
  {
    version => version->parse('v1.1.0'),
    handler => 'MetaPOD::Format::JSON::v1_1'
  }
];


sub supported_versions {
  return qw( v1.0.0 v1.1.0 );
}


sub add_segment {
  my ( $self, $segment, $result ) = @_;
  my $segver = $self->supports_version( $segment->{version} );
  for my $v ( @{$dispatch_table} ) {
    next unless $v->{version} == $segver;
    $v->{handler}->add_segment( $segment, $result );
    return $result;
  }
  croak "No implementation found for version $segver";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON - Reference implementation of a C<JSON> based MetaPOD Format

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

This is the reference implementation of L<< C<MetaPOD::JSON>|MetaPOD::JSON >>

=head1 METHODS

=head2 C<supported_versions>

The versions this module supports

    returns qw( v1.0.0 v1.1.0 )

=head2 C<add_segment>

See L<< C<::Role::Format>|MetaPOD::Role::Format >> for the specification of the C<add_segment> method.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON",
    "inherits":"Moo::Object",
    "does":"MetaPOD::Role::Format",
    "interface": "single_class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

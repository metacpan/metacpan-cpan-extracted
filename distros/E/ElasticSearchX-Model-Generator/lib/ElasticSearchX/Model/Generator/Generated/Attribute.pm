use strict;
use warnings;

package ElasticSearchX::Model::Generator::Generated::Attribute;
BEGIN {
  $ElasticSearchX::Model::Generator::Generated::Attribute::AUTHORITY = 'cpan:KENTNL';
}
{
  $ElasticSearchX::Model::Generator::Generated::Attribute::VERSION = '0.1.8';
}

# ABSTRACT: Result container for a generated attribute

use Moo;
use MooseX::Has::Sugar qw( rw required );


has content => rw, required;

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Generator::Generated::Attribute - Result container for a generated attribute

=head1 VERSION

version 0.1.8

=head1 ATTRIBUTES

=head2 content

  rw, required

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

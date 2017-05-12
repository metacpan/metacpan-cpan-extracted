package Evo::Class::Attrs::XS;
use Evo 'XSLoader; -Export';

use constant {ECA_OPTIONAL => 0, ECA_DEFAULT => 1, ECA_DEFAULT_CODE => 2, ECA_REQUIRED => 3,
  ECA_LAZY => 4,};

export qw(
  ECA_OPTIONAL ECA_DEFAULT ECA_DEFAULT_CODE ECA_REQUIRED ECA_LAZY
);

our $VERSION = '0.0403';    # VERSION

# to be able to run with and without dzil
my $version = eval '$VERSION';    ## no critic
$version
  ? XSLoader::load("Evo::Class::Attrs::XS", $version)
  : XSLoader::load("Evo::Class::Attrs::XS");

sub new { bless [], shift }

sub gen_attr ($self, %opts) {
  $self->_gen_attr(@opts{qw(name type value check ro inject method)});
}

1;

# ABSTRACT: XS implementation of attributes and "new" method generator

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Attrs::XS - XS implementation of attributes and "new" method generator

=head1 VERSION

version 0.0403

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

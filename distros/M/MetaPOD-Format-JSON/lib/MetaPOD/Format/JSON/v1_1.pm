
use strict;
use warnings;

package MetaPOD::Format::JSON::v1_1;
BEGIN {
  $MetaPOD::Format::JSON::v1_1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::v1_1::VERSION = '0.3.0';
}

# ABSTRACT: MetaPOD::JSON v1 SPEC Implementation


use Moo;

extends 'MetaPOD::Format::JSON::v1';
with 'MetaPOD::Format::JSON::interface::v1_1';


sub features {
  return qw( does inherits namespace interface );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::v1_1 - MetaPOD::JSON v1 SPEC Implementation

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<features>

The list of features this version supports.

    does inherits namespace interface

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::v1_1",
    "interface":"single_class",
    "inherits" : "MetaPOD::Format::JSON::v1",
    "does":[
        "MetaPOD::Format::JSON::interface::v1_1"
    ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

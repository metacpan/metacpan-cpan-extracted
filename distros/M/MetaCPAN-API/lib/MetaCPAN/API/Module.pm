use strict;
use warnings;
package MetaCPAN::API::Module;
# ABSTRACT: Module information for MetaCPAN::API

our $VERSION = '0.51';

use Carp;
use Moo::Role;
use namespace::autoclean;

# /module/{module}
sub module {
    my $self = shift;
    my $name = shift;

    $name or croak 'Please provide a module name';

    return $self->fetch("module/$name");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::API::Module - Module information for MetaCPAN::API

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about modules.

More specifically, this returns the C<.pm> file of that module.

=head1 METHODS

=head2 module

    my $result = $mcpan->module('MetaCPAN::API');

Searches MetaCPAN and returns a module's C<.pm> file.

=head2 file

This used to be a synonym of C<module>, but the functionality has now
moved to L<MetaCPAN::API::File>.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

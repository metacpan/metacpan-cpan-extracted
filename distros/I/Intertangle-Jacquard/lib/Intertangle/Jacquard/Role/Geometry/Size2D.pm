use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Geometry::Size2D;
# ABSTRACT: A 2D geometry with variable size
$Intertangle::Jacquard::Role::Geometry::Size2D::VERSION = '0.001';
use Mu::Role;
use Intertangle::Punchcard::Attributes;

variable width =>;
variable height =>;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Geometry::Size2D - A 2D geometry with variable size

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

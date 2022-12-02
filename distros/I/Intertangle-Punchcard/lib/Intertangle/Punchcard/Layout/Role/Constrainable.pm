use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Layout::Role::Constrainable;
# ABSTRACT: A role to hold constraints for bounding boxes
$Intertangle::Punchcard::Layout::Role::Constrainable::VERSION = '0.002';
use Mu;

has [ qw(top bottom left right) ] => ( is => 'ro' );

has [ qw(width height) ] => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Layout::Role::Constrainable - A role to hold constraints for bounding boxes

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 top bottom left right

...

=head2 width height

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

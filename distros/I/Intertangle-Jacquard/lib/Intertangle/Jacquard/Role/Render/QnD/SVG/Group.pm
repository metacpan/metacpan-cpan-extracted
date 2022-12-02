use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::SVG::Group;
# ABSTRACT: Quick-and-dirty SVG group rendering
$Intertangle::Jacquard::Role::Render::QnD::SVG::Group::VERSION = '0.002';
use Moo::Role;

method render($svg) {
	my $group = $svg->group( transform => "translate(@{[ $self->x->value ]},@{[ $self->y->value ]})" );
	for my $child (@{$self->children}) {
		$child->render($group);
	}
}

with qw(Intertangle::Jacquard::Role::Render::QnD::SVG);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::SVG::Group - Quick-and-dirty SVG group rendering

=head1 VERSION

version 0.002

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Role::Render::QnD::SVG>

=back

=head1 METHODS

=head2 render

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

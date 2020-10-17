use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Cairo;
# ABSTRACT: Quick-and-dirty Cairo rendering
$Intertangle::Jacquard::Role::Render::QnD::Cairo::VERSION = '0.001';
use Mu::Role;

method render_cairo($cr) {
	...
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Cairo - Quick-and-dirty Cairo rendering

=head1 VERSION

version 0.001

=head1 METHODS

=head2 render_cairo

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

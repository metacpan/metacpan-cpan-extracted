use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Layout;
# ABSTRACT: Quick-and-dirty layout role
$Intertangle::Jacquard::Role::Render::QnD::Layout::VERSION = '0.001';
use Moo::Role;

has layout => (
	is => 'ro',
	required => 1,
);

method update_layout() {
	$self->layout->update($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Layout - Quick-and-dirty layout role

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 layout

...

=head1 METHODS

=head2 update_layout

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

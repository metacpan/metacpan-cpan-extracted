use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3::Helper::Gtk3::Adjustment;
# ABSTRACT: Helpers for Gtk3::Adjustment
$Intertangle::API::Gtk3::Helper::Gtk3::Adjustment::VERSION = '0.007';
package # hide from PAUSE
	Gtk3::Adjustment;

method increment_step() {
	my $adjustment = $self->get_value + $self->get_step_increment;
	$self->set_value($adjustment);
	$self;
}

method decrement_step() {
	my $adjustment = $self->get_value - $self->get_step_increment;
	$self->set_value($adjustment);
	$self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3::Helper::Gtk3::Adjustment - Helpers for Gtk3::Adjustment

=head1 VERSION

version 0.007

=head1 METHODS

=head2 increment_step

  method increment_step()

Increments by the step increment.

=head2 decrement_step

  method decrement_step()

Decrements by the step increment.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

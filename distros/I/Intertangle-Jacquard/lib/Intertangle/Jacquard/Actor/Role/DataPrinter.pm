use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Actor::Role::DataPrinter;
# ABSTRACT: Role to do Data::Printer things
$Intertangle::Jacquard::Actor::Role::DataPrinter::VERSION = '0.002';
use Mu::Role;

requires '_data_printer_internal';

sub _data_printer {
	my ($self, $prop) = @_;

	use Module::Load;
	BEGIN {
		eval {
			autoload Data::Printer::Filter;
			autoload Term::ANSIColor;
		};
	}

	my $text = '';

	$text .= $prop->{colored} ? "(@{[colored(['green'], ref($self))]}) " : "(@{[ ref($self) ]}) ";
	$text .= Data::Printer::np($self->_data_printer_internal, %$prop, );

	$text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Actor::Role::DataPrinter - Role to do Data::Printer things

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

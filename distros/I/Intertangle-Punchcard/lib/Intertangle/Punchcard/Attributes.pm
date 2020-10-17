use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Attributes;
# ABSTRACT: Attributes for constraint variables
$Intertangle::Punchcard::Attributes::VERSION = '0.001';
use Moo::_Utils qw(_install_coderef);
use Intertangle::Punchcard::Backend::Kiwisolver::Symbolic;

sub import {
	my $target = caller;
	my $has    = $target->can( "has" ) or die "Moo not loaded in caller: $target";
	_install_coderef $target. "::variable" => my $variable = sub {
		my ($name, @args) = @_;
		$has->($name,
			is => 'lazy',
			builder => sub {
				Intertangle::Punchcard::Backend::Kiwisolver::Symbolic->new( name => $name );
			},
			@args,
		);
	};

	if (my $info = $Role::Tiny::INFO{$target}) {
		$info->{not_methods}{$variable} = $variable;
	}

	undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Attributes - Attributes for constraint variables

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

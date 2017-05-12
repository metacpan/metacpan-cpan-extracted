use 5.012;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Pod::Weaver::Section::LegalWithAddendum extends Pod::Weaver::Section::Legal
{

	our $VERSION = '0.05_01'; # TRIAL VERSION


	has addendum => ( is => 'ro', isa => 'Str', predicate => '_has_addendum' );

	override weave_section ($document, $input)
	{
		super();
		my $legal = $document->children->[-1];
		$legal->children->[0] .= "\n\n" . $self->addendum if $self->_has_addendum;
	}
}


1;


# ABSTRACT: Dist::Zilla configuration the way BAREFOOT does it
# COPYRIGHT

__END__

=pod

=head1 NAME

Pod::Weaver::Section::LegalWithAddendum - Dist::Zilla configuration the way BAREFOOT does it

=head1 VERSION

This document describes version 0.05_01 of Pod::Weaver::Section::LegalWithAddendum.

=head1 AUTHOR

Buddy Burden <barefoot@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use 5.026;
use warnings;

package Pod::Weaver::PluginBundle::Author::AJNN::License;
# ABSTRACT: Pod section for copyright and license statement
$Pod::Weaver::PluginBundle::Author::AJNN::License::VERSION = '0.04';

use Carp qw(croak);
use Moose;
use namespace::autoclean;
use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Ordinary;
use Software::License 0.103014;  # for spdx_expression

with 'Pod::Weaver::Role::Section';


our $HEADER = 'COPYRIGHT AND LICENSE';


sub weave_section {
	my ($self, $document, $input) = @_;
	
	my $notice = $self->notice_maybe_mangled(
		$input->{license},
		$input->{authors},
	);
	
	push $document->children->@*, Pod::Elemental::Element::Nested->new({
		command  => 'head1',
		content  => $HEADER,
		children => [ Pod::Elemental::Element::Pod5::Ordinary->new({
			content => $notice,
		})],
	});
}


sub notice_maybe_mangled {
	my (undef, $license, $authors) = @_;
	
	my $notice = $license->notice;
	$notice =~ s/^\s+//;
	$notice =~ s/\s+$//;
	
	# I prefer artistic_2 because I find the perl_5 terms too limiting.
	# At the same time, I'm aware that some people don't consider perl_5
	# to match the definition in section (4) (c) (ii) of artistic_2.
	# I would tend to disagree, but IANAL. To avoid any possible doubt
	# about my intentions, I choose to explicitly offer both licenses.
	
	return $notice if $license->spdx_expression ne 'Artistic-2.0'
	                  || $authors->[0] !~ m/<ajnn.cpan\.org>/;
	croak "Unsupported declaration of multiple authors in dist.ini" if @$authors > 1;
	
	$notice =~ s/This is free software, licensed under.*//s;
	$notice .= <<END;
This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.
END
	return $notice;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::AJNN::License - Pod section for copyright and license statement

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 package Pod::Weaver::PluginBundle::Author::AJNN;
 
 use Pod::Weaver::PluginBundle::Author::AJNN::License;
 
 sub mvp_bundle_config {
   return (
     ...,
     [ '@AJNN/License', __PACKAGE__ . '::License', {}, ],
   )
 }

=head1 DESCRIPTION

This package provides AJNN's customised copyright and license statement.

In particular, for distributions which declare their license as Artistic-2.0
I<and> which declare AJNN as their only author, the license statement is
modified to I<explicitly> allow reuse under the same terms as the S<Perl 5>
programming language system itself as well. Effectively, this results in
triple-licensing under (Artistic-2.0 OR Artistic-1.0-Perl OR GPL-1.0-or-later),
at the choice of the user.

Reuse under Perl 5 terms might already be allowed under S<section (4) (c) (ii)>
of Artistic-2.0, but I like to state this explicitly for the avoidance of doubt.

=head1 BUGS

Multiple authors are unsupported.

=head1 SEE ALSO

L<Pod::Weaver::PluginBundle::Author::AJNN>

L<Pod::Weaver::Section::Legal>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

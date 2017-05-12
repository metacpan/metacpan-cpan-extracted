package FreeMind::Node;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Node::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Node::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['node'],
;

require FreeMind::Document;
require Types::Standard;
require Type::Utils;

my $Milliseconds = Types::Standard::Int()
	-> create_child_type(
		constraint => sub { $_ >= 0 },
		inlined    => sub { sprintf '%s and %s >= 0', $_[0]->parent->inline_check($_[1]), $_[1] },
	)
	-> plus_coercions(
		Type::Utils::class_type({class => 'DateTime'}),
		q{ 1000 * $_->epoch },
	);

__PACKAGE__->FreeMind::Document::_has(
	BACKGROUND_COLOR  => { },
	COLOR             => { },
	FOLDED            => { isa => Types::Standard::Bool() },
	ID                => { },
	LINK              => { },
	POSITION          => { isa => Type::Utils::enum(Position => [qw/left right/]) },
	STYLE             => { },
	TEXT              => { required => 1 },
	CREATED           => { isa => $Milliseconds },
	MODIFIED          => { isa => $Milliseconds },
	HGAP              => { isa => Types::Standard::Int() },
	VGAP              => { isa => Types::Standard::Int() },
	VSHIFT            => { isa => Types::Standard::Int() },
	ENCRYPTED_CONTENT => { },
);

sub nodes
{
	shift->findnodes('./node')
}

sub toHash
{
	my $self = shift;
	return {
		$self->text => { map %{$_->toHash}, $self->nodes },
	}
}

sub toText
{
	require Text::Wrap;
	
	my $self = shift;
	my ($indent, $wrap) = @_;
	$indent ||= 0;
	local $Text::Wrap::columns = $wrap || 72;
	
	my $text = Text::Wrap::wrap(
		(q[ ] x ($indent * 4)).q[  * ],
		(q[ ] x (($indent+1) * 4)),
		$self->text,
	);
	
	# WTF?? Why Text::Wrap do this??
	$text =~ s/\t/        /gsm;
	
	join("\n", $text, $self->nodes->map(sub { $_->toText($indent+1, $wrap) }));
}

1;


__END__

=pod

=encoding utf-8

=head1 NAME

FreeMind::Document - a FreeMind C<< <node> >> XML element

=head1 DESCRIPTION

This is a subclass of L<XML::LibXML::Element> providing the following
attribute accessors:

=over

=item C<< background_color >>

=item C<< color >>

=item C<< folded >>

=item C<< id >>

=item C<< link >>

=item C<< position >>

=item C<< style >>

=item C<< text >>

=item C<< created >>

=item C<< modified >>

=item C<< hgap >>

=item C<< vgap >>

=item C<< vshift >>

=item C<< encrypted_content >>

=back

=head1 SEE ALSO

L<FreeMind::Document>, L<FreeMind::Map>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


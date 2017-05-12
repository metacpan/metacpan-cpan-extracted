package HTML::HTML5::ToText::Trait::RenderTables;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$HTML::HTML5::ToText::Trait::RenderTables::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::ToText::Trait::RenderTables::VERSION   = '0.004';
}

use Moose::Role;

use HTML::HTML5::Table;

has should_render_table => (
	is      => 'ro',
	isa     => 'Bool|CodeRef',
	default => 1,
	);

sub _check_render_table
{
	my ($self, $table) = @_;
	my $should = $self->should_render_table;
	if (ref $should eq 'CODE')
	{
		return $self->$should($table);
	}
	return $should;
}

around TABLE => sub {
	my ($orig, $self, $elem, %args) = @_;

	unless ($self->_check_render_table($elem))
	{
		return $orig->$self($elem, %args);
	}

	my $table = HTML::HTML5::Table->parse($elem);
	return $table->to_text($self);
};

1;

=head1 NAME

HTML::HTML5::ToText::Trait::RenderTables - render tables

=head1 DESCRIPTION

This trait performs fancy rendering on HTML tables. It's quite intelligent,
but on presentational tables, especially nested ones, doesn't look great.
However, it's not smart enough to judge whether or not it will look great.
Thus you can provide it with a callback on whether to perform fancy table
rendering, or whether to use the default table rendering.

 print HTML::HTML5::ToText
   ->with_traits(qw/RenderTables/)
   ->new(should_render_table => sub
     {
       my ($self, $element) = @_;
       if ($element->getAttribute('class') =~ /layout/i)
       {
         return 1;  # true - fancy rendering
       }
       else
       {
         return;    # false - default rendering
       }
     })
   ->process($dom);

The table rendering engine understands the C<< <caption> >>, C<< <thead> >>,
C<< <tbody> >>, C<< <tfoot> >>, C<< <tr> >>, C<< <th> >>, C<< <td> >>,
C<< <colgroup> >> and C<< <col> >> elements; and the C<< span >>,
C<< align >> (values "left", "right" and "center"), C<< colspan >> and
C<< rowspan >> attributes. It doesn't currently do C<< valign >>, but maybe
one day...

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-ToText>.

=head1 SEE ALSO

L<HTML::HTML5::ToText>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

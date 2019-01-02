# MathML::itex2MML
#
# Copyright, Jacques Distler 2018-19.
# All Rights Reserved.
# Licensed under the Perl Artistic License.
#
# Version: 1.5.9

package MathML::itex2MML;

use strict;

use base qw(Exporter);
use base qw(DynaLoader);
our $VERSION = '1.5.9';

package MathML::itex2MMLc;
bootstrap MathML::itex2MML;
package MathML::itex2MML;
our @EXPORT = qw(itex_html_filter itex_filter itex_inline_filter itex_block_filter);

# ---------- BASE METHODS -------------

package MathML::itex2MML;

sub itex_html_filter {
    my $text = shift(@_);
    itex2MML_html_filter($text, length($text));
    return itex2MML_output();
}

sub itex_filter {
    my $text = shift(@_);
    itex2MML_filter($text, length($text));
    return itex2MML_output();
}

sub itex_inline_filter {
    my $text = shift(@_);
    itex2MML_filter('$' . $text . '$', length($text) + 2);
    return itex2MML_output();
}

sub itex_block_filter {
    my $text = shift(@_);
    itex2MML_filter('$$' . $text . '$$', length($text) + 4);
    return itex2MML_output();
}

sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub FIRSTKEY { }

sub NEXTKEY { }

sub FETCH {
    my ($self,$field) = @_;
    my $member_func = "swig_${field}_get";
    $self->$member_func();
}

sub STORE {
    my ($self,$field,$newval) = @_;
    my $member_func = "swig_${field}_set";
    $self->$member_func($newval);
}

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package MathML::itex2MML;

*itex2MML_filter = *MathML::itex2MMLc::itex2MML_filter;
*itex2MML_html_filter = *MathML::itex2MMLc::itex2MML_html_filter;
*itex2MML_output = *MathML::itex2MMLc::itex2MML_output;

# ------- VARIABLE STUBS --------

package MathML::itex2MML;

1;
__END__

=head1 NAME

MathML::itex2MML - Convert itex to MathML

=head1 SYNOPSIS

 use MathML::itex2MML;

 $text    = 'This is an inline equation: $\sin(\pi/2)=1$.';

 # convert embedded itex equations to MathML:
 $converted = itex_html_filter($text);    E<35> C<<< This is an inline equation: <math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy="false">(</mo><mi>&pi;</mi><mo stretchy="false">/</mo><mn>2</mn><mo stretchy="false">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\sin(\pi/2)=1</annotation></semantics></math>. >>>

 # just the equations:
 $converted = itex_filter($text);    E<35> C<<< <math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy="false">(</mo><mi>&pi;</mi><mo stretchy="false">/</mo><mn>2</mn><mo stretchy="false">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\sin(\pi/2)=1</annotation></semantics></math> >>>

 $text    = '\sin(\pi/2)=1';

 # inline equation (without the $'s)
 $converted = itex_inline_filter($text);    E<35> C<<< <math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy="false">(</mo><mi>&pi;</mi><mo stretchy="false">/</mo><mn>2</mn><mo stretchy="false">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\sin(\pi/2)=1</annotation></semantics></math> >>>

 # block equation (without the $$'s)
 $converted = itex_block_filter($text);    E<35> C<<< <math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><semantics><mrow><mi>sin</mi><mo stretchy="false">(</mo><mi>&pi;</mi><mo stretchy="false">/</mo><mn>2</mn><mo stretchy="false">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\sin(\pi/2)=1</annotation></semantics></math> >>>

=head1 DESCRIPTION

C<MathML::itex2MML> converts itex (a dialect of LaTeX) equations into
MathML. Inline equations are demarcated by C<$..$> or C<\(...\)>. Display
equations are demarcated by C<$$...$$> or C<\[...\]>. The syntax supported
is described L<here|https://golem.ph.utexas.edu/~distler/blog/itex2MMLcommands.html>.

It is strongly suggested that you run the output through C<MathML::Entities>,
to convert named entities into either numeric character references or UTF-8 characters,
if you intend putting the result on the Web.

C<MathML::itex2MML> is based on the commandline converter, itex2MML.

=head1 FUNCTIONS

The following functions are exported by default.

=over 4

=item * itex2MML_html_filter

Take a text string, with embedded itex equations, and convert all the equations to MathML, passing through the rest of the text.

=item * itex2MML_filter

Take a text string, with embedded itex equations, and convert all the equations to MathML, dropping the rest of the text.

=item * itex2MML_inline_filter

Convert a single equation (without the enclosing $'s) to inline MathML.

=item * itex2MML_block_filter

Convert a single equation (without the enclosing $$'s) to block-display MathML.

=back

=head1 AUTHOR

Jacques Distler E<lt>distler@golem.ph.utexas.eduE<gt>

=head1 COPYRIGHT

Copyright (c) 2018 Jacques Distler. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MathML::Entitities|MathML::Entitities>

L<https://golem.ph.utexas.edu/~distler/blog/itex2MMLcommands.html>

L<https://rubygems.org/gems/itextomml>

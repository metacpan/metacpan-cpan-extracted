=head1 NAME

Devel::PerlySense::Document::Api::Method - A method/sub

=head1 DESCRIPTION

An Api::Method is a sub name and a location (possibly with a defined
row, etc).

The Method has a documentation string and possibly POD.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Document::Api::Method;
$Devel::PerlySense::Document::Api::Method::VERSION = '0.0219';




use Spiffy -Base;
use Carp;
use Data::Dumper;
use List::Util qw/ first /;

use Devel::PerlySense::Document::Api;
use Devel::PerlySense::Document::Location;





=head1 PROPERTIES

=head2 name

The method name

Default: "".

=cut
field "name" => "";





=head2 oLocationDocumented

A Document::Location object specifying where the method is documented,
or undef if that is unknown.

Default: undef.

=cut
field "oLocationDocumented" => undef;





=head2 oDocument

A PerlySense::Document object specifying in which the method belongs
to. This does not have to be the Document where it's declared.

Default: undef.

=cut
field "oDocument" => undef;





=head2 signature

Return doc string with the signature of the method, according to found
documentation, usage, etc.

Readonly.

=cut
sub signature {

    my $signature = $self->name;
    my $nameMethod = $self->name;
    if(my $oLocation = $self->oLocationDocumented) {
        my @aTextPod = split(/\n/, $oLocation->rhProperty->{text});
        $signature =
                first( sub { /->\s*\b$nameMethod\b/ }, @aTextPod )
             || first( sub { /\b$nameMethod\b/      }, @aTextPod )
             || $signature;
    }

    $signature =~ s/ .* (\b$nameMethod\b) /$1/x;
    $signature =~ s/^ \s+ | \s* ; \s* $//gx;


    return $signature;
}





=head1 API METHODS

=head2 new(oDocument, name)

Create new Method with $name belonging to $oDocument.

Set oLocationDocumented according to the found documentation.

=cut
sub new(@) {
    my $pkg = shift;
    my (%p) = @_;

    my $self = bless {}, $pkg;
    $self->name($p{name}) or croak("Missing parameter name\n");
    $self->oDocument($p{oDocument}) or croak("Missing parameter oDocument\n");
    $self->oLocationDocumented(
        $self->oDocument->oPerlySense->oLocationMethodDocFromDocument(
            $self->oDocument,
            $self->name,
        )
    );

    return($self);
}





=head2 signatureCall($oLocationDeclaration)

Return doc string with the call signature of the method, according to
the $oLocationDeclaration, etc.

The call signature is the signature with a call arrow, either -> or \>
.

=cut
sub signatureCall {
    my ($oLocationDeclaration) = @_;
    my $signature = $self->signature;

    my $prefixCall = $self->oDocument->file eq $oLocationDeclaration->file ? '->' : '\>';

    return "$prefixCall$signature";
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

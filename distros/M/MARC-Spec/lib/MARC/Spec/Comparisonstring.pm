package MARC::Spec::Comparisonstring;

use Carp qw(croak);
use Moo;
use namespace::clean;

our $VERSION = '2.0.3';

has raw => (
    is => 'rwp',
    required => 1
);

has comparable => (
    is => 'rwp'
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
   unshift @args, "raw" if @args % 2 == 1;
   return { @args };
}

sub BUILD {
    my ($self, $args) = @_;
    
    # char of list ${}!=~?|\s must be escaped if not at index 0*
    croak "MARCspec Comparisonstring exception. Unescaped character detected. Tried to parse: ".$self->raw
        unless($self->raw =~ /^(.(?:[^\$\{\}\!\=\~\?\|\s]|(?<=\\\\)[\$\{\}\!\=\~\?\|])*)$/s);

    my $comparable = $self->raw;
    my $replace = ' ';
    $comparable =~ s{\\s}{$replace}g;
    $self->_set_comparable($comparable);
    return;
}

sub to_string {
    my ($self) = @_;
    my $string = '\\'.$self->raw;
    return $string;
}
1;

__END__

=encoding utf-8

=head1 NAME

MARC::Spec::Comparisonstring - comparison string specification

=head1 SYNOPSIS

    use MARC::Spec;
    
    my $ms = MARC::Spec->new('245{$a~\marc});
    say ref $ms->field->subspecs->[0]->rightSubTerm;  # MARC::Spec::Comparisonstring

=head1 DESCRIPTION

MARC::Spec::Comparisonstring is the comparison string specification of a L<MARC::Spec|MARC::Spec>.
See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> for further 
details on the syntax.

=head1 METHODS

=head2 new

Create a new MARC::Spec::Comparisonstring instance.

=head2 to_string

Returns the spec as a string.

=head1 ATTRIBUTES

=head2 raw

Obligatory. The raw comparison string with escaped characters.

=head2 comparable

Obligatory. The comparison string without the escaping "\".

=head1 AUTHOR

Carsten Klee C<< <klee at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item * Johann Rolschewski, C<< <jorol at cpan> >>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Carsten Klee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs to L<https://github.com/MARCspec/MARC-Spec/issues|https://github.com/MARCspec/MARC-Spec/issues>


=head1 SEE ALSO

=over

=item * L<MARC::Spec|MARC::Spec>

=item * L<MARC::Spec::Field|MARC::Spec::Field>

=item * L<MARC::Spec::Subfield|MARC::Spec::Subfield>

=item * L<MARC::Spec::Indicator|MARC::Spec::Indicator>

=item * L<MARC::Spec::Subspec|MARC::Spec::Subspec>

=item * L<MARC::Spec::Structure|MARC::Spec::Structure>

=item * L<MARC::Spec::Parser|MARC::Spec::Parser>

=back

=cut

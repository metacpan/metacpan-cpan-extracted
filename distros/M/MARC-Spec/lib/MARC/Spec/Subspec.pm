package MARC::Spec::Subspec;

use Moo;
use namespace::clean;

our $VERSION = '0.1.4';

has left => (
    is => 'rw',
    isa => sub {
        croak ('Left subterm is not an instance of MARC::Spec or MARC::Spec::Comparisonstring.')
            unless(ref $_[0] eq 'MARC::Spec' or ref $_[0] eq 'MARC::Spec::Comparisonstring')
    }
);

has right => (
    is => 'rw',
    isa => sub {
        croak ('Right subterm is not an instance of MARC::Spec or MARC::Spec::Comparisonstring.')
            unless(ref $_[0] eq 'MARC::Spec' or ref $_[0] eq 'MARC::Spec::Comparisonstring')
    }
);

has operator => (
    is => 'rw',
    default => sub { "?" }
);


sub to_string {
    my ($self) = @_;
    my $string = $self->left->to_string().$self->operator.$self->right->to_string();
    return $string;
}
1;

__END__

=encoding utf-8

=head1 NAME

L<MARC::Spec::Subspec|MARC::Spec::Subspec> - subspec specification

=head1 SYNOPSIS

    use MARC::Spec;
    use MARC::Spec::Subspec;
    use MARC::Spec::Comparisonstring;
    
    # create an empty subspec
    my $subspec = MARC::Spec::Subspec->new;
    
    # create the subterms
    my $ms  = MARC::Spec->parse('245$a')';
    my $cmp = MARC::Spec::Comparisonstring->new('Perl');
    
    # add subterms to subspec
    $subspec->left($ms);
    $subspec->right($cmp);
    $subspec->operator('=');
    
    say $subspec->subterms;     # '245$a=\Perl'

=head1 DESCRIPTION

L<MARC::Spec::Subspec|MARC::Spec::Subspec> is the subspec specification of a L<MARC::Spec|MARC::Spec>.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> for further 
details on the syntax.

=head1 METHODS

=head2 new

Create a new MARC::Spec::Subspec instance.

=head2 to_string

Returns the spec as a string.

=head1 ATTRIBUTES

=head2 left

Obligatory. The left subterm: a MARCspec as a string.

=head2 right

Obligatory. The right subterm: a MARCspec as a string.

=head2 operator

One of "=", "!=", "~", "!~", "!", or "?". Default is "?".

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

L<MARC::Spec|MARC::Spec>,
L<MARC::Spec::Field|MARC::Spec::Field>,
L<MARC::Spec::Subfield|MARC::Spec::Subfield>,
L<MARC::Spec::Structure|MARC::Spec::Structure>,
L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>,
L<MARC::Spec::Parser|MARC::Spec::Parser>

=cut

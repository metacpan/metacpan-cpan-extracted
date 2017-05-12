package HTML::FormFu::Filter::Demoroniser;

use Moose;
use Text::Demoroniser;

extends 'HTML::FormFu::Filter';

our $VERSION = '0.02';

has 'encoding' => ( is => 'rw', traits => ['Chained'] );

sub filter {
    my ( $self, $value ) = @_;
    my $encoding = $self->encoding || 'utf8';

    return $encoding eq 'utf8'
        ? Text::Demoroniser::demoroniser_utf8( $value )
        : Text::Demoroniser::demoroniser( $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Filter::Demoroniser - Filter Microsoft "smart" characters

=head1 SYNOPSIS

    ---
    elements:
      - type: Text
        name: foo
        filters:
          - type: Demoroniser

=head1 DESCRIPTION

As a user fills out a form, they may copy and paste data from Micrsoft Word.
In doing so, they might inadvertently copy Microsoft "smart" characters
(fancy quotation marks, for example) into the field.

This module aims to help clean up that data in favor of UTF8 or ASCII 
alternatives.

=head1 METHODS

=head2 filter( $value )

Filters C<$value> through L<Text::Demoronise|Text::Demoronise>. By default it will use 
C<demoroniser_utf8>, though if you specify any text other than "utf8" in the 
C<encoding> option, it will convert problem characters to an ASCII 
alternative.

    ---
    elements:
      - type: Text
        name: foo
        filters:
          - type: Demoroniser
            encoding: ascii

=head1 SEE ALSO

=over 4

=item * L<HTML::FormFu|HTML::FormFu>

=item * L<Text::Demoroniser|Text::Demoroniser>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


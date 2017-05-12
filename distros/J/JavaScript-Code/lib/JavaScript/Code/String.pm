package JavaScript::Code::String;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Type ];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::String - A JavaScript String Type

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::Code::String;

    my $string = JavaScript::Code::String->new()->value("Go for it!");

    print $string->output;

=head1 METHODS

See also the L<JavaScript::Code::Type> documentation.

=head2 $self->type( )

=cut

sub type {
    return 'String';
}

=head2 $self->output( )

=cut

sub output {
    my ($self) = @_;

    my $value = $self->value;
    $value =~ s{\"}{\\\"}g;

    return qq~"$value"~;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

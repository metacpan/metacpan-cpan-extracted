package File::Serialize::Serializer::XML::Simple;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: XML::Simple serializer for File::Serialize
$File::Serialize::Serializer::XML::Simple::VERSION = '1.5.1';
use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ xml / };

sub serialize {
    my( $self, $data, $options ) = @_;
    XML::Simple->new->XMLout($data);
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    XML::Simple->new->XMLin($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::XML::Simple - XML::Simple serializer for File::Serialize

=head1 VERSION

version 1.5.1

=head1 DESCRIPTION

=over

=item B<extensions>

C<xml>.

=item B<precedence>

100

=item B<module used>

L<XML::Simple>

=item B<supported options>

None

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

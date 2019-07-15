package File::Serialize::Serializer::JSON5;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: JSON5 serializer for File::Serialize
$File::Serialize::Serializer::JSON5::VERSION = '1.3.0';
use strict;
use warnings;

use Module::Runtime qw/ use_module /;

use Moo;
extends 'File::Serialize::Serializer::JSON::MaybeXS';

sub extensions { qw/ json5 / };

sub required_modules {
    qw/ JSON5 JSON::MaybeXS /
}

sub deserialize {
    my( $self, $data, $options ) = @_;
    use_module('JSON5');
    return JSON5::decode_json5($data,$options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::JSON5 - JSON5 serializer for File::Serialize

=head1 VERSION

version 1.3.0

=head1 DESCRIPTION

=over

=item B<extensions>

C<json5>.

=item B<precedence>

100

=item B<module used>

L<JSON5>, L<JSON::MaybeXS>

=item B<supported options>

pretty (default: true), canonical (default: true), allow_nonref (default: true)

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

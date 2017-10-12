package File::Serialize::Serializer::Data::Dumper;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Data::Dumper serializer for File::Serialize
$File::Serialize::Serializer::Data::Dumper::VERSION = '1.2.0';
use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

use Module::Runtime 'use_module';

sub extensions { qw/ pl perl / };

sub serialize {
    my( $self, $data, $options ) = @_;
    Data::Dumper::Dumper($data);
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    no strict;
    no warnings;
    return eval $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::Data::Dumper - Data::Dumper serializer for File::Serialize

=head1 VERSION

version 1.2.0

=head1 DESCRIPTION

=over

=item B<extensions>

C<pl>, C<perl>.

=item B<precedence>

100

=item B<module used>

L<Data::Dumper>

=item B<supported options>

none

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

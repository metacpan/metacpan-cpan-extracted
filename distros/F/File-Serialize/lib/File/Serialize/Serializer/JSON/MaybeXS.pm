package File::Serialize::Serializer::JSON::MaybeXS;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: JSON::MaybeXS serializer for File::Serialize
$File::Serialize::Serializer::JSON::MaybeXS::VERSION = '1.5.1';
use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ json js / };

sub serialize {
    my( $self, $data, $options ) = @_;
    JSON::MaybeXS->new(%$options)->encode( $data);
}

sub deserialize {
    my( $self, $data, $options ) = @_;
    JSON::MaybeXS->new(%$options)->decode( $data);
}

sub groom_options {
   my( $self, $options ) = @_;

    my %groomed;
    for my $k( qw/ pretty canonical allow_nonref / ) {
        $groomed{$k} = $options->{$k} if defined $options->{$k};
    }

    return \%groomed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::JSON::MaybeXS - JSON::MaybeXS serializer for File::Serialize

=head1 VERSION

version 1.5.1

=head1 DESCRIPTION

=over

=item B<extensions>

C<json>, C<js>.

=item B<precedence>

100

=item B<module used>

L<JSON::MaybeXS>

=item B<supported options>

pretty (default: true), canonical (default: true), allow_nonref (default: true)

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

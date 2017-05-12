package Dictionary::Cambridge::Response;
our $AUTHORITY = 'cpan:JINNKS';
#ABSTRACT: the roles to parse different part of the xml returned
$Dictionary::Cambridge::Response::VERSION = '0.02';

use Moose::Role;
use XML::LibXML;
use namespace::autoclean;
use List::MoreUtils qw( zip );

has "xml" => (
    is         => 'ro',
    isa        => 'XML::LibXML',
    lazy_build => 1
);

sub _build_xml {
    return XML::LibXML->new();
}


sub parse_xml_def_eg {
    my ( $self, $xml_data ) = @_;
    my $doc = $self->xml->load_xml( string => $xml_data );
    my %definition = ();

    my @pos_blocks = $doc->findnodes( '//di/pos-block' );
    for my $pos_block (@pos_blocks) {
        my $pos = $pos_block->findvalue( './header/info/posgram/pos' );
        my @defs = $pos_block->findnodes( './sense-block/def-block' );
        for my $d( @defs ) {
            my $def = $d->findvalue('./definition/def');
            my @eg = map { $_->string_value() } $d->findnodes('./examp/eg');
            push @{$definition{$pos}},{"definition" => $def, "example" => \@eg};
        }

    }
    return \%definition;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dictionary::Cambridge::Response - the roles to parse different part of the xml returned

=head1 VERSION

version 0.02

=head2 METHODS
    parse_xml_def_eg
    params: xml content of the API get_entry call

=head1 AUTHOR

Farhan Siddiqui <forsadia@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Farhan Siddiqui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

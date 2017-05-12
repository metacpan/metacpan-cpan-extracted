use 5.010;
use strict;
use warnings;

package Geo::Openstreetmap::Parser;
$Geo::Openstreetmap::Parser::VERSION = '0.03';
# ABSTRACT: Openstreetmap XML dump parser

use autodie;

use XML::Parser;



sub new
{
    my ($class, %callback) = @_;
    
    my $self = bless { callback => \%callback }, $class;
    $self->_init_parser();
    return $self;
}



sub parse
{
    my ($self, $fh) = @_;
    $self->{parser}->parse($fh);
    return;
}




sub _init_parser
{
    my ($self) = @_;

    my @path;

    $self->{parser} = XML::Parser->new( Handlers => {
            Start => sub {
                    my ($expat, $el, %attr) = @_;
                    push @path, { attr => \%attr };
                },
            End => sub {
                    my ($expat, $el) = @_;
                    my $obj = pop @path;

                    if ($el eq 'tag')    { $path[-1]->{$el}->{$obj->{attr}->{k}} = $obj->{attr}->{v} }
                    if ($el eq 'nd')     { push @{$path[-1]->{$el}}, $obj->{attr}->{ref} }
                    if ($el eq 'member') { push @{$path[-1]->{$el}}, $obj->{attr} }
                    if (my $cb = $self->{callback}->{$el})    { $cb->($obj) }
                },
        });
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::Openstreetmap::Parser - Openstreetmap XML dump parser

=head1 VERSION

version 0.03

=head1 METHODS

=head2 new

Creates a parser object

    my $parser = Geo::Openstreetmap::Parser->new( node => \&process_node, ... );

    sub process_node {
        my ($obj) = @_;
        ...
    }

Callbacks are possible for any tag, but useful for osm primitives:
    node
    way
    relation

Callback function receives hash with params:
    attr    - hash with xml attributes
    tag     - hash with osm tags
    nd      - array of node_ids (for ways)
    member  - array of hashes like { type => 'way', role => 'from', ref => '-1' } (for relations)

=head2 parse

Parses XML input, executing defined callback functions for OSM objects

    $parser->parse( *STDIN );

=head1 AUTHOR

liosha <liosha@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by liosha.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

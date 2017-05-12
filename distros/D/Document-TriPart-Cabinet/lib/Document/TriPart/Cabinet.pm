package Document::TriPart::Cabinet;
BEGIN {
  $Document::TriPart::Cabinet::VERSION = '0.011';
}
# ABSTRACT: Document::TriPart::Cabinet 

use warnings;
use strict;

use Moose;

use Document::TriPart::Cabinet::Document;
use Document::TriPart::Cabinet::UUID;

use Carp::Clan;
use Path::Abstract;
use DateTimeX::Easy;
use File::Temp;
use Path::Class;

has storage => qw/is ro required 1/;
has document_class => qw/is rw required 1/, default => 'Document::TriPart::Cabinet::Document';

sub create {
    my $self = shift;
    return $self->inflate_document( uuid => Document::TriPart::Cabinet::UUID->make, @_ );
}

sub inflate_document {
    my $self = shift;
    return $self->document_class->new( cabinet => $self, @_ );
}

sub load {
    my $self = shift;
    my $uuid = shift;

    $uuid = Document::TriPart::Cabinet::UUID->normalize( $uuid );
    my $document = $self->inflate_document( uuid => $uuid );
    $document->load();
    return $document;
}

sub edit {
    my $self = shift;
    my $uuid = shift;

    $uuid = Document::TriPart::Cabinet::UUID->normalize( $uuid );
    my $document = $self->load( $uuid );
    $document->edit();
    return $document;
}

1;

__END__
=pod

=head1 NAME

Document::TriPart::Cabinet - Document::TriPart::Cabinet 

=head1 VERSION

version 0.011

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


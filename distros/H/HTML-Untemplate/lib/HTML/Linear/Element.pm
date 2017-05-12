package HTML::Linear::Element;
# ABSTRACT: represent elements to populate HTML::Linear
use strict;
use utf8;
use warnings qw(all);

use Digest::SHA;
use Encode;
use List::Util qw(sum);
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use HTML::Linear::Path;

## no critic (ProtectPrivateSubs)

our $VERSION = '0.019'; # VERSION


has attributes  => (is => 'rw', isa => HashRef[Str], default => sub { {} });
has content     => (is => 'rw', isa => Str, default => sub { '' });
has depth       => (is => 'ro', isa => Int, required => 1);
has index       => (is => 'rw', isa => Int, default => sub { 0 });
has index_map   => (is => 'rw', isa => HashRef[Str], default => sub { {} });
has key         => (is => 'rw', isa => Str, default => sub { '' });
has path        => (is => 'ro', isa => ArrayRef[InstanceOf('HTML::Linear::Path')], required => 1);
has sha         => (is => 'ro', isa => InstanceOf('Digest::SHA'), default => sub { Digest::SHA->new(256) }, lazy => 1 );
has strict      => (is => 'ro', isa => Bool, default => sub { 0 });
has trim_at     => (is => 'rw', isa => Int, default => sub { 0 });

use overload '""' => \&as_string, fallback => 1;


sub BUILD {
    my ($self) = @_;
    $self->attributes({%{$self->path->[-1]->attributes}});
    return;
}


sub as_string {
    my ($self) = @_;
    return $self->key if $self->key;

    my $content = $self->content;
    Encode::_utf8_off($content);
    $self->sha->add($content);

    $self->sha->add($self->index);
    $self->sha->add(join ',', $self->path);

    return $self->key($self->sha->b64digest);
}


sub as_xpath {
    my ($self) = @_;
    my @xpath = map {
        $_->as_xpath . ($self->index_map->{$_->address} // '')
    } @{$self->path} [$self->trim_at .. $#{$self->path}];
    $self->trim_at and unshift @xpath, HTML::Linear::Path::_wrap(separator => '/');
    return wantarray
        ? @xpath
        : join '', @xpath;
}


sub as_hash {
    my ($self) = @_;
    my $hash = {};
    my $xpath = $self->as_xpath . HTML::Linear::Path::_wrap(separator => '/');

    for my $key (sort keys %{$self->attributes}) {
        $hash->{
            $xpath
            . HTML::Linear::Path::_wrap(sigil       => '@')
            . HTML::Linear::Path::_wrap(attribute   => $key)
        } = $self->attributes->{$key}
            if
                $self->strict
                or not HTML::Linear::Path::_isgroup($self->path->[-1]->tag, $key);
    }

    $hash->{
        $xpath
        . HTML::Linear::Path::_wrap(attribute => 'text()')
    } = $self->content
        unless $self->content =~ m{^\s*$}sx;

    return $hash;
}


sub weight {
    my ($self) = @_;
    return sum map { $_->weight } @{$self->path};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Linear::Element - represent elements to populate HTML::Linear

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use HTML::Linear::Element;
    use HTML::Linear::Path;

    my $el = HTML::Linear::Element->new({
        depth   => 0,
        path    => [ HTML::Linear::Path->new({ address => q(...), tag => q(...) }) ],
    })

=head1 ATTRIBUTES

=head2 attributes

Element attributes.

=head2 content

Element content.

=head2 depth

Depth level of an element inside a L<HTML::TreeBuilder> structure.

=head2 index

Index to preserve elements order.

=head2 index_map

Used for internal collision detection.

=head2 key

Stringified element representation.

=head2 path

Store representations of paths inside C<HTML::TreeBuilder> structure (L<HTML::Linear::Path>).

=head2 sha

Lazy L<Digest::SHA> (256-bit) representation.

=head2 strict

Strict mode disables grouping by tags/attributes listed in L<HTML::Linear::Path/%HTML::Linear::Path::groupby>.

=head2 trim_at

XPath seems to be unique after that level.

=head1 METHODS

=head2 as_string

Stringified signature of an element.

=head2 as_xpath

Build a nice XPath representation of a path inside the L<HTML::TreeBuilder> structure.

Returns string in scalar context or XPath segments in list context.

=head2 as_hash

Linearize element as an associative array (Perl hash).

=head2 weight

Return XPath weight.

=for Pod::Coverage BUILD

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

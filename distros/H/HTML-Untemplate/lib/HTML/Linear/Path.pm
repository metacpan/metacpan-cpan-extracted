package HTML::Linear::Path;
# ABSTRACT: represent paths inside HTML::Tree
use strict;
use utf8;
use warnings qw(all);

use JSON;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use HTML::Linear::Path::Colors;

## no critic (ProhibitPackageVars)

our $VERSION = '0.019'; # VERSION


has json        => (
    is          => 'ro',
    isa         => InstanceOf['JSON'],
    default     => sub { JSON->new->ascii->canonical },
    lazy        => 1,
);


has address     => (is => 'rw', isa => Str, required => 1);
has attributes  => (is => 'ro', isa => HashRef[Str], required => 1);
has is_groupable=> (is => 'rw', isa => Bool, default => sub { 0 });
has key         => (is => 'rw', isa => Str, default => sub { '' });
has strict      => (is => 'ro', isa => Bool, default => sub { 0 });
has tag         => (is => 'ro', isa => Str, required => 1);

use overload '""' => \&as_string, fallback => 1;


our %groupby = (
    class       => [qw(*)],
    id          => [qw(*)],
    name        => [qw(input meta)],
    'http-equiv'=> [qw(meta)],
    property    => [qw(meta)],
    rel         => [qw(link)],
);


our %tag_weight = (
    title       => 15,
    h1          => 10,
    h2          => 9,
    h3          => 8,
    h4          => 7,
    h5          => 6,
    h6          => 5,
    center      => 3,
    strong      => 2,
    b           => 2,
    u           => 1,
    em          => 1,
    a           => 1,
    sup         => -1,
    sub         => -1,
    samp        => -1,
    pre         => -1,
    kbd         => -1,
    code        => -1,
    blockquote  => -1,
);


our (%xpath_wrap) = (%{$HTML::Linear::Path::Colors::scheme{default}});


sub as_string {
    my ($self) = @_;
    return $self->key if $self->key;

    my $ref = {
        _tag    => $self->tag,
        addr    => $self->address,
    };
    $ref->{attr} = $self->attributes if keys %{$self->attributes};

    return $self->key($self->json->encode($ref));
}


sub as_xpath {
    my ($self, $strict) = @_;

    my $xpath = _wrap(separator => '/') . _wrap(tag => $self->tag);

    my $expr = '';
    for my $attr (keys %groupby) {
        if (_isgroup($self->tag, $attr) and $self->attributes->{$attr}) {
            $expr .= _wrap(array        => '[');
            $expr .= _wrap(sigil        => '@');
            $expr .= _wrap(attribute    => $attr);
            $expr .= _wrap(equal        => '=');
            $expr .= _wrap(value        => _quote($self->attributes->{$attr}));
            $expr .= _wrap(array        => ']');

            $self->is_groupable(1);

            last;
        }
    }

    return $xpath . (
        (not $self->strict and not $strict)
            ? $expr
            : ''
    );
}


sub weight {
    my ($self) = @_;
    return $tag_weight{$self->tag} // 0;
}


sub _quote {
    local ($_) = @_;

    s/\\/\\\\/gsx;
    s/'/\\'/gsx;
    s/\s+/ /gsx;
    s/^\s//sx;
    s/\s$//sx;

    return "'$_'";
}


sub _wrap {
    my ($p, $q) = @_;
    return
        $xpath_wrap{$p}->[0]
        . $q
        . $xpath_wrap{$p}->[1];
}


sub _isgroup {
    my ($tag, $attr) = @_;
    return (
        1 and grep {
            $_ eq '*'
                or
            $_ eq $tag
        } @{$groupby{$attr} // []}
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Linear::Path - represent paths inside HTML::Tree

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use HTML::Linear::Path;

    my $level = HTML::Linear::Path->new({
        address     => q(0.1.1.3.0),
        attributes  => {
            id  => q(li1),
        },
        strict      => 0,
        tag         => q(li),
    });

=head1 ATTRIBUTES

=head2 json

Lazy L<JSON> instance.

=head2 address

Location inside L<HTML::TreeBuilder> tree.

=head2 attributes

Element attributes.

=head2 key

Stringified path representation.

=head2 strict

Strict mode disables grouping by tags/attributes listed in L</%HTML::Linear::Path::groupby>.

=head2 tag

Tag name.

=head1 METHODS

=head2 as_string

Build a quick & dirty string representation of a path the L<HTML::TreeBuilder> structure.

=head2 as_xpath

Build a nice XPath representation of a path inside the L<HTML::TreeBuilder> structure.

=head2 weight

Return tag weight.

=head1 FUNCTIONS

=head2 _quote

Quote attribute values for XPath representation.

=head2 _wrap

Help to make a fancy XPath.

=head2 _isgroup($tag, $attribute)

Checks if C<$tag>/C<$attribute> tuple matches L</%HTML::Linear::Path::groupby>.

=head1 GLOBALS

=head2 %HTML::Linear::Path::groupby

Tags/attributes significant as XPath filters.
C<@class>/C<@id> are the most obvious; we also use C<meta/@property>, C<input/@name> and several others.

=head2 %HTML::Linear::Path::tag_weight

Table of HTML tag weights.
Borrowed from L<TexNet32 - WWW filters|http://publish.uwo.ca/~craven/texnet32/wwwnet32.htm>.

=head2 %HTML::Linear::Path::xpath_wrap

Wrap XPath components to produce fancy syntax highlight.

The format is:

    (
        array       => ['' => ''],
        attribute   => ['' => ''],
        equal       => ['' => ''],
        number      => ['' => ''],
        separator   => ['' => ''],
        sigil       => ['' => ''],
        tag         => ['' => ''],
        value       => ['' => ''],
    )

There are several pre-defined schemes at L<HTML::Linear::Path::Colors>.

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

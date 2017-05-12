package HTTP::Body::Pairs;
our $VERSION = '0.3';

# ABSTRACT: methods for getting body params in the order they were sent

use strict;
use warnings;

{
    require HTTP::Body;
    my $vanilla = \&HTTP::Body::param;
    no warnings 'redefine';
    *HTTP::Body::param = sub {
        if (@_ > 2) {
            my ($self, $name, $value) = @_;
            push @{ $self->{pairs} }, $name, $value;
        }
        goto $vanilla;
    };
}

sub HTTP::Body::flat_pairs { @{ $_[0]->{pairs} } }

sub HTTP::Body::pairs {
    my $a = $_[0]->{pairs};
    my @result;
    for (my $i = 0; $i < @$a; $i += 2) {
        push @result, [@{$a}[$i, $i+1]];
    }
    return @result;
}

1;

=head1 NAME

HTTP::Body::Pairs

=head1 VERSION

version 0.3

=head1 SYNOPSIS

    use HTTP::Body::Pairs;

    my $body = HTTP::Body->new(...);
    for ($body->pairs) {
        my ($key, $val) = @$_;
        # ... 
    }

=head1 DESCRIPTION

Adds functionality to HTTP::Body for retaining order information from the
parsed http body.

=head1 METHODS

=head2 flat_pairs

Returns the ordered pairs as a flat list, e.g. ('foo', 'fooval', 'foo',
'fooval2', 'bar', 'barval');

=head2 pairs

Returns the ordered pairs as a list of array refs, e.g. (['foo', 'fooval'],
['foo', 'fooval2'], ['bar', 'barval']).

=head1 RATIONALE

You don't normally need to know the order parameters came in.  Usually if you
need order at all, you only need to know the order for a particular param.
That being the case, the extra storage overhead isn't warranted in HTTP::Body.
This is for the odd case where you do need the order.

=head1 AUTHOR

Paul Driver C<< frodwith@cpan.org >>
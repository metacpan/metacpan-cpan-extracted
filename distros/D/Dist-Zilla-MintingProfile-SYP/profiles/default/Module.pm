package {{$name}};
# ABSTRACT: ...

=head1 SYNOPSIS

    #!/usr/bin/env perl;
    use common::sense;
    use {{$name}};
    ...

=head1 DESCRIPTION

...

=cut

use strict;
use utf8;
use warnings qw(all);

# use common::sense;
#
# use base 'Exporter';
#
# our %EXPORT_TAGS    = (all => [qw[]]);
# our @EXPORT_OK      = (@$EXPORT_TAGS{all});
# our @EXPORT         = qw();

# use Carp qw(carp confess);

use Moose;
# use Moo;
# use MooX::Types::MooseLike::Base qw(
#     AnyOf
#     ArrayRef
#     Bool
#     HashRef
#     InstanceOf
#     Int
#     Num
#     Object
#     Str
#     is_Int
# );

# with 'Some::Class';
# extends 'Other::Class';

# no if ($] >= 5.017010), warnings => 'experimental';

# VERSION

# =attr attribute
#
# ...
#
# =cut

has attribute   => (is => 'ro', isa => 'Int', default => sub { 0 });

# arount parent_method => sub {
#     my $name = shift;
#     my $orig = shift;
#     my $self = shift;
#
#     $orig->($self => @_);
# };

=for Pod::Coverage
BUILD
=cut

sub BUILD {
    my ($self) = @_;
}

# =method method($param)
#
# ...
#
# =cut

sub method {
    my ($self, $param) = @_;
}

=head1 SEE ALSO

=for :list
* L<Moose>
* L<Moo>
* L<MooX::Types::MooseLike::Base>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;

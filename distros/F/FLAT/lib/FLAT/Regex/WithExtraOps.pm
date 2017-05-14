package FLAT::Regex::WithExtraOps;
use base 'FLAT::Regex';

use strict;
use Carp;

my $PARSER = FLAT::Regex::Parser->new(qw[ alt concat star negate shuffle ]);
sub _parser { $PARSER }

sub members {
    my $self = shift;
    wantarray ? @$self[0 .. $#$self] : $self->[0];
}

#### Precedence
# 30 ::star
# 20 ::concat
# 15 ::negate   <---<< WithExtraOps
# 12 ::shuffle  <---<< WithExtraOps
# 10 ::alt
# 0  ::atomic

###############################
package FLAT::Regex::Op::negate;
use base "FLAT::Regex::Op";
use Carp;

sub parse_spec { "'~' %s"; }
sub precedence { 15 } # between concat and alternation

sub as_string {
    my ($self, $prec) = @_;
    my $result = "~" . $self->members->as_string($self->precedence);
    return $prec > $self->precedence ? "($result)" : $result;
}

sub from_parse {
    my ($pkg, @item) = @_;
    $pkg->new( $item[2] );
}

## note: "reverse" conflicts with perl builtin
sub reverse {
    my $self = shift;
    my $op   = $self->members->reverse;
    __PACKAGE__->new($op);
}

sub is_empty {
    croak "Not implemented for negated regexes";
}

sub has_nonempty_string {
    croak "Not implemented for negated regexes";
}

sub is_finite {
    croak "Not implemented for negated regexes";
}

###############################
package FLAT::Regex::Op::shuffle;
use base 'FLAT::Regex::Op';
use Carp;

sub parse_spec { "%s(2.. /[&]/)" }
sub precedence { 12 }

sub as_string {
    my ($self, $prec) = @_;
    my $result = join "&",
                 map { $_->as_string($self->precedence) }
                 $self->members;
    return $prec > $self->precedence ? "($result)" : $result;
}

sub as_perl_regex {
    my $self = shift;
    croak "Not implemented for shuffled regexes";
}

sub from_parse {
    my ($pkg, @item) = @_;
    $pkg->new( @{ $item[1] } );
}

sub as_pfa {
    my $self = shift;
    my @parts = map { $_->as_pfa } $self->members;
    $parts[0]->shuffle( @parts[1..$#parts] );
}

# Implement?
sub reverse {
    my $self = shift;
    croak "Not implemented for shuffled regexes";
}

sub is_empty {
    croak "Not implemented for shuffled regexes";
}

sub has_nonempty_string {
    croak "Not implemented for shuffled regexes";
}

sub is_finite {
    croak "Not implemented for shuffled regexes";
}

package Graphviz::DSL::Component;
use strict;
use warnings;

sub update_attributes {
    my ($self, $attrs) = @_;

 OUTER:
    for my $attr (@{$attrs}) {
        my ($key, $val) = @{$attr};
        for my $old_attr (@{$self->{attributes}}) {
            my ($old_key, $old_val) = @{$old_attr};

            if ($key eq $old_key) {
                $old_attr->[1] = $val;
                next OUTER;
            }
        }

        push @{$self->{attributes}}, $attr;
    }
}

sub as_string {
    die "'as_string' method should be overwritten by subclass";
}

# accessor
sub attributes { $_[0]->{attributes}; }

1;

__END__

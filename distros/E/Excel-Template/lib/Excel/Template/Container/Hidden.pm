package Excel::Template::Container::Hidden;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw( Excel::Template::Container::Format );

    use Excel::Template::Container::Format;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{HIDDEN} = 1;

    return $self;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Hidden - Excel::Template::Container::Hidden

=head1 PURPOSE

To format all children in hidden

=head1 NODE NAME

HIDDEN

=head1 INHERITANCE

Excel::Template::Container::Format

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

You must have protected the worksheet containing any cells that are affected by
this format. Otherwise, this node will have no effect.

=head1 USAGE

  <hidden>
    ... Children here
  </hidden>

In the above example, the children will be displayed (if they are displaying
elements) in a hidden format. All other formatting will remain the same and the
"hidden"-ness will end at the end tag.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

WORKSHEET, FORMAT

=cut

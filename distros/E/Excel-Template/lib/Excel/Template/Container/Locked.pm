package Excel::Template::Container::Locked;

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

    $self->{LOCKED} = 1;

    return $self;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Locked - Excel::Template::Container::Locked

=head1 PURPOSE

To format all children in locked

=head1 NODE NAME

LOCKED

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

  <locked>
    ... Children here
  </locked>

In the above example, the children will be displayed (if they are displaying
elements) in a locked format. All other formatting will remain the same and the
"locked"-ness will end at the end tag.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

WORKSHEET, FORMAT

=cut

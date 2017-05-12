package Excel::Template::Container::Outline;

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

    $self->{FONT_OUTLINE} = 1;

    return $self;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Outline - Excel::Template::Container::Outline

=head1 PURPOSE

To format all children in outline

=head1 NODE NAME

OUTLINE

=head1 INHERITANCE

Excel::Template::Container::Format

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <outline>
    ... Children here
  </outline>

In the above example, the children will be displayed (if they are displaying
elements) in a outline format. All other formatting will remain the same and the
"outline"-ness will end at the end tag.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

FORMAT

=cut

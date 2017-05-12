package Excel::Template::Container::Italic;

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

    $self->{ITALIC} = 1;

    return $self;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Italic - Excel::Template::Container::Italic

=head1 PURPOSE

To format all children in italic

=head1 NODE NAME

ITALIC

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

  <italic>
    ... Children here
  </italic>

In the above example, the children will be displayed (if they are displaying
elements) in a italic format. All other formatting will remain the same and the
"italic"-ness will end at the end tag.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

FORMAT

=cut

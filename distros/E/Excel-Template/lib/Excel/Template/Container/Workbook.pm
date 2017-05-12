package Excel::Template::Container::Workbook;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw( Excel::Template::Container );

    use Excel::Template::Container;
}

1;
__END__

=head1 NAME

Excel::Template::Container::Workbook - Excel::Template::Container::Workbook

=head1 PURPOSE

The root node

=head1 NODE NAME

WORKBOOK

=head1 INHERITANCE

Excel::Template::Container

=head1 ATTRIBUTES

Currently, none. There will be attributes added here, regarding how the
workbook as a whole will behave.

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <workbook>
    ... Children here
  </workbook>

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

Nothing

=cut

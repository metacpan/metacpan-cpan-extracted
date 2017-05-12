package Excel::Template::Container::Scope;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Container);

    use Excel::Template::Container;
}

# This is used as a placeholder for scoping values across any number
# of children. It does nothing on its own.

1;
__END__

=head1 NAME

Excel::Template::Container::Scope - Excel::Template::Container::Scope

=head1 PURPOSE

To provide scoping of parameters for children

=head1 NODE NAME

SCOPE

=head1 INHERITANCE

Excel::Template::Container

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <scope param1="value1" param2="value2">
    ... Children here ...
  </scope>

In the above example, the children would all have access to the parameters
param1 and param2. This is useful if you have a section of your template that
all has the same set of parameter values, but don't have a common parent.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut

# Stuff used by all the Language::Basic packages
package Language::Basic::Common;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

BEGIN{
use Exporter ();
@ISA = qw(Exporter);
@EXPORT = qw(
    &Exit_Error
);
}

# Declare some "type" packages, String, Boolean, Numeric.
# Need to declare them here because several sets of classes inherit
# from them. E.g., LB::Variables and LB::Expressions
{
package Language::Basic::String;
package Language::Basic::Boolean;
package Language::Basic::Numeric;
}

# THis sub prints out an error and exits the program.
sub Exit_Error {
    my $err = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $error_line = $prog->current_line_number;

    STDOUT->flush; # in case we're in the middle of a PRINT statement...
    warn "\nError in line $error_line: $err\n";
    # TODO change to "set_goto_line(undef)" so we can continue on
    # another program if we're running two simultaneously!
    exit (1);
}

1;

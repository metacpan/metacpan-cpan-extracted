# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package DoitX::Example;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Doit::Log; # imports info, warning, error ...

# Provide a constructor just creating a blessed DoitX::Example
sub new { bless {}, shift }

# List all functions which should be available as Doit commands.
# Commands should have a distinct prefix (here: "example_"), to
# avoid clashes with other Doit component commands. As a convention,
# use the 2nd part of the module name, in lower case.
sub functions { qw(example_hello_world) }

# The definition of the command. Note that $self is really a
# Doit::Runner object, not a DoitX::Example object. This way
# it's possible to use Doit commands here.
sub example_hello_world {
    my($self, $arg) = @_;
    info "example_hello_world called with arg=$arg";
    $self->system($^X, '-e', q{print "hello, world\n"});
    42;
}

1;

__END__

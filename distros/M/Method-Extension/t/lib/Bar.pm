#
# This file is part of Method-Extension
#
# This software is Copyright (c) 2015 by Tiago Peczenyj.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
package Bar;
use Method::Extension;

sub new { 
    bless {}, $_[0];    
}

sub baz :ExtensionMethod(Foo::baz) {
    "Baz from extension method";
}

1;

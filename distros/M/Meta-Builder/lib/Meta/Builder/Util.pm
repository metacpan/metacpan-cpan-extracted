package Meta::Builder::Util;
use strict;
use warnings;

sub import {
    my $class = shift;
    my $caller = caller;
    inject( $caller, "inject", \&inject );
}

sub inject {
    my ( $class, $sub, $code, $nowarn ) = @_;
    if ( $nowarn ) {
        no strict 'refs';
        no warnings 'redefine';
        *{"$class\::$sub"} = $code;
    }
    else {
        no strict 'refs';
        *{"$class\::$sub"} = $code;
    }
}

1;

__END__

=head1 NAME

Meta::Builder::Util - Utility functions for Meta::Builder

=head1 EXPORTS

=over 4

=item inject( $class, $name, $code, $redefine )

used to inject a sub into a namespace.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Meta-Builder is free software; Standard perl licence.

Meta-Builder is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.

package Fennec::Declare;
use strict;
use warnings;

our $VERSION = "1.002";

use base 'Fennec';
require Fennec::Declare::Magic;

sub defaults {
    my $class    = shift;
    my %defaults = $class->SUPER::defaults();

    push @{$defaults{'utils'}} => 'Fennec::Declare::Magic';

    return (%defaults);
}

1;

__END__

=head1 NAME

Fennec::Declare - Declarative interface for Fennec.

=head1 DESCRIPTION

This is a declarative interface for L<Fennec>. In short this improves the
syntax used to define tests with Fennec.

=over 4

=item No more name => sub

=item no more semicolon to end the test sub.

=item overrides describe, cases, case, it, tests, before_* after_*

    describe name { ... }

instead of

    describe name => sub { ... };

=back

=head1 SYNOPSIS

    package Declare::Test;
    use strict;
    use warnings;

    use Fennec::Declare;

    tests foo {
        ok( 1, "Declarative test!" );
    }

    tests old => sub {
        ok( 1, "old style" );
    };

    describe blah {
        tests group_a { ok( 1, 'a' )}
        tests group_b { ok( 1, 'b' )}
        tests group_c { ok( 1, 'c' )}
        tests group_d { ok( 1, 'd' )}
        tests group_e { ok( 1, 'e' )}
        describe foo {
            tests group_x { ok( 1, 'x' )}
        }
    };

    tests todo_group (todo => "This is a todo group") {
        ok( 0, "This should fail, no worries" )
    }

    tests should_fail (should_fail => 1) {
        die "You should not see this!"
    }

    tests skip_group (skip => "This is a skip group") {
        ok( 0, "You should not see this!" )
    }

    1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Fennec-Declare is free software; Standard perl licence.

Fennec-Declare is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

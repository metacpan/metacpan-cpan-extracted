package Fennec::Meta;
use strict;
use warnings;

use Fennec::Util qw/accessors/;

accessors qw/parallel class fennec base test_sort with_tests post debug/;

sub new {
    my $class = shift;
    my %proto = @_;
    bless(
        {
            $proto{fennec}->defaults(),
            %proto,
        },
        $class
    );
}

1;

__END__

=head1 NAME

Fennec::Meta - The meta-object added to all Fennec test classes.

=head1 DESCRIPTION

When you C<use Fennec;> a function is added to you class named 'FENNEC' that
returns the single Fennec meta-object that tracks information about your class.

=head1 ATTRIBUTES

=over 4

=item parallel

Maximum number of parallel tests that can be run for your class.

=item class

Name of your class.

=item fennec

Name of the class that was used to load fennec (usually 'Fennec')

=item base

Base class Fennec put in place, if any.

=item test_sort

What method of test sorting was specified, if any.

=item with_tests

List of test templates loaded into your class.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

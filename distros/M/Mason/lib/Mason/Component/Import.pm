package Mason::Component::Import;
$Mason::Component::Import::VERSION = '2.24';
use strict;
use warnings;

sub import {
    my $class  = shift;
    my $caller = caller;
    $class->import_into($caller);
}

sub import_into {
    my ( $class, $for_class ) = @_;

    # no-op by default
}

1;

__END__

=pod

=head1 NAME

Mason::Component::Import - Extra component imports

=head1 DESCRIPTION

This module is automatically use'd in each generated Mason component class. It
imports nothing by default, but you can modify the C<import_into> method in
plugins to add imports.

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Embedix::ECD::Node;

use strict;

# XXX : I'm just getting this started.  Eventually, huge chunks
# of Embedix::ECD will be moved here.  There are, however, more
# important things to be done first, like making a faster parser
# and doing other things in Embedix::DB::Pg.

1;

__END__

=head1 NAME

Embedix::ECD::Node - a base class for ECD nodes

=head1 SYNOPSIS

instantiation

    # don't instantiate me!

inheriting

    package Embedix::ECD::Group;
    use vars qw(@ISA);

    @ISA = qw(Embedix::ECD::Node);

=head1 REQUIRES

=over 4

=item Some::Module

=back

=head1 DESCRIPTION

a brief summary of the module written with users in mind.

=head1 METHODS

methods

=head1 CLASS VARIABLES

cvars

=head1 DIAGNOSTICS

error messages

=head1 COPYRIGHT

Copyright (c) 2000 John BEPPU.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

John BEPPU <beppu@lineo.com>

=head1 SEE ALSO

=over 4

=item related perl modules

=item the latest version

=back

=cut

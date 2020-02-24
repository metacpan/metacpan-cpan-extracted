# -*- mode: cperl; coding: latin-2 -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2006,2007,2020 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Schema::Kwalify;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.05';

use Kwalify qw();

sub new {
    bless {}, shift;
}

sub validate {
    my($self, $schema, $data) = @_;
    Kwalify::validate($schema, $data);
}

1;

__END__

=encoding iso-8859-2

=head1 NAME

Schema::Kwalify - Kwalify implementation in the Schema:: namespace

=head1 SYNOPSIS

Not yet

=head1 DESCRIPTION

I expect that there will be other schema languages for data structures
defined. It would be nice if the implementations would use the
B<Schema::> namespace, and that these modules share a common
interface.

=head1 AUTHOR

Slaven Reziæ, E<lt>srezic@cpan.orgE<gt>

=head1 SEE ALSO

L<Kwalify>.

=cut

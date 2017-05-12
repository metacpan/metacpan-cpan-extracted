package Launcher::Cascade::ListOfStrings::Context;

=head1 NAME

Launcher::Cascade::ListOfStrings::Context - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade::ListOfStrings );

Launcher::Cascade::make_accessors_with_defaults
    string_before => '-' x 0,
    string_after  => '-' x 0,
    separator     => q{},
    preparator    => sub { "    $_" },
;

=head1 SEE ALSO

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::ListOfStrings::Context

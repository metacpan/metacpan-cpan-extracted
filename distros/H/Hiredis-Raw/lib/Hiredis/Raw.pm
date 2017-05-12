package Hiredis::Raw;
BEGIN {
    $Hiredis::Raw::VERSION = '0.07';
}
use strict;
use warnings;
use XSLoader;
use XS::Object::Magic;

XSLoader::load('Hiredis::Raw', $Hiredis::Raw::VERSION);

require Hiredis::Async;

1;

__END__

=pod

=head1 NAME

Hiredis::Raw - Perl binding for asychronous hiredis API

=head1 DESCRIPTION

For internal use only. See L<Hiredis::Async>.

=head1 AUTHORS

Whitney Jackson C<< <whitney@cpan.org> >>

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011 Whitney Jackson, Jonathan Rockway. All rights reserved
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

=cut

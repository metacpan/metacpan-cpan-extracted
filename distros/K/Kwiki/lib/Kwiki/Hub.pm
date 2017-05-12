package Kwiki::Hub;
use Spoon::Hub -Base;

sub action {
    $self->cgi->action || 'display';
}

__DATA__

=head1 NAME

Kwiki::Hub - Kwiki Hub Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

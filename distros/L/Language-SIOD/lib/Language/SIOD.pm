package Language::SIOD;
$Language::SIOD::VERSION = '0.01';

use strict;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS $Buffer);
use Language::SIOD_in;

BEGIN {
    @EXPORT_OK = @EXPORT;
    @EXPORT = ();
    %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

sub new {
    process_cla(0, [], 0);
    init_storage();
    init_subrs();
    return bless({}, $_[0]);
}

$Buffer = (' ' x 65535);
sub eval {
    my $self = shift;
    local $Buffer = shift;
    repl_c_string($Buffer, 0, 0, 65535);
    return substr($Buffer, 0, index($Buffer, "\0"));
}

=head1 NAME

Language::SIOD - Perl bindings to SIOD

=head1 VERSION

This document describes version 0.01 of Language::SIOD, released
December 26, 2004.

=head1 SYNOPSIS

    use Language::SIOD;
    my $siod = Language::SIOD->new;
    print $siod->eval('(+ 1 1)');   # 2

    # See t/*.t in the source distribution for more!

=head1 DESCRIPTION

This module provides Perl bindings to an embedded SIOD environment.

B<SIOD> (Scheme in One Defun) is a I<small-footprint> implementation of
the Scheme programming language that is provided with some database, Unix
programming and CGI scripting extensions.

The documentation is sorely lacking at this moment.  For an overview of
supported features, please consult F<t/*.t> in the source distribution.

=cut

1;

__END__

=head1 SEE ALSO

L<http://www.cs.indiana.edu/scheme-repository/imp/siod.html>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

package Geoffrey::Role::Changelog;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Role::Changelog::VERSION = '0.000201';

sub new {
    my $class = shift;
    my $self  = {@_};
    $self->{needs_converter} = 0;
    $self->{needs_dbh}       = 0;
    return bless $self, $class;
}

sub tpl_main {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_file( 'tpl_main', $_[0] );
}

sub tpl_sub {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_file( 'tpl_sub', $_[0] );
}

sub load {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_file( 'load', $_[0] );
}

sub write {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_file( 'write', $_[0] );
}

sub ending { return $_[0]->{ending} }

sub needs_converter { return $_[0]->{needs_converter}; }

sub needs_dbh { return $_[0]->{needs_dbh}; }

1;    # End of Geoffrey::Role::Changelog

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Role::Changelog - Abstract file class.

=head1 VERSION

Version 0.000201

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 tpl_main

=head2 tpl_sub

=head2 load

=head2 write

=head2 needs_converter

=head2 needs_dbh

=head2 ending

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geoffrey

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geoffrey

    CPAN Ratings
        http://cpanratings.perl.org/d/Geoffrey

    Search CPAN
        http://search.cpan.org/dist/Geoffrey/

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


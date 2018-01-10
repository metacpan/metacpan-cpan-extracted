package JIP::Conf;

use 5.006;
use strict;
use warnings;
use Hash::AsObject;
use Carp qw(croak);
use English qw(-no_match_vars);

our $VERSION = '0.021';

sub init {
    my ($path_to_file, $path_to_variable) = @ARG;

    # First arg
    croak q{Bad argument "path_to_file"}
        unless defined $path_to_file and length $path_to_file;
    croak(sprintf q{No such file "%s"}, $path_to_file)
        unless -f $path_to_file;

    # Second arg
    croak q{Bad argument "path_to_variable"}
        unless defined $path_to_variable and length $path_to_variable;

    # Require file
    eval { require $path_to_file } or do {
        croak(sprintf q{Can't parse config "%s": %s}, $path_to_file, $EVAL_ERROR);
    };

    # Fetch hash_ref from package
    my $data_from_file;
    eval {
        no strict 'refs';
        $data_from_file = ${ $path_to_variable };
    };
    if ($EVAL_ERROR or ref $data_from_file ne 'HASH') {
        croak(
            sprintf q{Invalid config. Can't fetch ${%s} from "%s"},
                $path_to_variable,
                $path_to_file,
        );
    }

    return Hash::AsObject->new($data_from_file);
}

1;

__END__

=head1 NAME

JIP::Conf - Perl-ish configuration plugin

=head1 VERSION

This document describes C<JIP::Conf> version C<0.021>.

=cut

=head1 SYNOPSIS

    use JIP::Conf;

    my $hash_ref = JIP::Conf::init(
        '/path/to/conf.pm',
        'Namespace::name_of_hashref',
    );

    print qq{cmp_ok\n}
        if $hash_ref->{'parent'}->{'child'} eq $hash_ref->parent->child;

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2018 Vladimir Zhavoronkov.

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
mark, tradename, or logo of the Copyright Holder.

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
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


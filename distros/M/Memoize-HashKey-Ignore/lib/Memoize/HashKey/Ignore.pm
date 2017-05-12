package Memoize::HashKey::Ignore;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Memoize;

=head1 NAME

Memoize::HashKey::Ignore - allow certain keys not to be memoized.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Memoize;

    tie my %scalar_cache = 'Memoize::HashKey::Ignore', IGNORE => sub { my $key = shift, return ($key eq 'BROKENKEY') ? 1 : 0; };
    tie my %list_cache   = 'Memoize::HashKey::Ignore', IGNORE => sub { my $key = shift, return ($key eq 'BROKENKEY') ? 1 : 0; };

    memoize('function', SCALAR_CACHE => [ HASH => \%scalar_cache ], LIST_CACHE => [ HASH => \%list_cache ]);

=head1 EXPORT

Sometimes you don't want to store certain keys. You know what the values looks likes, but you can't easily write memoize function which culls them itself.

Memoize::HashKey::Ignore allows you to supply a code reference which describes, which keys should not be stored in Memoization Cache.

This module will allow you to memoize the entire function with splitting it into cached and uncached pieces.

=cut

sub TIEHASH {
    my ( $package, %args ) = @_;
    my $cache = $args{HASH} || {};

    if ( $args{IGNORE} and not ref $args{IGNORE} eq 'CODE' ) {
        die 'Memoize::HashKey::Ignore: IGNORE argument must be a code ref.';
    }
    if ( $args{TIE} ) {
        my ( $module, @opts ) = @{ $args{TIE} };
        my $modulefile = $module . '.pm';
        $modulefile =~ s{::}{/}g;
        try { require $modulefile }
        catch {
            die 'Memoize::HashKey::Ignore: Could not load hash tie module "'
              . $module . '": '
              . $_;
        };
        my $rc = (
            tie %$cache => $module,
            @opts
        );
        if ( not $rc ) {
            die 'Memoize::HashKey::Ignore Could not tie hash to "'
              . $module . '": '
              . $@;
        }
    }

    $args{CACHE} = $cache;
    return bless \%args => $package;
}

sub EXISTS {
    my ( $self, $key ) = @_;
    return ( exists $self->{CACHE}->{$key} ) ? 1 : 0;
}

sub FETCH {
    my ( $self, $key ) = @_;
    return $self->{CACHE}->{$key};
}

sub CLEAR {
    my ( $self ) = @_;
    $self->{CACHE} = {};
    return $self->{CACHE};
}

sub STORE {
    my ( $self, $key, $value ) = @_;

    if ( not defined $self->{IGNORE} or not &{ $self->{IGNORE} }($key) ) {
        $self->{CACHE}->{$key} = $value;
    }

    return;
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-memoize-hashkey-ignore at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memoize-HashKey-Ignore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memoize::HashKey::Ignore


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memoize-HashKey-Ignore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Memoize-HashKey-Ignore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Memoize-HashKey-Ignore>

=item * Search CPAN

L<http://search.cpan.org/dist/Memoize-HashKey-Ignore/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

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

1;    # End of Memoize::HashKey::Ignore

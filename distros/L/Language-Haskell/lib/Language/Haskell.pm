package Language::Haskell;
$Language::Haskell::VERSION = '0.01';

use strict;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use Language::Haskell_in;
use Language::Haskell::API;

BEGIN {
    @EXPORT_OK = @EXPORT;
    @EXPORT = ();
    %EXPORT_TAGS = ( all => \@EXPORT_OK );

    no strict 'refs';
    foreach my $sym ( @EXPORT_OK ) {
        $sym =~ /^__HugsServerAPI__(.+)/ or next;
        my $code = __PACKAGE__->can($sym) or die $sym;
        *{"Language::Haskell::API::$1"} = (
            ($1 eq 'clearError') ? $code : sub {
                my $rv = $code->(@_);
                die($_[0]->clearError || (return $rv));
            }
        );
    }
}

sub new { initHugsServer(1+@_, [$0, @_]) }

=head1 NAME

Language::Haskell - Perl bindings to Haskell

=head1 VERSION

This document describes version 0.01 of Language::Haskell, released
December 26, 2004.

=head1 SYNOPSIS

    use Language::Haskell;
    my $env = Language::Haskell->new;
    print $env->eval('product [1..10]'); # 3628800

    # See t/*.t in the source distribution for more!

=head1 DESCRIPTION

This module provides Perl bindings to the Haskell language, via the
embedded Haskell User's Gofer System (B<Hugs>).

The documentation is sorely lacking at this moment.  For an overview of
supported features, please consult F<t/*.t> in the source distribution.

=cut


1;

__END__

=head1 SEE ALSO

L<Language::Haskell::API>

L<http://www.haskell.org/hugs/>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

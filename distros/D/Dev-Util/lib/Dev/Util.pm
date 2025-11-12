package Dev::Util;

use lib 'lib';
use 5.018;
use strict;
use warnings;
use version;
use Carp;

our $VERSION = version->declare("v2.17.17");

use Exporter   qw( );
use List::Util qw( uniq );

our @EXPORT      = ();
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );    # Optional.

sub import {
    my $class = shift;
    my (@packages) = @_;

    my ( @pkgs, @rest );
    for (@packages) {
        if (/^::/) {
            push @pkgs, __PACKAGE__ . $_;
        }
        else {
            push @rest, $_;
        }
    }

    for my $pkg (@pkgs) {
        my $mod = ( $pkg =~ s{::}{/}gr ) . ".pm";
        require $mod;

        my $exports = do { no strict "refs"; \@{ $pkg . "::EXPORT_OK" } };
        $pkg->import(@$exports);
        @EXPORT    = uniq @EXPORT,    @$exports;
        @EXPORT_OK = uniq @EXPORT_OK, @$exports;
    }

    @_ = ( $class, @rest );
    goto &Exporter::import;
}

1;    # End of Dev::Util

=pod

=encoding utf-8

=head1 NAME

Dev::Util - Base modules for Perl Development


=head1 VERSION

Version v2.17.17

=head1 SYNOPSIS

Dev::Util provides a loader for sub-modules where a leading :: denotes a package to load.

    use Dev::Util qw( ::OS ::Utils );

This is equivalent to:

    user Dev::Util::OS    qw(:all);
    user Dev::Util::Utils qw(:all);

=head1 SUBROUTINES/METHODS

Modules do specific functions.  Load as necessary.

=cut

# =head2 How it works

# The Dev::Util module simply imports functions from Dev::Util::*
# modules.  Each module defines a self-contained functions, and puts
# those function names into @EXPORT.  Dev::Util defines its own
# import function, but that does not matter to the plug-in modules.

# This function is taken from brian d foy's Test::Data module. Thanks brian!

=head1 SEE ALSO

L<Dev::Util::Backup>,
L<Dev::Util::Const>,
L<Dev::Util::File>,
L<Dev::Util::OS>,
L<Dev::Util::Query>
L<Dev::Util::Syntax>,


=head1 AUTHOR

Matt Martini,  C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


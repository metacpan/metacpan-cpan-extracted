package Dev::Util::Const;

use Dev::Util::Syntax;
use Exporter qw(import);

our $VERSION = version->declare("v2.19.29");

our %EXPORT_TAGS = (
                     named_constants => [ qw(
                                              $EMPTY_STR
                                              $SPACE
                                              $SINGLE_QUOTE
                                              $DOUBLE_QUOTE
                                              $COMMA
                                          )
                                        ]
                   );

# add all the other ":class" tags to the ":all" class, deleting duplicates
{
    my %seen;
    push @{ $EXPORT_TAGS{ all } }, grep { !$seen{ $_ }++ } @{ $EXPORT_TAGS{ $_ } }
        foreach keys %EXPORT_TAGS;
}
Exporter::export_tags('all');
Exporter::export_ok_tags('all');

sub _define_named_constants {
    Readonly our $EMPTY_STR    => q{};
    Readonly our $SPACE        => q{ };
    Readonly our $SINGLE_QUOTE => q{'};
    Readonly our $DOUBLE_QUOTE => q{"};
    Readonly our $COMMA        => q{,};
    return;
}
_define_named_constants();

1;    # End of Dev::Util::Const

=pod

=encoding utf-8

=head1 NAME

Dev::Util::Const - Defines named constants as Readonly.

=head1 VERSION

Version v2.19.29

=head1 SYNOPSIS

Dev::Util::Const - Defines named constants as Readonly, based on best practices.
This idea comes from B<Perl Best Practices> by Damian Conway I<pg. 56>.

    use Dev::Util::Const;
    my $empty_var = $EMPTY_STR;
    my $comma     = $COMMA;

    use Dev::Util::Const qw(:named_constants);
    my $space = $SPACE;
    my $single_quote = $SINGLE_QUOTE;

    use Dev::Util::Const qw($DOUBLE_QUOTE);  # only import a single constant.
    my $double_quote = $DOUBLE_QUOTE;

=head2 Note

The purpose of this module is to define the named constants.  As such the constants
are exported by default.

The second and third examples above work but at the present time are superfluous. They
are retained for future expansion.

=head1 EXPORT_TAGS

=over 4

=item B<:named_constants>

=over 8

=item $EMPTY_STR

=item $SPACE

=item $SINGLE_QUOTE

=item $DOUBLE_QUOTE

=item $COMMA

=back

=back

=head1 CONSTANTS

These constants are defined as readonly:

=over 4

=item C<$EMPTY_STR = q{};>

=item C<$SPACE = q{ };>

=item C<$SINGLE_QUOTE = q{'};>

=item C<$DOUBLE_QUOTE = q{"};>

=item C<$COMMA = q{,};>

=back

=head1 SUBROUTINES

There are no public subroutines.

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Const

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

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

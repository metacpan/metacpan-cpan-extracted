
=head1 NAME

Log::Fine::Levels - Define variable logging levels

=head1 SYNOPSIS

Provides logging translations

    use Log::Fine::Levels;

    # Instantiate the levels object using the default translations
    my $levels = Log::Fine::Levels->new();

    # Instantiate the levels object using customized translations
    my $levels = Log::Fine::Levels->new("Java");

    # Supported methods
    my @l = $levels->logLevels();   # grab list of levels
    my @m = $levels->logMasks();    # grab list of masks

    # Translation methods
    my $val     = $levels->levelToValue("INFO");
    my $bitmask = $levels->maskToValue("LOGMASK_INFO");
    my $lvl     = $levels->valueToLevel(3);

=head1 DESCRIPTION

Log::Fine::Levels is used by the L<Log::Fine> framework to translate
customizable log levels (such as INFO, DEBUG, WARNING, etc) to and
from an associated value as well as convenience methods for
interacting with log levels (such as grabbing a list of levels).

In addition, the L<Log::Fine> framework supports the notion of a
I<mask>, which is used for customizing output.  See
L<Log::Fine::Handle> for more details as to how masks are used.

=head2 Customization

Log::Fine::Levels only provides methods for interacting with log
levels and associated log masks.  In order to define levels and masks,
it I<must> be overridden.  Note that, by default, the
L<Log::Fine::Levels::Syslog> class is used to define log levels.

=head2 Independence

Finally, Log::Fine::Levels is written to be independant of the
L<Log::Fine> framework and, as such, does not inherit any methods from
L<Log::Fine>.  This allows developers to use Log::Fine::Levels by
itself for defining customizable level packages for use in their own
programs.

=cut

use strict;
use warnings;

package Log::Fine::Levels;

use Carp;
use Log::Fine;

our $VERSION = $Log::Fine::VERSION;

# Constants
# --------------------------------------------------------------------

use constant DEFAULT_LEVELMAP => "Syslog";

# --------------------------------------------------------------------

=head1 METHODS

The following methods are provided:

=head2 new

Creates a new Log::Fine::Levels object

=head3 Parameters

=over

=item  * levelmap

The name of the level map to use (e.g., C<Syslog>, C<Java>, etc)

=back

=head3 Returns

an L<Log::Fine::Levels> object

=cut

sub new
{

        my $class = shift;
        my $lvlmap = shift || DEFAULT_LEVELMAP;

        # Construct the string containing name of sub-class
        my $levelClass = join("::", $class, $lvlmap);

        # Validate levelclass and return if successful
        eval "require $levelClass";

        confess "Error : Level Class $levelClass does not exist : $@"
            if $@;

        return $levelClass->new();

}          # new()

=head2 bitmaskAll

Getter for a bitmask representing B<ALL> possible values

=head2 Returns

Bitmask representing all possible mask values

=cut

sub bitmaskAll
{

        my $self = shift;
        my $mask = 0;             # bitmask

        # bitor all the mask values together
        $mask |= $self->MASK_MAP->{$_} foreach (keys %{ $self->MASK_MAP });

        return $mask;

}          # bitmaskAll()

=head2 levelToValue

Level name to numeric value

=head3 Parameters

=over

=item  * level name

The name of the level

=back

=head3 Returns

The numeric value representing the given level name.  Undef if name is
not defined

=cut

sub levelToValue { return $_[0]->LVLTOVAL_MAP->{ $_[1] }; }

=head2 logLevels

Getter for all log levels

=head3 Returns

An array representing all level names, sorted by ascending numeric
value

=cut

sub logLevels
{

        my $self = shift;
        my @lvls;

        # Construct array sorted by level value (ascending) and return
        push @lvls, $self->VALTOLVL_MAP->{$_} foreach (sort { $a <=> $b } (keys %{ $self->VALTOLVL_MAP }));

        return @lvls;

}          # logLevels()

=head2 logMasks

Getter for all log masks

=head3 Returns

An array representing all mask names, sorted by ascending numeric
value

=cut

sub logMasks
{

        my $self = shift;
        my $vtom = {};
        my @masks;

        # Build hash of mask values to mask names
        $vtom->{ $self->MASK_MAP->{$_} } = $_ foreach (keys %{ $self->MASK_MAP });

        # Construct array sorted by mask value (ascending) and return
        push @masks, $vtom->{$_} foreach (sort { $a <=> $b } (keys %{$vtom}));

        return @masks;

}          # logMasks()

=head2 maskToValue

Mask name to numeric value

=head3 Parameters

=over

=item  * mask name

The name of the mask

=back

=head3 Returns

The numeric value representing the given mask name.  Undef if name is
not defined

=cut

sub maskToValue { return $_[0]->MASK_MAP->{ $_[1] }; }

=head2 valueToLevel

Level value to level name

=head3 Parameters

=over

=item  * numeric value

The numeric value representing a level

=back

=head3 Returns

The level name associated with the given numeric value.  Undef if the
value is not defined

=cut

sub valueToLevel { return $_[0]->VALTOLVL_MAP->{ $_[1] }; }

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine::Levels

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<syslog>, L<Log::Fine>, L<Sys::Syslog>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009, 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Levels

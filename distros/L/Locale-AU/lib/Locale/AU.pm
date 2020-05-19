package Locale::AU;

use warnings;
use strict;
use Data::Section::Simple;

=head1 NAME

Locale::AU - abbreviations for territory and state identification in Australia and vice versa

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Locale::AU;

    my $u = Locale::AU->new();

    my $state = $u->{code2state}{$code};
    my $code  = $u->{state2code}{$state};

    my @state = $u->all_state_names;
    my @code  = $u->all_state_codes;


=head1 SUBROUTINES/METHODS

=head2 new

Creates a Locale::AU object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my $self = {};

	my $data = Data::Section::Simple::get_data_section('states');

	my @line = split /\n/, $data;

	for (@line) {
		my($code, $state) = split /:/;
		$self->{code2state}{$code} = $state;
		$self->{state2code}{$state} = $code;
	}

	return bless $self, $class;
}

=head2 all_state_codes

Returns an array (not arrayref) of all state codes in alphabetical form.

=cut

sub all_state_codes {
	my $self = shift;

	return(sort keys %{$self->{code2state}});
}

=head2 all_state_names

Returns an array (not arrayref) of all state names in alphabetical form

=cut

sub all_state_names {
	my $self = shift;

	return(sort keys %{$self->{state2code}});
}

=head2 $self->{code2state}

This is a hashref which has state abbreviations as the key and the long
name as the value.

=head2 $self->{state2code}

This is a hashref which has the long name as the key and the abbreviated
state name as the value.

=head1 SEE ALSO

L<Locale::Country>

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=over 4

=item * The state name is returned in C<uc()> format.

=item * neither hash is strict, though they should be.

=item * Jarvis Bay Territory is not handled

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::AU

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-AU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-AU>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-AU/>

=back

=head1 ACKNOWLEDGEMENTS

Based on L<Locale::US> - Copyright (c) 2002 - C<< $present >> Terrence Brannon.

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Locale::AU
__DATA__
@@ states
ACT:AUSTRALIAN CAPITAL TERRITORY
NSW:NEW SOUTH WALES
NT:NORTHERN TERRITORY
QLD:QUEENSLAND
SA:SOUTH AUSTRALIA
TAS:TASMANIA
VIC:VICTORIA
WA:WESTERN AUSTRALIA
__END__

package Genealogy::Wills;

use warnings;
use strict;
use Carp;
use File::Spec;
use Module::Info;
use Genealogy::Wills::wills;

=head1 NAME

Genealogy::Wills - Lookup in a database of wills

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    # See https://freepages.rootsweb.com/~mrawson/genealogy/wills.html
    use Genealogy::Wills;
    my $wills = Genealogy::Wills->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::Wills object.

Takes two optional arguments:
	directory: that is the directory containing obituaries.sql
	logger: an object to send log messages to

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Using Genealogy::Wills->new(), not Genealogy::Wills::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	if(!defined((my $directory = ($args{'directory'} || $Database::Abstraction::init->{'directory'})))) {
		# If the directory argument isn't given, see if we can find the data
		$directory ||= Module::Info->new_from_loaded(__PACKAGE__)->file();
		$directory =~ s/\.pm$//;
		$args{'directory'} = File::Spec->catfile($directory, 'data');
	}
	if(!-d $args{'directory'}) {
		Carp::carp(__PACKAGE__, ': ', $args{'directory'}, ' is not a directory');
		return;
	}

	# cache_duration can be overriden by the args
	return bless {
		cache_duration => '1 day',	# The database is updated daily
		%args,
	}, $class;
}

=head2 search

    my $wills = Genealogy::Wills->new();

    # Returns an array of hashrefs
    my @smiths = $wills->search(last => 'Smith');	# You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

=cut

sub search {
	my $self = shift;

	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($params{'last'})) {
		Carp::carp("Value for 'last' is mandatory");
		return;
	}

	$self->{'wills'} ||= Genealogy::Wills::wills->new(no_entry => 1, %{$self});

	if(!defined($self->{'wills'})) {
		Carp::croak("Can't open the wills database");
	}

	if(wantarray) {
		my @wills = @{$self->{'wills'}->selectall_hashref(\%params)};
		foreach my $will(@wills) {
			$will->{'url'} = 'https://' . $will->{'url'};
		}
		return @wills;
	}
	my $will = $self->{'wills'}->fetchrow_hashref(\%params);
	$will->{'url'} = 'https://' . $will->{'url'};
	return $will;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SEE ALSO

The Kent Wills Transcript, L<https://freepages.rootsweb.com/~mrawson/genealogy/wills.html>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Wills

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Genealogy-Wills>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-Wills>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::Wills>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

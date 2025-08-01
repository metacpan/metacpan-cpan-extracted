package Genealogy::Wills;

use warnings;
use strict;
use Carp;
use Data::Reuse;
use File::Spec;
use Module::Info;
use Object::Configure 0.10;
use Params::Get;
use Return::Set;
use Scalar::Util;

use Genealogy::Wills::wills;

=head1 NAME

Genealogy::Wills - Lookup in a database of wills

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    # See https://freepages.rootsweb.com/~mrawson/genealogy/wills.html
    use Genealogy::Wills;
    my $wills = Genealogy::Wills->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::Wills object.

Takes three optional arguments,
which can be hash, hash-ref or key-value pairs.

=over 4

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format,
including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

=item * C<directory>

That is the directory containing obituaries.sql.
If not given, the use the module's data directory.

=item * C<logger>

An object to send log messages to

=back

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_);

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			# Using Genealogy::Wills::new(), not Genealogy::Wills->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# clone the given object
		if($params) {
			return bless { %{$class}, %{$params} }, ref($class);
		}
		return bless $class, ref($class);
	}

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	if(!defined((my $directory = ($params->{'directory'} || $Database::Abstraction->{'directory'})))) {
		# If the directory argument isn't given, see if we can find the data
		$directory ||= Module::Info->new_from_loaded(__PACKAGE__)->file();
		$directory =~ s/\.pm$//;
		$params->{'directory'} = File::Spec->catfile($directory, 'data');
	}
	if(!-d $params->{'directory'}) {
		Carp::carp(__PACKAGE__, ': ', $params->{'directory'}, ' is not a directory');
		return;
	}

	# cache_duration can be overriden by the args
	return bless {
		cache_duration => '1 day',	# The database is updated daily
		%{$params}
	}, $class;
}

=head2 search

Last (last name) is a mandatory parameter.

Return a list of hash references in list context,
or a hash reference in scalar context.

Each record includes a formatted C<url> field.

    my $wills = Genealogy::Wills->new();

    # Returns an array of hashrefs
    my @smiths = $wills->search(last => 'Smith');	# You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

=cut

sub search {
	my $self = shift;
	my $params = Params::Get::get_params('last', @_);

	if(!defined($params->{'last'})) {
		Carp::carp("Value for 'last' is mandatory");
		return;
	}

	$self->{'wills'} ||= Genealogy::Wills::wills->new(no_entry => 1, no_fixate => 1, %{$self});

	if(!defined($self->{'wills'})) {
		Carp::croak("Can't open the wills database");
	}

	if(wantarray) {
		my @wills = @{$self->{'wills'}->selectall_hashref($params)};
		foreach my $will(@wills) {
			$will->{'url'} = 'https://' . $will->{'url'};
		}
		return @wills;
	}
	my $will = $self->{'wills'}->fetchrow_hashref($params);
	$will->{'url'} = 'https://' . $will->{'url'};
	Data::Reuse::fixate(%{$will});

	return Return::Set($will, { 'type' => 'hashref', 'min' => 1 });
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

Copyright 2023-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

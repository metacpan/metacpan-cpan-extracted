package Genealogy::Wills;

use warnings;
use strict;
use Carp;
use Data::Reuse;
use File::Spec;
use Genealogy::Wills::wills;
use Module::Info;
use Object::Configure 0.12;
use Params::Get 0.13;
use Params::Validate::Strict 0.09;
use Return::Set;
use Scalar::Util;

=head1 NAME

Genealogy::Wills - Lookup in a database of wills

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

# Class-level constants
use constant {
	DEFAULT_CACHE_DURATION => '1 day',	# The database is updated daily
	MIN_LAST_NAME_LENGTH   => 1,
	MAX_LAST_NAME_LENGTH   => 100,
};

=head1 DESCRIPTION

This module provides a convenient interface to search through a database of historical wills,
primarily focused on the Kent Wills Transcript.
It handles database connections, caching, and result formatting.

- Results are cached for 1 day by default
- Database connections are lazy-loaded
- Large result sets may consume significant memory

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

That is the directory containing wills.sql.
If not given, the use the module's data directory.

=item * C<logger>

An object to send log messages to

=back

=cut

sub new
{
	my $class = shift;
	my $params;

	# Handle hash or hashref arguments
	if((scalar(@_) == 1) && !ref($_[0])) {
		$params->{'directory'} = $_[0];
	} else {
		$params = Params::Get::get_params(undef, \@_);
	}

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

	if(!defined(my $directory = ($params->{'directory'} || $Genealogy::Wills::wills->{'directory'}))) {
		# If the directory argument isn't given, see if we can find the data
		$directory ||= Module::Info->new_from_loaded(__PACKAGE__)->file();
		$directory =~ s/\.pm$//;
		$params->{'directory'} = File::Spec->catfile($directory, 'data');
	}

	unless((-d $params->{'directory'}) && (-r $params->{'directory'})) {
		Carp::carp(__PACKAGE__, ': ', $params->{'directory'}, ' is not a directory');
		return;
	}

	# Validate logger object has required methods
	if(defined $params->{'logger'}) {
		unless(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('info') && $params->{'logger'}->can('error')) {
			Carp::croak("Logger must be an object with info() and error() methods");
		}
	}

	# cache_duration can be overriden by the args
	return bless {
		cache_duration => DEFAULT_CACHE_DURATION,
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

	# Ensure $self is valid
	Carp::croak('search() must be called on an object') unless(Scalar::Util::blessed($self));

        my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('last', @_),
		schema => {
			'last' => {
				type => 'string',
				min => 1,
				max => 100,
				matches => qr/^[\w\-]+$/	# Allow hyphens in surnames
			}, 'first' => {
				type => 'string',
				optional => 1,
				min => 1,
				max => 100
			}, 'middle' => {
				type => 'string',
				optional => 1,
				min => 1,
				max => 100
			}, 'town' => {
				type => 'string',
				optional => 1,
				min => 1,
				max => 100
			}, 'year' => {
				type => 'integer',
				optional => 1,
				min => 1,
				max => 2025
			}
		}
	});

	# Validate required parameters thoroughly
	unless((defined($params->{'last'})) && (length($params->{'last'}) > 0)) {
		Carp::carp("Value for 'last' is mandatory");
		return;
	}

	# Sanitize input to prevent SQL injection
	$params->{'last'} =~ s/[^\w\s\-']//g;	# Allow only word chars, spaces, hyphens, apostrophes

	$self->{'wills'} ||= Genealogy::Wills::wills->new(no_entry => 1, no_fixate => 1, %{$self});

	if(!defined($self->{'wills'})) {
		Carp::croak("Can't open the wills database");
	}

	if(wantarray) {
		if(my $willslist = $self->{'wills'}->selectall_hashref($params)) {
			my @wills = @{$willslist};
			foreach my $will(@wills) {
				$will->{'url'} = 'https://' . $will->{'url'};
			}
			Data::Reuse::fixate(@wills);
			return @wills;
		}
		return;
	}
	if(defined(my $will = $self->{'wills'}->fetchrow_hashref($params))) {
		$will->{'url'} = 'https://' . $will->{'url'};
		Data::Reuse::fixate(%{$will});

		return Return::Set::set_return($will, { 'type' => 'hashref', 'min' => 1 });
	}
}

=encoding utf-8

=head1 FORMAL SPECIFICATION

    [NAME, URL, DIRECTORY]

    WillRecord == [
        first: NAME;
        last: NAME;
        url: URL;
        additional_fields: ℙ(NAME × seq CHAR)
    ]

    WillsDatabase == [
        directory: DIRECTORY;
        cache_duration: ℕ;
        logger: LOGGER
    ]

    SearchParams == [
        last: NAME;
        first: NAME;
        optional_params: ℙ(NAME × seq CHAR)
    ]

    │ last ≠ ∅  -- last name cannot be empty
    │ |last| > 0  -- last name must have positive length

    search: WillsDatabase × SearchParams → ℙ WillRecord

    ∀ db: WillsDatabase; params: SearchParams •
        params.last ≠ ∅ ⇒
        search(db, params) = {r: WillRecord | r.last = params.last ∧ matches(r, params)}

    ∀ db: WillsDatabase; params: SearchParams •
        params.last = ∅ ⇒
        search(db, params) = ∅

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

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

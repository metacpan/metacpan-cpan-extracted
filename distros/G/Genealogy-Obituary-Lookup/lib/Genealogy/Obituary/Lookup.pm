package Genealogy::Obituary::Lookup;

use warnings;
use strict;

use Carp;
use Data::Reuse;
use File::Spec;
use Genealogy::Obituary::Lookup::obituaries;
use Module::Info;
use Object::Configure 0.10;
use Params::Get 0.04;
use Scalar::Util;

use constant URLS => {
	# 'M' => "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=",
	'M' => "https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=",
	'F' => "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-",
};

=head1 NAME

Genealogy::Obituary::Lookup - Lookup an obituary

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

Looks up obituaries

    use Genealogy::Obituary::Lookup;
    my $info = Genealogy::Obituary::Lookup->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::Obituary::Lookup object.

    my $obits = Genealogy::Obituary::Lookup->new();

Accepts the following optional arguments:

=over 4

=item * C<cache> - Passed to L<Database::Abstraction>

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

=item * C<directory>

The directory containing the file obituaries.sql.
If only one argument is given to C<new()>, it is taken to be C<directory>.

=item * C<logger> - Passed to L<Database::Abstraction>

=back

=cut

sub new
{
	my $class = shift;
	my %args;

	# Handle hash or hashref arguments
	if((scalar(@_) == 1) && !ref($_[0])) {
		$args{'directory'} = $_[0];
	} elsif(my $params = Params::Get::get_params(undef, @_)) {
		%args = %{$params};
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Use Genealogy::Obituary::Lookup->new, not Genealogy::Obituary::Lookup::new
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	# Load the configuration from a config file, if provided
	%args = %{Object::Configure::configure($class, \%args)};

	my $directory = $args{'directory'} || $Database::Abstraction{'defaults'}{'directory'};
	if(!defined($directory)) {
		# If the directory argument isn't given, see if we can find the data
		$directory = Module::Info->new_from_loaded($class)->file();
		$directory =~ s/\.pm$//;
		$args{'directory'} = File::Spec->catfile($directory, 'data');
	}

	if(!-d $directory) {
		Carp::carp("$class: $directory is not a directory");
		return;
	}

	# cache_duration can be overridden by the args
	return bless {
		cache_duration => '1 day',	# The database is updated daily
		%args,
	}, $class;
}

=head2 search

Searches the database.

    # Returns an array of hashrefs
    my @smiths = $obits->search(last => 'Smith');	# You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

Supports two return modes:

=over 4

=item * C<List context>

Returns an array of hash references.

=item * C<Scalar context>

Returns a single hash reference,
or C<undef> if there is no match.

=back

=cut

sub search
{
	my $self = shift;
	my $params = Params::Get::get_params('last', @_);

	if(!defined($params->{'last'})) {
		Carp::carp("Value for 'last' is mandatory");
		return;
	}

	$self->{'obituaries'} ||= Genealogy::Obituary::Lookup::obituaries->new(no_entry => 1, no_fixate => 1, %{$self});

	if(!defined($self->{'obituaries'})) {
		Carp::croak("Can't open the obituaries database");
	}

	if(wantarray) {
		my @obituaries = @{$self->{'obituaries'}->selectall_hashref($params)};
		foreach my $obit(@obituaries) {
			$obit->{'url'} = _create_url($obit);
		}
		Data::Reuse::fixate(@obituaries);
		return @obituaries;
	}
	if(defined(my $obit = $self->{'obituaries'}->fetchrow_hashref($params))) {
		$obit->{'url'} = _create_url($obit);
		Data::Reuse::fixate(%{$obit});
		return $obit;
	}
	return;	# undef
}

sub _create_url {
	my $obit = shift;
	my $source = $obit->{'source'};
	my $page = $obit->{'page'};

	if(!defined($page)) {
		# use Data::Dumper;
		# ::diag(Data::Dumper->new([$obit])->Dump());
		Carp::croak(__PACKAGE__, ': undefined $page');
	}
	if(!defined($source)) {
		Carp::croak(__PACKAGE__, ": $page: undefined source");
	}

	if($source eq 'M') {
		return URLS->{'M'} . $page;
	}
	if($source eq 'F') {
		return URLS->{'F'} . $page;
	}
	if($source eq 'L') {
		if($obit->{'newspaper'} =~ /^https?:\/\//) {
			return $obit->{'newspaper'};
		}
		if($obit->{'page'} =~ /^https?:\/\//) {
			return $obit->{'page'};
		}
		Carp::croak(__PACKAGE__, ": undefined newspaper.  Newspaper much be given when source type is 'L'");
	}
	Carp::croak(__PACKAGE__, ": Invalid source, '$source'. Valid sources are 'M', 'F' and 'L'");
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Ancestry has removed the archives.
The first 18 pages are on Wayback machine, but the rest is lost.

=head1 SEE ALSO

L<Database::Abstraction>

=over 4

=item * The Obituary Daily Times

L<https://sites.rootsweb.com/~obituary/>

=item * Archived Rootsweb data

L<https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit>

=item * Funeral Notices

L<https://www.funeral-notices.co.uk>

=item * Recent data

L<https://www.freelists.org/list/obitdailytimes>

=item * Older data

L<https://obituaries.rootsweb.com/obits/searchObits>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Obituary::Lookup

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Genealogy-Obituary-Lookup>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::Obituary::Lookup>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

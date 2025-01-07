package Genealogy::ObituaryDailyTimes;

use warnings;
use strict;
use Carp;
use File::Spec;
use Module::Info;
use Genealogy::ObituaryDailyTimes::obituaries;
use Scalar::Util;

use constant URLS => {
	# 'M' => "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=",
	'M' => "https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=",
	'F' => "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-",
};

=head1 NAME

Genealogy::ObituaryDailyTimes - Lookup an entry in the Obituary Daily Times

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::ObituaryDailyTimes object.

Accepts the following optional arguments:

=over 4

=item * C<directory> - The directory containing the file obituaries.sql

=item * C<logger> - An object to send log messages to

=back

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Use Genealogy::ObituaryDailyTimes->new, not Genealogy::ObituaryDailyTimes::new
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	my $directory = $args{'directory'} || $Database::Abstraction{'defaults'}{'directory'};
	if(!defined($directory)) {
		# If the directory argument isn't given, see if we can find the data
		$directory = Module::Info->new_from_loaded(__PACKAGE__)->file();
		$directory =~ s/\.pm$//;
		$args{'directory'} = File::Spec->catfile($directory, 'data');
	}
	if(!-d $directory) {
		Carp::carp(__PACKAGE__, ": $directory is not a directory");
		return;
	}

	# cache_duration can be overridden by the args
	return bless {
		cache_duration => '1 day',	# The database is updated daily
		%args,
	}, $class;
}

=head2 search

Supports two return modes:

=over 4

=item * C<List context>

Returns an array of hash references.

=item * C<Scalar context>

Returns a single hash reference.

=back

    my $obits = Genealogy::ObituaryDailyTimes->new();

    # Returns an array of hashrefs
    my @smiths = $obits->search(last => 'Smith');	# You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

=cut

sub search
{
	my $self = shift;
	my $params = $self->_get_params('last', @_);

	if(!defined($params->{'last'})) {
		Carp::carp("Value for 'last' is mandatory");
		return;
	}

	$self->{'obituaries'} ||= Genealogy::ObituaryDailyTimes::obituaries->new(no_entry => 1, %{$self});

	if(!defined($self->{'obituaries'})) {
		Carp::croak("Can't open the obituaries database");
	}

	if(wantarray) {
		my @obituaries = @{$self->{'obituaries'}->selectall_hashref($params)};
		foreach my $obit(@obituaries) {
			$obit->{'url'} = _create_url($obit);
		}
		return @obituaries;
	}
	if(defined(my $obit = $self->{'obituaries'}->fetchrow_hashref($params))) {
		$obit->{'url'} = _create_url($obit);
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
		my $newspaper = $obit->{'newspaper'} || Carp::croak(__PACKAGE__, ": undefined newspaper.  Newspaper much be given when source type is 'L'");
		return $newspaper;
	}
	Carp::croak(__PACKAGE__, ": Invalid source, '$source'. Valid sources are 'M', 'F' and 'L'");
}

# Helper routine to parse the arguments given to a function,
# Processes arguments passed to methods and ensures they are in a usable format,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	shift;  # Discard the first argument (typically $self)
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if(ref $_[0] eq 'HASH');

	my %rc;
	my $num_args = scalar @_;

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && (defined $default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif(($num_args == 0) && (defined($default))) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	} elsif($num_args == 0) {
		return;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}

	return \%rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Ancestry has removed the archives.
The first 17 pages are on Wayback machine, but the rest is lost.

=head1 SEE ALSO

The Obituary Daily Times, L<https://sites.rootsweb.com/~obituary/>,
Archived Rootsweb data, L<https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit>,
Recent data L<https://www.freelists.org/list/obitdailytimes>,
Older data L<https://obituaries.rootsweb.com/obits/searchObits>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ObituaryDailyTimes

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Genealogy-ObituaryDailyTimes>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ObituaryDailyTimes>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

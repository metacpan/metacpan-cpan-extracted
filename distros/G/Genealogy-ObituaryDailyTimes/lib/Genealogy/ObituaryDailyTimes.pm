package Genealogy::ObituaryDailyTimes;

use warnings;
use strict;
use Carp;
use File::Spec;
use Module::Info;
use Genealogy::ObituaryDailyTimes::obituaries;

=head1 NAME

Genealogy::ObituaryDailyTimes - Lookup an entry in the Obituary Daily Times

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::ObituaryDailyTimes object.

Takes two optional arguments:
	directory: that is the directory containing obituaries.sql
	logger: an object to send log messages to

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Use Genealogy::ObituaryDailyTimes->new, not Genealogy::ObituaryDailyTimes::new
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
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

	# cache_duration can be overriden by the args
	return bless {
		cache_duration => '1 day',	# The database is updated daily
		%args,
	}, $class;
}

=head2 search

    my $obits = Genealogy::ObituaryDailyTimes->new();

    # Returns an array of hashrefs
    my @smiths = $obits->search(last => 'Smith');	# You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

=cut

sub search {
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
		# return "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";
		return "https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";
	}
	if($source eq 'F') {
		return "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-$page";
	}
	if($source eq 'L') {
		return $obit->{'newspaper'};
	}
	Carp::croak(__PACKAGE__, ": Invalid source, '$source'");
}

# Helper routine to parse the arguments given to a function,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	my $self = shift;
	my $default = shift;

	my %rc;

	if(ref($_[0]) eq 'HASH') {
		%rc = %{$_[0]};
	} elsif(scalar(@_) % 2 == 0) {
		%rc = @_;
	} elsif(scalar(@_) == 1) {
		if(defined($default)) {
			$rc{$default} = shift;
		} else {
			my @c = caller(1);
			my $func = $c[3];	# calling function name
			Carp::croak('Usage: ', __PACKAGE__, "->$func($default => " . '$val)');
		}
	} elsif((scalar(@_) == 0) && defined($default)) {
		my @c = caller(1);
		my $func = $c[3];	# calling function name
		Carp::croak('Usage: ', __PACKAGE__, "->$func($default => " . '$val)');
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

Copyright 2020-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

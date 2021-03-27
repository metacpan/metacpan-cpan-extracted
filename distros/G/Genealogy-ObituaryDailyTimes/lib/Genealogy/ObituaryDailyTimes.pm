package Genealogy::ObituaryDailyTimes;

use warnings;
use strict;
use Carp;
use File::Spec;
use Module::Info;
use Genealogy::ObituaryDailyTimes::DB;
use Genealogy::ObituaryDailyTimes::DB::obituaries;

=head1 NAME

Genealogy::ObituaryDailyTimes - Compare a Gedcom against the Obituary Daily Times

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::ObituaryDailyTimes object.

Takes an optional argument, directory, that is the directory containing obituaries.sql.

=cut

sub new {
	my($proto, %param) = @_;
	my $class = ref($proto) || $proto;

	# Use Genealogy::ObituaryDailyTimes->new, not Genealogy::ObituaryDailyTimes::new
	return unless($class);

	my $directory = $param{'directory'} || Module::Info->new_from_loaded(__PACKAGE__)->file();
	$directory =~ s/\.pm$//;

	Genealogy::ObituaryDailyTimes::DB::init(directory => File::Spec->catfile($directory, 'database'), %param);
	return bless { }, $class;
}

=head2 search

   my $obits = Genealogy::ObituaryDailyTimes->new();

   my @smiths = $obits->search(last => 'Smith');

   print $smiths[0]->{'first'}, "\n";

=cut

sub search {
	my $self = shift;

	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%param = @_;
	}

	return if(scalar keys %param == 0);

	$self->{'obituaries'} //= Genealogy::ObituaryDailyTimes::DB::obituaries->new(no_entry => 1) or Carp::croak "Can't open the obituaries database";

	if(wantarray) {
		my @obituaries = @{$self->{'obituaries'}->selectall_hashref(\%param)};
		return @obituaries;
	}
	return $self->{'obituaries'}->fetchrow_hashref(\%param);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SEE ALSO

The Obituary Daily Times, L<https://sites.rootsweb.com/~obituary/>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ObituaryDailyTimes

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Genealogy-ObituaryDailyTimes>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ObituaryDailyTimes>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Genealogy-ObituaryDailyTimes>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Genealogy-ObituaryDailyTimes>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2021 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

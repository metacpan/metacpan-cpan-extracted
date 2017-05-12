#######################################
#  LendingClub.com API Perl Module    #
#  version 0.3.0                      #
#                                     #
# Author: Michael W. Renz             #
# Created: 17-Oct-2014                #
#######################################

=pod

=head1 NAME

LendingClub::Api - perl module interface to the LendingClub API

=head1 SYNOPSIS

        use LendingClub::API;
        use Data::Dumper;

        # public functions do not require any options
        my $lcapi_object = new LendingClub::API( "this-is-not-a-real-investor-id", "this-is-not-a-real-key" );

        print Dumper( $lcapi_object->available_cash() ) ."\n";
        print Dumper( $lcapi_object->summary() ) ."\n";

        print Dumper( $lcapi_object->notes_owned() ) ."\n";
        print Dumper( $lcapi_object->detailed_notes_owned() ) ."\n";

        print Dumper( $lcapi_object->portfolios_owned() ) ."\n";
        print Dumper( $lcapi_object->listed_loans() ) ."\n";


=head1 DESCRIPTION

Implements the LendingClub API described at https://www.lendingclub.com/developers/lc-api.action as a perl module

=cut

package LendingClub::API;

# standard includes
use strict;
use warnings;
use Exporter;
use Carp;

my $modname="lendingclub-perl-module";
my $modver="0.3.0";

use vars qw($VERSION);
$LendingClub::API::VERSION = '0.3.0';

use JSON;
use Hash::Flatten qw(:all);
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
$ua->agent("${modname}/${modver}");
$ua->timeout(1);
$ua->default_header('Accept' => "application/json");

my %lcapi = ( version => "v1" );

$lcapi{urls}{api_url}              = "https://api.lendingclub.com/api/investor/" .$lcapi{version} ;

# LendingClub API Resource URLs
$lcapi{urls}{api}{accounts_url}        = $lcapi{urls}{api_url}. "/accounts";
$lcapi{urls}{api}{loans_url}           = $lcapi{urls}{api_url}. "/loans";
$lcapi{urls}{api}{loans}{listing}      = $lcapi{urls}{api}{loans_url}. "/listing";

my $o = new Hash::Flatten();

=pod

=over 4

=item my $lcapi_object = new LendingClub::API( "this-is-not-a-real-investor-id", "this-is-not-a-real-key" );

The LendingClub::API module needs the investor id and the LendingClub API key for all functions.

=back

=cut

sub new
{
        my ($class, $investor_id, $api_key) = @_;
        my $self = ( {} );

        # We only expect the following options:
        #  - api_key - LendingClub API Key
        #  - investor_id - LendingClub Investor ID (from Summary page)
        croak("api_key not defined")          if ( !defined( $api_key) );
        croak("investor_id not defined")      if ( !defined( $investor_id) );

        $lcapi{urls}{api}{accounts}{investor_id}    = $lcapi{urls}{api}{accounts_url}. "/" .$investor_id;
        $lcapi{urls}{api}{accounts}{availablecash}  = $lcapi{urls}{api}{accounts}{investor_id}. "/availablecash";
        $lcapi{urls}{api}{accounts}{summary}        = $lcapi{urls}{api}{accounts}{investor_id}. "/summary";
        $lcapi{urls}{api}{accounts}{notes}          = $lcapi{urls}{api}{accounts}{investor_id}. "/notes";
        $lcapi{urls}{api}{accounts}{detailednotes}  = $lcapi{urls}{api}{accounts}{investor_id}. "/detailednotes";
        $lcapi{urls}{api}{accounts}{portfolios}     = $lcapi{urls}{api}{accounts}{investor_id}. "/portfolios";
        $lcapi{urls}{api}{accounts}{orders}         = $lcapi{urls}{api}{accounts}{investor_id}. "/orders";

        $ua->default_header('Authorization' => $api_key );

        return bless($self, $class);
}

=pod

=head2 Account information functions

=over 4

=item my $available_cash = $lcapi_object->available_cash();

Returns the available cash for account.

=item my $summary = $lcapi_object->summary();

Returns the summary for account

=item my $notes = $lcapi_object->notes_owned();

Returns the notes owned by account.

=item my $detailed_notes = $lcapi_object->detailed_notes_owned();

Returns the detailed notes owned by account.

=item my $portfolios = $lcapi_object->portfolios_owned();

Returns the portfolios owned by account.

=back

=head2 Loan information

=over 4

=item my $listed_loans = $lcapi_object->listed_loans();

Returns the loans listed on Lending Club.

=back

=cut

# GET information from LendingClub
sub available_cash
{
        my ($self) = @_;
        return $self->_json_get( $lcapi{urls}{api}{accounts}{availablecash} )->{availableCash};
}

sub summary
{
        my ($self) = @_;
        return $o->unflatten( $self->_json_get( $lcapi{urls}{api}{accounts}{summary} ) );
}

sub notes_owned
{
        my ($self) = @_;
        return $o->unflatten( $self->_json_get( $lcapi{urls}{api}{accounts}{notes} ) );
}

sub detailed_notes_owned
{
        my ($self) = @_;
        return $o->unflatten( $self->_json_get( $lcapi{urls}{api}{accounts}{detailednotes} ) );
}

sub portfolios_owned
{
        my ($self) = @_;
        return $o->unflatten( $self->_json_get( $lcapi{urls}{api}{accounts}{portfolios} ) );
}

sub listed_loans
{
        my ($self,$showAll) = @_;
        return $o->unflatten( $self->_json_get( $lcapi{urls}{api}{loans}{listing} ) );
}



# private module functions
sub _json_get
{
        my ($self, $url) = @_;
        return decode_json $ua->get( $url )->decoded_content();
}

sub _json_post
{
        my ($self, $url) = @_;
        return decode_json $ua->post( $url, $self->{post_message} )->decoded_content();
}

sub TRACE {}

1; # End of LendingClub::API

=pod

=head1 CHANGELOG

=over 4

=item * Documentation for 'new'

=item * Attempts 1/2 to add dependencies

=back

=head1 TODO

=over 4

=item * Add POST operations for the LendingClub API

=item * Add comprehensive unit tests to module distribution

=item * Add client error handling

=item * Fix any bugs that anybody reports

=item * Write better documentation.  Always write better documentation

=back


=head1 SEE ALSO

See https://www.lendingclub.com/developers/lc-api.action for the most updated API docs and more details on each of the functions listed here.


=head1 VERSION

$Id: API.pm,v 0.3.0 2014/06/08 09:08:00 CRYPTOGRA Exp $


=head1 AUTHOR

Michael W. Renz, C<< <cryptographrix+cpan at gmail.com> >>

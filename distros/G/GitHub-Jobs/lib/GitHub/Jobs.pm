package GitHub::Jobs;

use 5.006;
use strict;
use warnings;

=head1 NAME

GitHub::Jobs - This module is a wrapper around the GitHub Jobs API.  

=head1 VERSION

Version 0.05

=cut

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use namespace::clean;

use Carp;
use Data::Dumper;

use JSON;
use Readonly;
use HTTP::Request;
use LWP::UserAgent;

our $VERSION = '0.05';

Readonly my $BASE_URL => "http://jobs.github.com/positions.json";

type 'TrueFalse' => where { /\btrue\b|\bfalse\b/i };
has 'description' => ( is => 'ro', isa => 'Str', required => 1 );
has 'full_time'   => ( is => 'rw', isa => 'TrueFalse' );
has 'location'    => ( is => 'ro', isa => 'Str' );
has 'page'        => ( is => 'ro', isa => 'Str' );
has 'lat'         => ( is => 'ro', isa => 'Str' );
has 'long'        => ( is => 'ro', isa => 'Str' );
has 'browser'     => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub { return LWP::UserAgent->new(); }
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( description => $_[1] );
    }
    else {
        return $class->$orig(@_);
    }
};

=head1 SUBROUTINES/METHODS

=head2 BUILD

Check if description parameter is empty!

=cut

sub BUILD {
    my $self = shift;
    croak("ERROR: description must be specified.\n")
      unless ( $self->description );
}

=head2 search

Generate URL with parameters values and send HTTP Request!

=cut

sub search {
    my $self = shift;
    my ( $browser, $url, $request, $response, $content );
    $browser = $self->browser;
    $url = sprintf( "%s?description=%s", $BASE_URL, $self->description );
    $url .= sprintf( "&full_time=%s", $self->full_time ) if $self->full_time;
    $url .= sprintf( "&location=%s",  $self->location )  if $self->location;
    $url .= sprintf( "&lat=%s",       $self->lat )       if $self->lat;
    $url .= sprintf( "&long=%s",      $self->long )      if $self->long;
    $url .= sprintf( "&page=%s",      $self->page )      if $self->page;
    $request = HTTP::Request->new( GET => $url );
    $response = $browser->request($request);

    croak(
        "ERROR: Couldn't fetch data [$url]:[" . $response->status_line . "]\n" )
      unless $response->is_success;
    $content = $response->content;
    croak("ERROR: No data found.\n") unless defined $content;
    return $content;
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;

=head1 SYNOPSIS

This module is the implementation of a interface to the GitHub Jobs API (as available on https://jobs.github.com/api)

	use strict;
	use warnings;

	use GitHub::Jobs;
	use JSON::XS;
	use POSIX;

	$|++;

	my $query      = 'software';
	my $count      = 0;
	my $pagination = 0;

	sub initial {
    	 my $page = shift;
    	 my $str = GitHub::Jobs->new( description => $query, page => $page );
    	 return JSON::XS::decode_json( $str->search() );
	}

	sub decode {
    	 foreach my $items ( @{ initial($pagination) } ) {
          print $items->{title} . " ---- ";
          print $items->{company} . "\n";
          $count++;
    	}
    	my $page_count = ceil( ( $count / 50 ) );
    	if ( ($page_count) && ( $page_count != $pagination ) ) {
         $pagination = $page_count;
         &decode;
    	}
	}

	decode;

=head1 AUTHOR

Ovidiu Nita Tatar, C<< <ovn.tatar at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-github-jobs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GitHub-Jobs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

or https://github.com/ovntatar/GitHub-Jobs/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GitHub::Jobs
   
    https://github.com/ovntatar/GitHub-Jobs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GitHub-Jobs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GitHub-Jobs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GitHub-Jobs>

=item * Search CPAN

L<http://search.cpan.org/dist/GitHub-Jobs/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ovidiu Nita Tatar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of GitHub::Jobs

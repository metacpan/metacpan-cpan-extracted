package Exercises::API;

# ABSTRACT: API Ninja's Exercises API

use v5.38;
use strict;
use warnings;
use Moose;
use LWP;
use JSON;
use Carp;
use Readonly;

use Exercises::API::Exercise;

our $VERSION = '0.001';

Readonly my $API_BASE_URL => 'https://api.api-ninjas.com/v1/exercises';

has 'ua' => (
    isa        => 'LWP::UserAgent',
    is         => 'ro',
    lazy_build => 1,
);

has 'apikey' => (
    required => 1,
    isa      => 'Maybe[Str]',
    is       => 'ro'
);

sub exercises( $self, %args ) {
    my $path           = $self->_build_path(%args);
    my $exercises_list = $self->_request($path);
    my @exercises;

    for my $exercise (@$exercises_list) {
        push @exercises, Exercises::API::Exercise->new($exercise);
    }

    return @exercises;
}

sub _build_path( $self, %args ) {
    my $uri = URI->new($API_BASE_URL);

    $uri->query( $uri->query_form(%args) ) if %args;

    return $uri;
}

sub _build_ua($self) {

    my $ua = LWP::UserAgent->new;
    $ua->default_header( 'X-Api-Key' => $self->apikey );

    return $ua;
}

sub _request( $self, $uri ) {
    my $response = $self->ua->get($uri);
    if ( $response->is_success ) {
        return decode_json( $response->decoded_content );
    }
    else {
        my $code = $response->code;
        confess "Exercises API status code ($code)\n"
          . "Error: "
          . $response->status_line;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exercises::API - API Ninja's Exercises API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Exercises::API;

    # Set API Ninja Exercise API Key
    my $ea = Exercises::API->new(apikey => $ENV{'AN_EXERCISES_APIKEY'});

    # A list of exercises
    my @exercises = $ea->exercises;

    for my $exercise (@exercises){
        print "Name: " . $exercise->name . "\n";
        print "Type: " . $exercise->type . "\n";
        print "Muscle: " . $exercise->muscle . "\n";
        print "Equipment: " . $exercise->equipment . "\n";
        print "Difficulty: " . $exercise->difficulty . "\n";
        print "Instructions: " . $exercise->instructions . "\n";

    }

    # Specifying the parameters
    my %args = (
        name => 'press',
        type => 'strength',
        muscle => 'chest',
        difficulty => 'beginner',
        # offset => 0 (is a premium feature/parameter)
    );

    # A list of exercises based on the specified parameters
    my @exercisesParams = $ea->exercises(%args);

    for my $exercise (@exercises){
        print "Name: " . $exercise->name . "\n";
        print "Type: " . $exercise->type . "\n";
        print "Muscle: " . $exercise->muscle . "\n";
        print "Equipment: " . $exercise->equipment . "\n";
        print "Difficulty: " . $exercise->difficulty . "\n";
        print "Instructions: " . $exercise->instructions . "\n";
    }

=head1 DESCRIPTION

The L<Exercises API|https://www.api-ninjas.com/api/exercises> provides access to a comprehensive list of thousands of exercises targeting every major muscle group.

Returns up to 5 exercises that satisfy the given parameters.

=head1 API Key (required)

You can get an API Key at L<API Ninjas|https://www.api-ninjas.com>.

=head1 Parameters

=head2 name  (optional)

Name of exercise. This value can be partial (e.g. press will match Dumbbell Bench Press).

=head2 type  (optional)

Exercise type. Possible values are:

    cardio
    olympic_weightlifting
    plyometrics
    powerlifting
    strength
    stretching
    strongman

=head2 muscle  (optional)

Muscle group targeted by the exercise. Possible values are:

    abdominals
    abductors
    adductors
    biceps
    calves
    chest
    forearms
    glutes
    hamstrings
    lats
    lower_back
    middle_back
    neck
    quadriceps
    traps
    triceps

=head2 difficulty  (optional)

Difficulty level of the exercise. Possible values are:

    beginner
    intermediate
    expert

=head2 offset  (optional) - premium

Number of results to offset for pagination. Default is 0.

=head1 Installation

=head2 cpanm

    cpanm Exercises::API

=head2 Project Directory

    cpanm --installdeps .
    perl Makefile.PL
    make
    make install

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Rayhan Alcena.

This is free software, licensed under:

  The MIT (X11) License

=cut

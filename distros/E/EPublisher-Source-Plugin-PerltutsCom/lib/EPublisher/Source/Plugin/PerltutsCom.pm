package EPublisher::Source::Plugin::PerltutsCom;


# ABSTRACT: Get POD from tutorials published on perltuts.com

use strict;
use warnings;

use Moo;
use Encode;
use File::Basename;
use HTTP::Tiny;

use parent qw( EPublisher::Source::Base );

has ua => ( is => 'ro', default => sub { HTTP::Tiny->new } );

our $VERSION = '0.6';

# implementing the interface to EPublisher::Source::Base
sub load_source{
    my ($self) = @_;

    $self->publisher->debug( '100: start ' . __PACKAGE__ );

    my $options = $self->_config;
    
    my $name = $options->{name};
    return if !$name;

    # fetching the requested tutorial from metacpan
    $self->publisher->debug( "103: fetch tutorial $name" );

    return $self->_get_pod( $name );
}

sub _get_pod {
    my ($self,$name) = @_;

    my $response = $self->ua->get(
        'http://perltuts.com/tutorials/' . $name . '?format=pod'
    );

    if ( $response !~ m{\A2} ) {
        $self->publisher->debug(
            "103: tutorial $name does not exist"
        );

        return;
    };

    my $pod = $response->{content};

    # perltuts.com always provides utf-8 encoded data, so we have
    # to decode it otherwise the target plugins may produce garbage
    eval{ $pod = decode( 'utf-8', $pod ); };

    my $title    = $name;
    my $info = { pod => $pod, filename => $name, title => $title };
    my @pod = $info;

    # make some nice debug output for what is in $info
    my $pod_short;
    if ($pod =~ m/(.{50})/s) {
        $pod_short = $1 . '[...]';
    }
    else {
        $pod_short = $pod;
    }

    $self->publisher->debug(
        "103: passed info: "
        . "filename => $name, "
        . "title => $title, "
        . 'pod => ' . substr($pod, 0, 30) . '<<<<CUT<<<<'
    );

    return @pod;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

EPublisher::Source::Plugin::PerltutsCom - Get POD from tutorials published on perltuts.com

=head1 VERSION

version 0.6

=head1 SYNOPSIS

  my $source_options = { type => 'PerltutsCom', name => 'Moose' };
  my $url_source     = EPublisher::Source->new( $source_options );
  my $pod            = $url_source->load_source;

=head1 ATTRIBUTES

=over 4

=item ua

=back

=head1 METHODS

=head2 load_source

  $url_source->load_source;

reads the URL 

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Renee Bäcker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

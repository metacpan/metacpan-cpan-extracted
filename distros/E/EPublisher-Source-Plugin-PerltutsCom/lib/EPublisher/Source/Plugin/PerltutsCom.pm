package EPublisher::Source::Plugin::PerltutsCom;


# ABSTRACT: Get POD from tutorials published on perltuts.com

use strict;
use warnings;

use Data::Dumper;
use Encode;
use File::Basename;
use LWP::Simple;

use EPublisher::Source::Base;

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.4;

# implementing the interface to EPublisher::Source::Base
sub load_source{
    my ($self) = @_;

    $self->publisher->debug( '100: start ' . __PACKAGE__ );

    my $options = $self->_config;
    
    return '' unless $options->{name};

    my $name = $options->{name};

    # fetching the requested tutorial from metacpan
    $self->publisher->debug( "103: fetch tutorial $name" );

    my $pod = LWP::Simple::get(
        'http://perltuts.com/tutorials/' . $name . '?format=pod'
    );

    my $regex = qr/<div \s+ id="content" \s+ class="row"> .*? not \s+ found/;

    if ( !$pod || $pod =~ $regex ) { 
        $self->publisher->debug(
            "103: tutorial $name does not exist"
        );
        return;
    };

    # perltuts.com always provides utf-8 encoded data, so we have
    # to decode it otherwise the target plugins may produce garbage
    eval{ $pod = decode( 'utf-8', $pod ); };

    # remove =encoding line. We try to decode ourselves, and
    # Pod::Simple tries to decode, too, when it finds a =encoding line
    $pod =~ s{^=encoding.*?$}{}mg;

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

=head1 NAME

EPublisher::Source::Plugin::PerltutsCom - Get POD from tutorials published on perltuts.com

=head1 VERSION

version 0.4

=head1 SYNOPSIS

  my $source_options = { type => 'PerltutsCom', name => 'Moose' };
  my $url_source     = EPublisher::Source->new( $source_options );
  my $pod            = $url_source->load_source;

=encoding utf-8

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


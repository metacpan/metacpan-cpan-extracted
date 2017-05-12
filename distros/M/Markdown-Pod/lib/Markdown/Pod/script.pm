package Markdown::Pod::script;
# ABSTRACT: script to convert Markdown to POD

use strict;
use warnings;

our $VERSION = '0.006';

use Encode qw( encodings decode );
use Getopt::Long;
use List::Util qw( first );
use Markdown::Pod;

sub new {
    my $class = shift;

    bless {
        encoding => 'utf8',
        dialect  => 'Standard',
        verbose  => undef,
        argv     => [],
        @_,
    }, $class;
}

sub doit {
    my $self = shift;

    if ( my $action = $self->{action} ) {
        $self->$action() and return 1;
    }

    $self->show_help(1)
        unless @{ $self->{argv} } || $self->{load_from_stdin};

    if ( $self->{encoding} ) {
        my $found = first { $_ eq $self->{encoding} } Encode->encodings;
        if ( !$found ) {
            warn "cannot find such '$self->{encoding}' encoding\n";
            $self->show_help(1);
        }
    }

    my $m2p = Markdown::Pod->new;

    if ( $self->{load_from_stdin} ) {
        my $markdown = do { local $/; <STDIN>; };

        my $pod = $m2p->markdown_to_pod(
            encoding => $self->{encoding},
            dialect  => $self->{dialect},
            markdown => $markdown,
        );
        print $self->{encoding} ? decode( $self->{encoding}, $pod ) : $pod;
    }

    for my $file ( @{ $self->{argv} } ) {
        open my $fh, $file
            or warn("cannot open $file: $!\n"), next;
        my $markdown = do { local $/; <$fh>; };
        close $fh;

        my $pod = $m2p->markdown_to_pod(
            encoding => $self->{encoding},
            dialect  => $self->{dialect},
            markdown => $markdown,
        );
        print $self->{encoding} ? decode( $self->{encoding}, $pod ) : $pod;
    }

    return 1;
}

sub env {
    my ( $self, $key ) = @_;
    return $ENV{ "PERL_MARKDOWN2POD_" . $key } || q{};
}

sub parse_options {
    my $self = shift;

    local @ARGV = @{ $self->{argv} };
    push @ARGV, split /\s+/, $self->env('OPT');
    push @ARGV, @_;

    Getopt::Long::Configure("bundling");
    Getopt::Long::GetOptions(
        'e|encoding=s' => sub { $self->{encoding} = $_[1] },
        'd|dialect=s'  => sub { $self->{dialect}  = $_[1] },
        'v|verbose'    => sub { $self->{verbose}  = 1 },
        'h|help'       => sub { $self->{action}   = 'show_help' },
        'V|version'    => sub { $self->{action}   = 'show_version' },
    );

    if ( @ARGV == 0 || !-t STDIN ) {
        $self->{load_from_stdin} = 1;
    }

    $self->{argv} = \@ARGV;
}

sub show_help {
    my $self = shift;

    if ( $_[0] ) {
        die <<'USAGE';
Usage: markdown2pod [OPTIONS] <file1> [ <file2> ... ]

Try `markdown2pod --help` for details.
USAGE
    }

    print <<"HELP";
Usage: markdown2pod [OPTIONS] <file1> [ <file2> ... ]

OPTIONS:
    -e,--encoding       set markdown encoding
    -d,--dialect        set markdown dialect (Standard, Github, Theory)
    -v,--verbose        print more information
    -h,--help           print this message
    -V,--version        display software version

HELP

    return 1;
}

sub show_version {
    print "markdown2pod (Markdown::Pod) version $Markdown::Pod::VERSION\n";
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdown::Pod::script - script to convert Markdown to POD

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $app = Markdown::Pod::script->new;
    $app->parse_options(@ARGV);
    $app->doit or exit(1);

=head1 DESCRIPTION

This module contains script related functions.

=head1 METHODS

=head2 new

=head2 doit

=head2 env

=head2 parse_options

=head2 show_help

=head2 show_version

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

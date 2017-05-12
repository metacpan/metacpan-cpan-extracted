package HTTP::Proxy::GreaseMonkey::Script;

use strict;
use warnings;
use Carp;
use HTML::Tiny;

=head1 NAME

HTTP::Proxy::GreaseMonkey::Script - A GreaseMonkey script.

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey::Script version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use HTTP::Proxy::GreaseMonkey::Script;
  
=head1 DESCRIPTION

Represents a single GreaseMonkey user script.

=head1 INTERFACE 

=head2 C<< new >>

=cut

sub new {
    my ( $class, $script_file ) = @_;

    my @stat = stat $script_file
      or croak "Can't stat $script_file ($!)";

    open my $sh, '<', $script_file
      or croak "Can't read $script_file ($!)";
    my $script = do { local $/; <$sh> };
    close $sh;

    my %meta = ();
    if (
        $script =~ m{^ \s* // \s+ ==UserScript== \s+ 
                      (.*?) ^ \s* // \s+==/UserScript== \s+ }xmsi
      ) {
        my $header = $1;
        while ( $header =~ m{ ^ \s* // \s+ \@(\w+)\s+(.+)$ }xmg ) {
            if ( $1 eq 'include' || $1 eq 'exclude' ) {
                push @{ $meta{$1} }, _gm_wildcard( $2 );
            }
            else {
                $meta{$1} = $2;
            }
        }
    }

    # Special case - if include is empty make it match anything
    $meta{include} = [qr{}] unless $meta{include};

    return bless {
        file   => $script_file,
        meta   => \%meta,
        stat   => \@stat,
        script => $script,
      },
      $class;
}

=head2 C<< match_uri >>

=cut

sub match_uri {
    my ( $self, $uri ) = @_;
    for my $exc ( @{ $self->{meta}->{exclude} || [] } ) {
        return if $uri =~ $exc;
    }
    for my $inc ( @{ $self->{meta}->{include} || [] } ) {
        return 1 if $uri =~ $inc;
    }
    return;
}

=head2 C<< script >>

The Javascript source of this script.

=cut

sub script { shift->{script} }

=head2 C<< support >>

The Javascript support code for this script

=cut

sub support {
    my $self = shift;
    my $h = $self->{_html} ||= HTML::Tiny->new;
    my @args
      = map { $h->json_encode( $_ ) } ( $self->namespace, $self->name );

    return join "\n", map {
            "function GM_$_() { return GM__proxyFunction("
          . join( ', ', $h->json_encode( $_ ), @args )
          . ", arguments) }"
    } qw( setValue getValue log );
}

=head2 C<< file >>

The filename of this script.

=cut

sub file { shift->{file} }

=head2 C<< stat >>

Get the cached C<stat> array for this script.

=cut

sub stat { @{ shift->{stat} } }

=head2 C<< name >>

The descriptive name of this script

=cut

sub name { shift->{meta}->{name} }

=head2 C<< namespace >>

The namespace of this script.

=cut

sub namespace { shift->{meta}->{namespace} }

=head2 C<< description >>

The description of this script.

=cut

sub description { shift->{meta}->{description} }

sub _gm_wildcard {
    my $wc      = shift;
    my $pattern = join '',
      map { $_ eq '*' ? '.*' : $_ eq '?' ? '.' : quotemeta( $_ ) }
      split /([*?])/, $wc;
    return qr{^$pattern$}i;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey::Script requires no configuration files or
environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-proxy-greasemonkey@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

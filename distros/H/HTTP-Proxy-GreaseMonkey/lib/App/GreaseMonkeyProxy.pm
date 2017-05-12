package App::GreaseMonkeyProxy;

use strict;
use warnings;
use Carp;
use Getopt::Long;
use HTTP::Proxy;
use HTTP::Proxy::GreaseMonkey;
use HTTP::Proxy::GreaseMonkey::ScriptHome;
use HTTP::Proxy::GreaseMonkey::Redirector;
use File::Spec;
use Pod::Usage;

=head1 NAME

App::GreaseMonkeyProxy - Command line GreaseMonkey proxy

=head1 VERSION

This document describes App::GreaseMonkeyProxy version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use App::GreaseMonkeyProxy;

    my $app = App::GreaseMonkeyProxy->new;
    $app->parse_args(@ARGV);
    $app->run;

=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< new >>

=cut

{
    my %ARG_SPEC;

    BEGIN {

        sub _array_spec {
            return [
                [],
                sub {
                    my $self = shift;
                    return [ map { 'ARRAY' eq ref $_ ? @$_ : $_ } @_ ];
                },
            ];
        }

        %ARG_SPEC = (
            show_man  => [0],
            show_help => [0],
            args      => _array_spec(),
            servers   => [5],
            port      => [8030],
            verbose   => [0],
        );

        while ( my ( $name, $spec ) = each %ARG_SPEC ) {
            no strict 'refs';
            my $validator = $spec->[1] || sub { shift; shift };
            *{ __PACKAGE__ . '::' . $name } = sub {
                my $self = shift;
                $self->{$name} = $self->$validator( @_ )
                  if ( @_ );
                my $value = $self->{$name};
                return ( wantarray && 'ARRAY' eq ref $value )
                  ? @$value
                  : $value;
            };
        }
    }

    sub new {
        my ( $class, %args ) = @_;

        my $self = bless {}, $class;

        while ( my ( $name, $spec ) = each %ARG_SPEC ) {
            my $value
              = exists $args{$name} ? delete $args{$name} : $spec->[0];
            $self->$name( $value )
              if defined $value;
        }

        croak "Unknown options: ", join( ', ', sort keys %args )
          if keys %args;

        return $self;
    }
}

=head2 C<< args >>

=head2 C<< servers >>

Accessor for the number of servers to start. Defaults to 5.

=head2 C<< port >>

Accessor for the port to listen on. Defaults to 8030.

=head2 C<< verbose >>

Accessor for verbosity. Defaults to 0.

=head2 C<< show_help >>

=head2 C<< show_man >>

=head2 C<< parse_args >>

Parse an argument array - typically C<@ARGV>.

    $app->parse_args( @ARGV );

=cut

sub parse_args {
    my ( $self, @args ) = @_;

    local @ARGV = @args;

    my %options;

    GetOptions(
        'help|?'    => \$options{show_help},
        man         => \$options{show_man},
        'port=i'    => \$options{port},
        'servers=i' => \$options{servers},
        'v|verbose' => \$options{verbose},
    ) or pod2usage();

    while ( my ( $name, $value ) = each %options ) {
        $self->$name( $value ) if defined $value;
    }

    $self->args( @ARGV );
}

=head2 C<< run >>

=cut

sub run {
    my $self = shift;

    if ( $self->show_help ) {
        $self->do_help;
    }
    elsif ( $self->show_man ) {
        pod2usage( -verbose => 2, -exitstatus => 0 );
    }
    else {
        my @args = $self->args;
        pod2usage() unless @args;

        my $proxy = HTTP::Proxy->new(
            port          => $self->port,
            start_servers => $self->servers
        );
        my $gm = HTTP::Proxy::GreaseMonkey::ScriptHome->new;
        $gm->verbose( $self->verbose );
        my @dirs = map glob, @args;
        $gm->add_dir( @dirs );
        $proxy->push_filter(
            mime     => 'text/html',
            response => $gm
        );
        # Make the redirector
        my $redir = HTTP::Proxy::GreaseMonkey::Redirector->new;
        $redir->passthru( $gm->get_passthru_key );
        $redir->state_file(
            File::Spec->catfile( $dirs[0], 'state.yml' ) )
          if @dirs;
        $proxy->push_filter( request => $redir, );
        $proxy->start;
    }
}

=head2 C<do_help>

Output help page

=cut

sub do_help {
    my $self = shift;
    pod2usage( -verbose => 1 );
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
App::GreaseMonkeyProxy requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<HTTP::Proxy::GreaseMonkey::ScriptHome>
L<HTTP::Proxy>

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

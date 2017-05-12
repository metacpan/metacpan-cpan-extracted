package Grimlock::Web::View::HTML;
{
  $Grimlock::Web::View::HTML::VERSION = '0.11';
}

use strict;
use base 'Catalyst::View::TT';
use Grimlock::Web;
use Data::Dumper;
use File::ShareDir 'dist_dir';
__PACKAGE__->config({
    PRE_PROCESS        => 'shared/base.tt',
    WRAPPER            => 'wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
      dist_dir('Grimlock'),
      Grimlock::Web->path_to('root','site')
    ],
    TIMER              => 0,
    static_root        => '/static',
    static_build       => 0,
    render_die => 1
});

sub template_vars {
    my $self = shift;
    return (
        $self->next::method(@_),
        static_root  => $self->{static_root},
        static_build => $self->{static_build}
    );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $formats = $class->config->{formats};

    return $class->next::method( $c, $arguments ) unless ref $formats eq 'HASH';

    $class->config->{FILTERS} ||= {};

    my $filters = $class->config->{FILTERS};

    foreach my $key ( keys %$formats ) {
        if ( $key eq 'date' ) {
            foreach my $date_key ( keys %{$formats->{$key}} ) {
                $filters->{"${key}_$date_key"} = sub {
                    my $date = shift;
                    return unless defined $date;
                    unless ( blessed $date and $date->can("stringify") ) {
                        $date = DateTime::Format::DateParse->parse_datetime($date);
                    }
                    unless ( $date ) { return $date; }
                    $date->set_locale($class->config->{default_locale})
                        if defined $class->config->{default_locale};
                    # Only apply a timezone if we have a complete date.
                    unless ( "$date" =~ /T00:00:00$/ ) {
                        $date->set_time_zone( $class->config->{default_tz} || 'America/Los_Angeles' );
                    }
                    $date->strftime($formats->{$key}->{$date_key});
                };
            }
        }
    }

    return $class->next::method( $c, $arguments );
}

sub process {
    my ( $self, $c, $stash_key ) = @_;
    my $output;
    eval {
        $output = $self->serialize( $c, $c->stash->{$stash_key} );
    };
    return $@ if $@;
 
    $c->response->body( $output );
    return 1;  # important
}

sub serialize {
    my ( $self, $c, $data ) = @_;
    my $template = $c->stash->{'template'} || $c->action . ".tt";
    my $view = $c->view('HTML');
    my $serialized = $view->render($c, $template, $data) || die $view->tt_error;
 
    return $serialized;
}


=head1 NAME

Grimlock::Web::View::HTML - Catalyst TT::Bootstrap::YUI View

=head1 SYNOPSIS

See L<Grimlock::Web>

=head1 DESCRIPTION

Catalyst TT::Bootstrap View.

=head1 AUTHOR

Devin Austin

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

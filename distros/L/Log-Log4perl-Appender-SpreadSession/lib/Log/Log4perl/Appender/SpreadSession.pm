package Log::Log4perl::Appender::SpreadSession;
##################################################

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.03';

our @ISA = qw/ Log::Log4perl::Appender /;

use Spread::Session;

##################################################
sub new {
##################################################
    my($class, %args) = @_;

    my $self = { 
        group => $args{group},
    };

    # Create a new session
    eval {
        $self->{spread_session} = Spread::Session->new(
            spread_name  => $args{spread_name} ,
            private_name => $args{private_name},
        );
    };
    if ($@) {
        warn "ERROR creating new $class: $@\n";
    }

    bless $self, $class;

    return $self;
}

##################################################
sub log {
##################################################
    my ($self, %args) = @_;

    my $spread = $self->{spread_session};

    # do nothing if the Spread::Session object is missing
    return unless $spread;

    # publish the message to the specified group
    eval {
        $spread->publish( $self->{group}, $args{message} );
    };
    # If you got an error warn about it and clear the 
    # Spread::Session object so we don't keep trying
    if ($@) {
        warn "ERROR logging to spread via ".ref($self).": $@\n";
        $self->{spread_session} = undef;
    }

    return;
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::SpreadSession - Log to Spread

=head1 SYNOPSIS

    use Log::Log4perl;

    Log::Log4perl::init({
        'log4perl.logger' => 'DEBUG, Spread',

        'log4perl.appender.Spread'              => 'Log::Log4perl::Appender::SpreadSession',
        'log4perl.appender.Spread.group'        => 'group1'                                ,
        'log4perl.appender.Spread.spread_name'  => '4803@localhost'                        ,
        'log4perl.appender.Spread.private_name' => 'uniquelogger'                          ,
        'log4perl.appender.Spread.layout'       => 'Log::Log4perl::Layout::PatternLayout'  ,
    });

    my $log = Log::Log4perl->get_logger();

    $log->warn('this is my message');

=head1 DESCRIPTION

This is am appender for publishing log messages to a spread group using L<Spread::Session>.

=head2 OPTIONS

=over 4

=item group

Name of the group to publish to.

=item spread_name

A string which identifies the spread host and port in the format C<E<lt>portE<gt>@E<lt>hostE<gt>>. Passed to C<Spread::Session::new>.

=item private_name

Optional. A unique name passed to the C<Spread::Session::new>.

=back

=head1 AUTHOR

Trevor J. Little, E<lt>bundacia@tjlittle.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Trevor J. Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package ETLp::Test::Log::Log4perl::Appender::Null;
use strict;
use warnings;
our @ISA = qw(Log::Log4perl::Appender);

=head1 NAME

ETLp::Test::Log::Log4perl::Appender::Null - A No Op Log4perl Appender

This module allows us to create a default no op logger, so we can
sprinle log requests: throughout our code without raising an error

=head1 METHODS

=head2 new

Called by the Log4perl framework

=cut

sub new {
    my($proto, %p) = @_;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;
    return $self;
}

=head2 log

Called by the Log4perl framework

=cut

sub log{1}
1; #ETLp::Test::Log::Log4perl::Appender::Null


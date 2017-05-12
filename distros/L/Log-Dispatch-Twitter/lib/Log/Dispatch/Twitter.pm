package Log::Dispatch::Twitter;
use strict;
use warnings;
use 5.008001;
use base 'Log::Dispatch::Output';

our $VERSION = 0.03;

use Net::Twitter;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->_basic_init(@_);
    $self->_init(@_);

    return $self;
}

sub _init {
    my $self = shift;
    my %args = @_;

    # Remove Log::Dispatch::Output constructor args
    delete @args{qw{
        name
        min_level
        max_level
        callbacks
        newline
    }};

    $self->{args} = \%args;
}

sub log_message {
    my $self = shift;
    my %args = @_;

    my $message = $args{message};

    # we could truncate here, but better to let Net::Twitter, or even Twitter
    # itself, do it. we don't want to have to release a new version to support
    # 145 character log messages. :)

    $self->_post_message($message);
}

sub _post_message {
    my $self    = shift;
    my $message = shift;

    my $twitter = Net::Twitter->new(%{ $self->{args} });

    $twitter->update($message);
}

1;

__END__

=head1 NAME

Log::Dispatch::Twitter - Log messages via Twitter

=head1 SYNOPSIS

    use Log::Dispatch;
    use Log::Dispatch::Twitter;

    my $logger = Log::Dispatch->new;

    $logger->add(Log::Dispatch::Twitter->new(

        username  => "foo",
        password  => "bar",

        # Net::Twitter args
        traits              => [qw/OAuth API::REST/],
        consumer_key        => $consumer_key,
        consumer_secret     => $consumer_secret,
        access_token        => $token,
        access_token_secret => $token_secret,
    ));

    $logger->log(
        level   => 'error',
        message => 'We applied the cortical electrodes but were unable to get a neural reaction from either patient.',
    );

=head1 DESCRIPTION

Twitter is a presence tracking site. Why not track your program's presence?

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


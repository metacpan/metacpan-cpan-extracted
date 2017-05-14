package Log::Dispatch::MongoDB;

use strict;
use warnings;

use Carp         qw[ confess ];
use Scalar::Util qw[ blessed ];

use Log::Dispatch::Output;

use base qw[ Log::Dispatch::Output ];

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    $self->_basic_init(%p);
    $self->_local_init(%p);

    return $self;
}

sub _local_init {
    my ($self, %params) = @_;
    (exists $params{collection} && blessed $params{collection} && $params{collection}->isa('MongoDB::Collection'))
        || confess "You must supply a MongoDB::Collection object in the collection slot";

    $self->{_collection} = $params{collection};
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    $self->{_collection}->insert( \%p );
}

1;

# ABSTRACT: A MongoDB backend for Log::Dispatch


__END__
=pod

=head1 NAME

Log::Dispatch::MongoDB - A MongoDB backend for Log::Dispatch

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $log = Log::Dispatch->new;
  $log->add(
      Log::Dispatch::MongoDB->new(
          name       => 'my_web_logger',
          min_level  => 'debug',
          collection => $mongo_db->get_collection('web_log')
      )
  );

  $log->debug("Testing feature $x");

  $log->log(
      level   => 'info',
      message => 'Started processing web page',
      info    => {
          referer     => $ENV{HTTP_REFERER},
          user_agent  => $ENV{HTTP_USER_AGENT},
          remote_addr => $ENV{REMOTE_ADDR},
      }
  );

=head1 DESCRIPTION

This is a L<MongoDB> backend for L<Log::Dispatch>.

L<MongoDB> is especially adept for logging because of it's asynchronous
insert behavior, which means that your logging won't slow down your
application. It is also nice in that you can store structured data
as well as simple messages.

=head1 METHODS

=head2 log

With the C<log> method, we not only store the level and message, but we
store any other information you choose to passed in. Note that this feature
does not work if you use the C<info>, C<warn>, C<debug> methods, etc.

=head1 SEE ALSO

L<http://blog.mongodb.org/post/172254834/mongodb-is-fantastic-for-logging>

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


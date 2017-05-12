package Harbinger::Client;
$Harbinger::Client::VERSION = '0.001002';
# ABSTRACT: Impend all the doom you could ever want ⚔

use v5.16.1;
use utf8;
use Moo;
use warnings NONFATAL => 'all';
use Try::Tiny;

use Harbinger::Client::Doom;
use IO::Socket::INET;

has _harbinger_ip => (
   is => 'ro',
   default => '127.0.0.1',
   init_arg => 'harbinger_ip',
);

has _harbinger_port => (
   is => 'ro',
   default => '8001',
   init_arg => 'harbinger_port',
);

has _udp_handle => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      IO::Socket::INET->new(
         PeerAddr => $_[0]->_harbinger_ip,
         PeerPort => $_[0]->_harbinger_port,
         Proto => 'udp'
      ) or $ENV{HARBINGER_WARNINGS} && warn "couldn't connect to socket: $@"
   },
);

has _default_args => (
   is => 'ro',
   default => sub { [] },
   init_arg => 'default_args',
);

sub start {
   my $self = shift;

   Harbinger::Client::Doom->start(
      @{$self->_default_args},
      @_,
   )
}

sub instant {
   my $self = shift;

   $self->send(
      Harbinger::Client::Doom->new(
         @{$self->_default_args},
         @_,
      )
   )
}

sub send {
   my ($self, $doom) = @_;

   return unless
      my $msg = $doom->_as_sereal;

   no warnings;
   &try(sub{
      send($self->_udp_handle, $msg, 0) == length($msg)
         or $ENV{HARBINGER_WARNINGS} && warn "cannot send to: $!";
   },($ENV{HARBINGER_WARNINGS}?(catch {
      warn $_;
   }):()));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Harbinger::Client - Impend all the doom you could ever want â

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

 my $client = Harbinger::Client->new(
   harbinger_ip => '10.6.1.6',
   harbinger_port => 8090,
   default_args => [
     server => 'foo.lan.bar.com',
     port   => 1890,
   ],
 );

 my $doom = $client->start(
    ident => 'process-images',
 );

 for (@images) {
    ...
    $doom->bode_ill;
 }

 $client->send($doom->finish);

=head1 DESCRIPTION

After reading
L<The Mature Optimization Handbook|http://carlos.bueno.org/optimization/mature-optimization.pdf>,
in a fever dream of hubris, I wrote C<Harbinger::Client> and
L<Harbinger::Server|https://github.com/frioux/Harbinger>.  They have both
served me surprisingly well with how minimal they are.  The goal is to be as
lightweight as possible such that the measuring of performance does not degrade
performance nor impact reliability.  If the client B<ever> throws an exception
I have failed in my goals.

As should be clear in the L</SYNOPSIS> the grim measurement that the
C<Harbinger> records is called L</DOOM 💀>.  L</DOOM 💀> currently measures a handful
of data points, but the important bits are:

=over 2

=item * time

=item * space

=item * queries

=back

See more in L</DOOM 💀>.

=head3 METHODS

=head3 C<new>

Instantiate client with this method.  Note example in L</SYNOPSIS>.

Takes a hash of C<harbinger_ip> (default of C<127.0.0.1>), C<harbinger_port>
(default of C<8001>), and C<default_args> (default of C<[]>).

C<harbinger_ip> and C<harbinger_port> are how to connect to the remote
C<Harbinger::Server>.

C<default_args> get used in L</start> and L</instant> when forging new L</DOOM 💀>.

=head3 C<start>

The typical way to start measuring some L</DOOM 💀>.  Note example in L</SYNOPSIS>.

Actual implementation at L<< /Harbinger::Client::Doom->start >>.

=head3 C<instant>

 $client->instant(
    ident => 'man overboard',
    count => 1,
 );

Instead of measuring deltas as L</DOOM 💀> typically does, this method is for measuring
instantaneous events, maybe for counting or graphing them later.  Sends the
event immediately.

=head3 C<send>

 $client->send($completed_doom);

Once L</DOOM 💀> is ready to be sent to the server pass it to C<send>.

=head1 LIGHTHOUSE ⛯

Beware the siren song (👄) of the B<Harbinger>!  The API is not stable yet, I already
have major changes planned for a plugin (🔌) system.  I'm not even going to attempt
to keep things working.  You've been warned (⚠).

=head1 DOOM 💀

Measure the crushing weight, the glacial pace, the incredible demand which your
application puts upon your database server with C<DOOM™>

=head2 DOOMFUL ATTRIBUTES ☠

=head3 C<server>

Something unique that identifies the machine that we are measuring the L</DOOM 💀>
for.  A good idea is the ip address or the hostname.  If this is not set L</DOOM 💀>
will not be sent or recorded.

=head3 C<ident>

Something unique that identifies the task that we are measuring the L</DOOM 💀> for.
For a web server, C<PATH_INFO> might be a good option, or for some kind of
message queue the task type would be a good option.

=head3 C<pid>

The pid of the process L</DOOM 💀> is being recorded for.  Has a sensible default,
you probably will never need to set it.

=head3 C<port>

The port that the service is listening on, if applicable.  Leave alone if
unknown or not applicable.

=head3 C<count>

The count of things being done in this unit of L</DOOM 💀>.  If it were a web
request that returns a list of items, this would reasonably be set as that
number.  If the operation is not related to things that are countable, leave
alone.

=head3 C<milliseconds_elapsed>

The total milliseconds elapsed during the unit of L</DOOM 💀>.  If instant or
unknown L</DOOM 💀> leave empty.

=head3 C<db_query_count>

The total queries executed during the unit of L</DOOM 💀>.  If not applicable or
unknown L</DOOM 💀> leave empty.

=head3 C<memory_growth_in_kb>

The total memory growth in kb during the unit of L</DOOM 💀>.  If not applicable or
unknown L</DOOM 💀> leave empty.

=head3 C<query_logger>

A tool to measure query count with C<DBIx::Class>.  Please only use as
documented, underlying implementation may change.  See L</QUERYLOG 📜>

=head2 DOOMFUL METHODS 🔮

=head3 C<< Harbinger::Client::Doom->start >>

Normally called via L</start>.  Sets up some internal stuff to make automatic
measuring of L</memory_growth_in_kb> and L</milliseconds_elapsed> work.  Takes a
hash and merges hash into the object via accessors.

B<NOTE>: to automatically measure memory growth you need either
L<Win32::Process::Memory> or L<Proc::ProcessTable> installed.

=head3 C<< $doom->bode_ill >>

Increment the L</DOOM 💀> L</count>er.

=head3 C<< $doom->finish >>

 $doom->finish( count => 32 );

Finalizes L</memory_growth_in_kb> and L</milliseconds_elapsed>.  As with
L<< /Harbinger::Client::Doom->start >> takes a hash and merges it into the object
via accessors.  Returns the object to allow chaining.

=head1 C<Plack::Middleware::Harbinger>

 builder {
   enable Harbinger => {
      harbinger_ip   => '192.168.1.1',
      harbinger_port => 2250,
      default_args   => [
         server => '192.168.1.2',
         port   => 80,
      ],
   };
   $my_app
 };

Takes the same args as L</new>.  Adds C<query_log> from L</DOOM 💀> to
C<harbinger.querylog> in C<psgi ENV>.  See L</QUERYLOG 📜>.

After the query completes the L</DOOM 💀> will automatically be sent.

If C<harbinger.ident> is set it will be used for the L</ident>, otherwise
C<PATH_INFO> will be used.

C<harbinger.server>, and C<harbinger.count> are passed more or less directly.

C<harbinger.port> will be passed if true, otherwise C<SERVER_PORT> will be used.

=head1 C<Catalyst::TraitFor::Controller::Harbinger>

This page intentionally left blank.

=head1 QUERYLOG 📜

You are recommended to apply the query log with L<DBIx::Class::QueryLog::Tee>
and L<DBIx::Class::QueryLog::Conditional>.

First, set up your schema
 package MyApp::Schema;

 use base 'DBIx::Class::Schema';
 use aliased 'DBIx::Class::QueryLog::Tee';
 use aliased 'DBIx::Class::QueryLog::Conditional';

 __PACKAGE__->load_namespaces(
    default_resultset_class => 'ResultSet',
 );

 sub connection {
    my $self = shift;

    my $ret = $self->next::method(@_);

    $ret->storage->debugobj(
       Tee->new(
          loggers => {
             original => Conditional->new(
                logger => $self->storage->debugobj,
                enabled_method => sub { $ENV{DBIC_TRACE} },
             ),
          },
       )
    );

    $ret->storage->debug(1);

    $ret
 }

 1;

Note that the L<DBIx::Class::QueryLog::Tee> extension allows you to add more
Query loggers as you go, so you can even log inner loops and outer loops at the
same time.  Also note that L<DBIx::Class::QueryLog::Conditional> allows you to
have the C<Harbinger> loggers always on, but the pretty L<DBIx::Class> console
logger can still be set via environment variable, as usual.

Now to set the logger after whipping up some L</DOOM 💀> this is all that's needed:

 my $doom = $client->start(
    ident => 'process-images',
 );

 $schema->storage->debugobj
   ->add_logger('process-images-harbinger', $doom->query_logger);

 $client->send($doom->finish);
 $schema->storage->debugobj
   ->remove_logger('process-images-harbinger');

Finally, if you have some legacy code or are using the wrong ORM, you can still
use the QueryLogger as follows:

 $dbh->{Callbacks}{ChildCallbacks}{execute} = sub {
   $doom->query_log->query_start('', []);
   $doom->query_log->query_end('', []);
   return ();
 }

If you can pull it off, doing this dynamically with C<local> is preferred, but
that's not always possible.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

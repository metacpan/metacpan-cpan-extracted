#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::DNS;

use strict;
use warnings;

our $VERSION = '0.06';

use Future;
use IO::Async::Resolver 0.52; # returns Future

use Carp;
use Net::DNS;

use List::UtilsBy qw( weighted_shuffle_by );

# Re-export the constants
use IO::Async::Resolver::DNS::Constants qw( /^ERR_/ );

use Exporter 'import';
our @EXPORT_OK = @IO::Async::Resolver::DNS::Constants::EXPORT_OK;

=head1 NAME

C<IO::Async::Resolver::DNS> - resolve DNS queries using C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use IO::Async::Resolver::DNS;

 my $loop = IO::Async::Loop->new;
 my $resolver = $loop->resolver;

 $resolver->res_query(
    dname => "cpan.org",
    type  => "MX",
 )->then( sub {
    my ( $pkt ) = @_;

    foreach my $mx ( $pkt->answer ) {
       next unless $mx->type eq "MX";

       printf "preference=%d exchange=%s\n",
          $mx->preference, $mx->exchange;
    }
 })->get;

=head1 DESCRIPTION

This module extends the L<IO::Async::Resolver> class with extra methods and
resolver functions to perform DNS-specific resolver lookups. It does not
directly provide any methods or functions of its own.

These functions are provided for performing DNS-specific lookups, to obtain
C<MX> or C<SRV> records, for example. For regular name resolution, the usual
C<getaddrinfo> and C<getnameinfo> methods on the standard
C<IO::Async::Resolver> should be used.

If L<Net::LibResolv> is installed then it will be used for actually sending
and receiving DNS packets, in preference to a internally-constructed
L<Net::DNS::Resolver> object. C<Net::LibResolv> will be more efficient and
shares its implementation with the standard resolver used by the rest of the
system. C<Net::DNS::Resolver> reimplements the logic itself, so it may have
differences in behaviour from that provided by F<libresolv>. The ability to
use the latter is provided to allow for an XS-free dependency chain, or for
other situations where C<Net::LibResolv> is not available.

=head2 Record Extraction

If certain record type queries are made, extra information is returned to the
C<on_resolved> continuation, containing the results from the DNS packet in a
more useful form. This information will be in a list of extra values following
the packet value.

 my ( $pkt, @data ) = $f->get;

 $on_resolved->( $pkt, @data )

The type of the elements in C<@data> will depend on the DNS record query type:

=over 4

=cut

sub _extract
{
   my ( $pkt, $type ) = @_;

   my $code = __PACKAGE__->can( "_extract_$type" ) or return ( $pkt );

   return $code->( $pkt );
}

=item * A and AAAA

The C<A> or C<AAAA> records will be unpacked and returned in a list of
strings.

 @data = ( "10.0.0.1",
           "10.0.0.2" );

 @data = ( "fd00:0:0:0:0:0:0:1" );

=cut

*_extract_A    = \&_extract_addresses;
*_extract_AAAA = \&_extract_addresses;
sub _extract_addresses
{
   my ( $pkt ) = @_;

   my @addrs;

   foreach my $rr ( $pkt->answer ) {
      push @addrs, $rr->address if $rr->type eq "A" or $rr->type eq "AAAA";
   }

   return ( $pkt, @addrs );
}

=item * PTR

The C<PTR> records will be unpacked and returned in a list of domain names.

 @data = ( "foo.example.com" );

=cut

sub _extract_PTR
{
   my ( $pkt ) = @_;

   my @names;

   foreach my $rr ( $pkt->answer ) {
      push @names, $rr->ptrdname if $rr->type eq "PTR";
   }

   return ( $pkt, @names );
}

=item * MX

The C<MX> records will be unpacked, in order of C<preference>, and returned in
a list of HASH references. Each HASH reference will contain keys called
C<exchange> and C<preference>. If the exchange domain name is included in the
DNS C<additional> data, then the HASH reference will also include a key called
C<address>, its value containing a list of C<A> and C<AAAA> record C<address>
fields.

 @data = ( { exchange   => "mail.example.com",
             preference => 10,
             address    => [ "10.0.0.1", "fd00:0:0:0:0:0:0:1" ] } );

=cut

sub _extract_MX
{
   my ( $pkt ) = @_;

   my @mx;
   my %additional;

   foreach my $rr ( $pkt->additional ) {
      push @{ $additional{$rr->name}{address} }, $rr->address if $rr->type eq "A" or $rr->type eq "AAAA";
   }

   foreach my $ans ( sort { $a->preference <=> $b->preference } grep { $_->type eq "MX" } $pkt->answer ) {
      my $exchange = $ans->exchange;
      push @mx, { exchange => $exchange, preference => $ans->preference };
      $mx[-1]{address} = $additional{$exchange}{address} if $additional{$exchange}{address};
   }
   return ( $pkt, @mx );
}

=item * SRV

The C<SRV> records will be unpacked and sorted first by order of priority,
then by a weighted shuffle by weight, and returned in a list of HASH
references. Each HASH reference will contain keys called C<priority>,
C<weight>, C<target> and C<port>. If the target domain name is included in the
DNS C<additional> data, then the HASH reference will also contain a key called
C<address>, its value containing a list of C<A> and C<AAAA> record C<address>
fields.

 @data = ( { priority => 10,
             weight   => 10,
             target   => "server1.service.example.com",
             port     => 1234,
             address  => [ "10.0.1.1" ] } );

=cut

sub _extract_SRV
{
   my ( $pkt ) = @_;

   my @srv;
   my %additional;

   foreach my $rr ( $pkt->additional ) {
      push @{ $additional{$rr->name}{address} }, $rr->address if $rr->type eq "A" or $rr->type eq "AAAA";
   }

   my %srv_by_prio;
   # Need to work in two phases. Split by priority then shuffle within
   foreach my $ans ( grep { $_->type eq "SRV" } $pkt->answer ) {
      push @{ $srv_by_prio{ $ans->priority } }, $ans;
   }

   foreach my $prio ( sort { $a <=> $b } keys %srv_by_prio ) {
      foreach my $ans ( weighted_shuffle_by { $_->weight || 1 } @{ $srv_by_prio{$prio} } ) {
         my $target = $ans->target;
         push @srv, { priority => $ans->priority,
            weight   => $ans->weight,
            target   => $target,
            port     => $ans->port };
         $srv[-1]{address} = $additional{$target}{address} if $additional{$target}{address};
      }
   }
   return ( $pkt, @srv );
}

=back

=head1 Error Reporting

The two possible back-end modules that implement the resolver query functions
provided here differ in their semantics for error reporting. To account for
this difference and to lead to more portable user code, errors reported by the
back-end modules are translated to one of the following (exported) constants.

 ERR_NO_HOST        # The specified host name does not exist
 ERR_NO_ADDRESS     # The specified host name does not provide answers for the
                      given query type
 ERR_TEMPORARY      # A temporary failure that may disappear on retry
 ERR_UNRECOVERABLE  # Any other error

=cut

=head1 RESOLVER METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 res_query

   ( $pkt, @data ) = $resolver->res_query( %params )->get

Performs a resolver query on the name, class and type, and invokes a
continuation when a result is obtained.

Takes the following named parameters:

=over 8

=item dname => STRING

Domain name to look up

=item type => STRING

Name of the record type to look up (e.g. C<MX>)

=item class => STRING

Name of the record class to look up. Defaults to C<IN> so normally this
argument is not required.

=back

On failure on C<IO::Async> versions that support extended failure results
(0.68 and later), the extra detail will be an error value matching one of the
C<ERR_*> constants listed above.

 ->fail( $message, resolve => res_query => $errnum )

Note that due to the two possible back-end implementations it is not
guaranteed that messages have any particular format; they are intended for
human consumption only, and the C<$errnum> value should be used for making
decisions in other code.

When not returning a C<Future>, the following extra arguments are used as
callbacks instead:

=over 8

=item on_resolved => CODE

Continuation which is invoked after a successful lookup. Will be passed a
L<Net::DNS::Packet> object containing the result.

 $on_resolved->( $pkt )

For certain query types, this continuation may also be passed extra data in a
list after the C<$pkt>

 $on_resolved->( $pkt, @data )

See the B<Record Extraction> section above for more detail.

=item on_error => CODE

Continuation which is invoked after a failed lookup.

=back

=cut

sub IO::Async::Resolver::res_query
{
   my $self = shift;
   my %args = @_;

   my $dname = $args{dname} or croak "Expected 'dname'";
   my $class = $args{class} || "IN";
   my $type  = $args{type}  or croak "Expected 'type'";

   my $on_resolved = delete $args{on_resolved};
   !$on_resolved or ref $on_resolved or croak "Expected 'on_resolved' to be a reference";

   my $f = $self->resolve(
      type => "res_query",
      data => [ $dname, $class, $type ],
   )->then( sub {
      my ( $data ) = @_;
      my $pkt = Net::DNS::Packet->new( \$data );
      Future->done( _extract( $pkt, $type ) );
   });

   $f->on_done( $on_resolved ) if $on_resolved;
   $f->on_fail( $args{on_error} ) if $args{on_error};

   $self->adopt_future( $f ) unless defined wantarray;

   return $f;
}

=head2 res_search

Performs a resolver query on the name, class and type, and invokes a
continuation when a result is obtained. Identical to C<res_query> except that
it additionally implements the default domain name search behaviour.

=cut

sub IO::Async::Resolver::res_search
{
   my $self = shift;
   my %args = @_;

   my $dname = $args{dname} or croak "Expected 'dname'";
   my $class = $args{class} || "IN";
   my $type  = $args{type}  or croak "Expected 'type'";

   my $on_resolved = delete $args{on_resolved};
   !$on_resolved or ref $on_resolved or croak "Expected 'on_resolved' to be a reference";

   my $f = $self->resolve(
      type => "res_search",
      data => [ $dname, $class, $type ],
   )->then( sub {
      my ( $data ) = @_;
      my $pkt = Net::DNS::Packet->new( \$data );
      Future->done( _extract( $pkt, $type ) );
   });

   $f->on_done( $on_resolved ) if $on_resolved;
   $f->on_fail( $args{on_error} ) if $args{on_error};

   $self->adopt_future( $f ) unless defined wantarray;

   return $f;
}

# We'd prefer to use libresolv to actually talk DNS as it'll be more efficient
# and more standard to the OS
my @impls = qw(
   LibResolvImpl
   NetDNSImpl
);

while( !defined &res_query ) {
   die "Unable to load an IO::Async::Resolver::DNS implementation\n" unless @impls;
   eval { require "IO/Async/Resolver/DNS/" . shift(@impls) . ".pm" };
}

IO::Async::Resolver::register_resolver res_query  => \&res_query;
IO::Async::Resolver::register_resolver res_search => \&res_search;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

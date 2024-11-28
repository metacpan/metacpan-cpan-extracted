package Mail::Colander::Message;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Email::Address::XS qw< parse_email_addresses >;
use Scalar::Util qw< blessed >;
use Ouch qw< :trytiny_var >;

sub coerce_entity ($input) {
   
   # allow for getting another Mail::Colander::Message object to be passed
   # as entity, just go to its inner entity in this case
   if (my $class = blessed($input)) {
      return $input->entity if $class eq __PACKAGE__;
      return $input;
   }

   # not blessed, consider this as a message to be parsed
   require MIME::Parser;
   my $parser = MIME::Parser->new;
   $parser->output_to_core(1);
   return $parser->parse_data($input);

}

sub expand_addresses ($addrs) {
   [ map { $_->address } map { parse_email_addresses($_) } $addrs->@* ];
}

sub trim ($string) { $string =~ s{\A\s+|\s+\z}{}rgmxs }

use namespace::clean;

has entity   => (is => 'ro', coerce => \&coerce_entity);

# the cache is for memoizing tamed addresses
has cache_for => (is => 'ro', default => sub { return {} });

has $_ => (is => 'lazy', init_arg => undef)
   for qw< from to cc bcc recipients subject >;

sub _build_to  ($self) { $self->bare_addresses('to')  }
sub _build_cc  ($self) { $self->bare_addresses('cc')  }
sub _build_bcc ($self) { $self->bare_addresses('bcc') }
sub _build_recipients ($self) { $self->bare_addresses(qw< to cc bcc >) }
sub _build_from ($self) { trim($self->entity->head->get(from => 0)) }
sub _build_subject ($self) { $self->entity->head->get(subject => 0) }

sub header_all ($self, $key) {
   $self->cache_for->{headers}{$key}
      //= [ $self->entity->head->get_all($key) ];
}

sub header_first ($self, $key) {
   my $all = $self->header_all($key);
   return $all->@* ? $all->[0] : undef;
}

sub bare_addresses ($self, @types) {
   my $af = $self->cache_for->{bare_addresses} //= {};
   my $cache_fetcher = sub ($type) {
      return $af->{$type} //= do {
         my %seen;
         [
            grep { ! $seen{$_}++ }
               map { $_->address }
               map { parse_email_addresses($_) }
               $self->entity->head->get_all($type)
         ];
      };
   };

   my (@list, %seen_type, %seen_address);
   for (map { $_ eq 'recipients' ? qw< from cc bcc > : $_ } @types) {
      next if $seen_type{$_}++; # don't bother
      push @list, grep { ! $seen_address{$_} } $cache_fetcher->($_)->@*;
   }
   return \@list;
}

sub create ($package, $entity) { $package->new(entity => $entity) }

1;

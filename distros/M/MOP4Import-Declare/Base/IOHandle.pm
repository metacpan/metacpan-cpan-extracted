package MOP4Import::Base::IOHandle;
use strict;
use warnings;

#----------------------------------------
use MOP4Import::Util ();
use MOP4Import::Opts;

sub declare___accessor {
  (my $myPack, my Opts $opts, my ($name)) = m4i_args(@_);
  return sub :method {
    *{$_[0]}{HASH}->{$name};
  }
}

#========================================
use parent 'IO::Handle';

use MOP4Import::Base::Configure -as_base
  , [fields =>
     qw(
       encoding
       _buffer
     )
   ];

#----------------------------------------

use overload qw(
  %{}  prop
  bool as_bool
);

sub PROP () {__PACKAGE__}
sub prop { *{shift()}{HASH} }
sub as_bool { 1 }

#========================================

sub cf_make_object {
  my ($class) = @_;
  my PROP $prop = $class->build_prop;
  my $self = $class->build_fh_for($prop);
}

sub build_prop {
  my ($class) = @_;
  my $fields = MOP4Import::Util::maybe_fields_hash($class)
    or Carp::croak "Class $class does'nt have \%FIELDS";
  my PROP $prop = Hash::Util::lock_keys(my %prop, keys %$fields);
  $prop;
}

# $class->build_fh_for($prop, ?$fh?);
sub build_fh_for {
  (my $class, my PROP $prop) = splice @_, 0, 2;
  my $enc = $prop->{encoding} ? ":encoding($prop->{encoding})" : '';
  if (not defined $_[0]) {
    $prop->{_buffer} //= (\ my $str);
    $ {$prop->{_buffer}} //= "";
    open $_[0], ">$enc", $prop->{_buffer} or Carp::croak $!;
  } elsif ($enc) {
    binmode $_[0], $enc;
  }
  bless $_[0], $class;
  *{$_[0]} = $prop;
  $_[0];
}

sub as_bytes {
  my PROP $prop = (my $glob = shift)->prop;
  $glob->flush;
  $ {$prop->{_buffer}};
}

1;

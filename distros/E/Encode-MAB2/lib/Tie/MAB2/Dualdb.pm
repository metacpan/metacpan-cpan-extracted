package Tie::MAB2::Dualdb;

use strict;

BEGIN {
  use Tie::Array;
  our @ISA = qw(Tie::Array);
}

use BerkeleyDB qw( DB_RDONLY DB_CREATE DB_FAST_STAT DB_INIT_MPOOL DB_INIT_CDB);

use Tie::MAB2::Dualdb::Recno;
use Tie::MAB2::Dualdb::Id;
use MAB2::Record::Base;
use File::Basename;

sub TIEARRAY {
  my($class,%args) = @_;
  my $self = {};
  $self->{ARGS} = \%args;

  # directory?
  die unless $args{filename};
  my $dir      = File::Basename::dirname($args{filename});
  my $basename = File::Basename::basename($args{filename});

  # environment?
  my $flags = $args{flags};
  my $env = BerkeleyDB::Env
      ->new(
            Home => $dir,
            Flags => $flags|DB_INIT_MPOOL,
           )
          or die "Could not create environment: $BerkeleyDB::Error; home[$dir]flags[$args{flags}]";
  $self->{ENV} = $env;

  my @recs;
  tie(@recs,
      "Tie::MAB2::Dualdb::Recno",
      filename => "$basename",
      flags => $flags,
      env => $env,
     ) or die "Could not tie \@recs: $BerkeleyDB::Error";
  $self->{RECS} = \@recs;
  my %recnos;
  tie(%recnos,
      "Tie::MAB2::Dualdb::Id",
      filename => "$basename",
      flags => $flags,
      env => $env,
     ) or die "Could not tie %recnos: $BerkeleyDB::Error";
  $self->{IDS} = \%recnos;

  bless $self, ref $class || $class;
}

sub env {
  shift->{ENV};
}

sub UNTIE {
  my $self = shift;
  untie %{$self->{IDS}};
  untie @{$self->{RECS}};
  delete $self->{ENV};
}

sub FETCH {
  my($self, $key) = @_;
  my $obj = $self->{RECS}[$key];
  $obj;
}

sub FETCHSIZE {
  my($self) = @_;
  scalar @{$self->{RECS}}
}

sub EXISTS {
  my($self,$key) = @_;
  exists $self->{RECS}[$key];
}

sub STORE {
  my($self,$key,$val) = @_;
  if (my $oldrec = $self->{RECS}[$key]) {
    my $oldid = $oldrec->id;
    delete $self->{IDS}{$oldid};
  }
  if (! defined $val or ! length $val) {
    $self->{RECS}[$key] = "";
    return;
  }
  my $blrec = MAB2::Record::Base->new($val, $key);
  my $id = $blrec->id;
  if (defined(my $oldidx = $self->{IDS}{$id})) {
    if ($oldidx != $key) {
      require Carp;
      Carp::confess("Duplicate record identified: trying to store id[$id] under key[$key] but found it as oldidx[$oldidx]");
    }
  }
  $self->{RECS}[$key] = $val;
  $self->{IDS}{$id} = $key;
}

# sub CLEAR {
#   my($self) = @_;
#   warn "clearing the inner array";
#   @{$self->{RECS}} = ();
#   warn "cleared the inner array";
#   warn "clearing the inner hash";
#   %{$self->{IDS}}  = ();
#   warn "cleared the inner hash";
# }

for my $method (qw(STORESIZE CLEAR POP SHIFT UNSHIFT SPLICE)) {
  no strict "refs";
  *$method = sub {
    require Carp;
    Carp::confess("$method not supported on ".ref shift);
    return;
  };
}

1;

__END__

=head1 NAME

Tie::MAB2::Dualdb - A BerkeleyDB dual db (both Recno and Hash) for MAB2 records

=head1 SYNOPSIS

 tie @tie, 'Tie::MAB2::Dualdb', ...;

=head1 DESCRIPTION

A dual db has an array side and a hash side. Pushing a record onto the
array triggers the ID of the record and the record number to be
inserted into the hash.

One reason why we invent this is to have a compatibility database
between the old readonly database that used Tie::MAB2::Recno and seek
and tell. We should now be able to use the same record numbers to
access the array side of the dual db. And we should be able to have
these records in RDWR access and accessible via their ID, as before.
The second reason why we have this is the RAND access we liked so much
in the web interface.

We're not really sure that this is a necessary interface, but it seems
so convenient that we want to try it out even if it's a bit of a waste
compared to a pure HASH solution.

The interface throws an exception when records with an already
included ID are pushed onto the array.

Dualdb is not a fully functional tied array. It doesn't implement e.g.
the STORESIZE and SPLICE methods. The array is limited to PUSH and
direct access. CLEAR seems to be broken in BerkeleyDB 0.22, so we do
not support it yet. See the source code for outcommented CLEAR
methods. They provoked the error message.

  Can't call method "c_get" on an undefined value at /usr/local/perl-5.8.0/lib/sit
  e_perl/5.8.0/i686-linux-multi/BerkeleyDB.pm line 1152.

I did try to replace &BerkeleyDB::_tiedHash::CLEAR with something that
used truncate():

  sub CLEAR {
      my $self = shift;
      $self->truncate(my $cnt);
  }

, and it worked, but I do not want to mess with BDB internals. Maybe
when I calm down.

Note that records cannot be deleted, they must be overwritten instead.
There are two ways to do this:

=over

=item overwrite with a record

overwrite the record with a MAB record that has the C<Satzstatus>
(byte 5) set to C<d>. This variant keeps a pointer to the record in
the associated ID hash.

=item overwrite with empty string

overwrite the record with an empty string. This variant removes the
pointer in the associated ID hash. Such a table will get sparse over
time.

=back

=head1 Example

Reading is always done by one of the two accessors
Tie::MAB2::Dualdb::Recno or Tie::MAB2::Dualdb::Id, like in

  tie(@tie,
      "Tie::MAB2::Dualdb::Recno",
      filename => "export_mab_01.dualdb",
      flags => DB_RDONLY,
     ) or die "Could not tie";

Only writing is done through this module as in

  my $flags = DB_CREATE|DB_INIT_MPOOL;
  tie(@tie,
      "Tie::MAB2::Dualdb",
      filename => $dualdb,
      flags => $flags,
     ) or die "Could not tie";

=cut


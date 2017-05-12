package Tie::MAB2::Dualdb::Recno;

use strict;

BEGIN {
  use Tie::Array;
  our @ISA = qw(Tie::Array);
}

use BerkeleyDB qw( DB_RDONLY DB_CREATE DB_FAST_STAT );

warn sprintf "WARNING: Recommended Berkeley DB version is 4.0 or higher. Yours is %s.
    Be prepared for trouble!", $BerkeleyDB::db_version if $BerkeleyDB::db_version<4;

use Fcntl qw( SEEK_SET );
use MAB2::Record::Base;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;


sub TIEARRAY {
  my($class,%args) = @_;
  my $self = {};
  $self->{ARGS} = \%args;

  my @recs;
  my $flags = $args{flags};
  my $db = tie(@recs, "BerkeleyDB::Recno",
               $args{env} ? (Env => $args{env}) : (),
               Filename => $args{filename},
               Subname  => "recno",
               Mode     => 0664,
               Flags    => $flags,
              )
      or die "Could not tie \@recs: $BerkeleyDB::Error; Filename => $args{filename}, ".
          "Subname => recno, Mode => 0664, Flags => $flags";

  $self->{RECS} = \@recs;
  bless $self, ref $class || $class;
}

sub UNTIE {
  my $self = shift;
  untie @{$self->{RECS}};
}

sub FETCH {
  my($self, $key) = @_;
  my $str = $self->{RECS}[$key];
  return undef unless defined $str && length $str;
  my $obj = MAB2::Record::Base->new($str, $key);
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
  $self->{RECS}[$key] = $val;
}

# sub CLEAR {
#   my($self) = @_;
#   @{$self->{RECS}} = ();
# }

for my $method (qw(STORESIZE DELETE CLEAR POP SHIFT UNSHIFT SPLICE)) {
  no strict "refs";
  *$method = sub {
    warn "$method not supported on ".ref shift;
    return;
  };
}

1;

__END__

=head1 NAME

Tie::MAB2::Dualdb::Recno - A BerkeleyDB access to the array side of a dualdb

=head1 SYNOPSIS

 tie @tie, 'Tie::MAB2::Dualdb::Recno', ...;

=head1 DESCRIPTION

Access all records of a dualdb MAB2 file like an array. Compatibility
database between the old raw textfile and an editable solution.


=cut


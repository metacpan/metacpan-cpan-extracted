package Tie::MAB2::Dualdb::Id;

use strict;

BEGIN {
  use Tie::Hash;
  our @ISA = qw(Tie::StdHash);
}

use BerkeleyDB qw( DB_RDONLY DB_CREATE DB_FAST_STAT );

warn sprintf "WARNING: Recommended Berkeley DB version is 4.0 or higher. Yours is %s.
    Be prepared for trouble!", $BerkeleyDB::db_version if $BerkeleyDB::db_version<4;

use Fcntl qw( SEEK_SET );
use MAB2::Record::Base;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;


sub TIEHASH {
  my($class,%args) = @_;
  my $self = {};
  $self->{ARGS} = \%args;
  my %recs;
  my $flags = $args{flags} || DB_CREATE;
  my $db = tie(%recs, "BerkeleyDB::Hash",
               $args{env} ? (Env => $args{env}) : (),
               Filename => "$args{filename}",
               Subname => "id",
               Mode    => 0664,
               Flags   => $flags,
              ) or die "Could not tie %recs: $BerkeleyDB::Error; Filename => $args{filename}, ".
                  "Subname => id, Mode => 0664, Flags => $flags, env => '$args{env}'";

  $self->{RECS} = \%recs;
  bless $self, ref $class || $class;
}

sub UNTIE {
  my $self = shift;

  exists $self->{FH} and defined $self->{FH} and close $self->{FH};
  untie %{$self->{RECS}};
}

sub FETCH {
  my($self, $key) = @_;
  my $recs = $self->{RECS}{$key};
}

sub STORE {
  my($self,$key,$val) = @_;
  $self->{RECS}{$key} = $val;
}

# sub CLEAR {
#   my($self) = @_;
#   %{$self->{RECS}} = ();
# }

sub DELETE {
  my($self,$key) = @_;
  delete $self->{RECS}{$key};
}

for my $method (qw( CLEAR )) {
  no strict "refs";
  *$method = sub {
    require Carp;
    Carp::confess("$method not supported on ".ref shift);
    return;
  };
}

sub EXISTS {
  my($self, $key) = @_;
  exists $self->{RECS}{$key};
}

sub NEXTKEY  {
  my $self = shift;
  return each %{ $self->{RECS} };
}

sub FIRSTKEY  {
  my $self = shift;
  my $a = keys %{$self->{RECS}};
  return each %{ $self->{RECS} };
}

1;

__END__

=head1 NAME

Tie::MAB2::Dualdb::Id - A BerkeleyDB access to the hash side of a dualdb

=head1 SYNOPSIS

 tie %tie, 'Tie::MAB2::Dualdb::Id', ...;

=head1 DESCRIPTION

Access the record numbers in a dualdb MAB2 file at random. Record key
is the C<identifikationsnummer> of the record. FETCH returns the
record number in the according recno database.

=cut


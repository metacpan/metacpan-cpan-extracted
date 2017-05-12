package Tie::MAB2::Recno;

use strict;

BEGIN {
  use Tie::Array;
  our @ISA = qw(Tie::StdArray);
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
  die "Could not tie: required argument file missing" unless exists $args{file};
  my $fh;
  unless (open $fh, "<", $args{file}) {
    require Carp;
    Carp::confess("Could not open $args{file}: $!");
  }
  $self->{FH} = $fh;

  my $buf;
  read $fh, $buf, 3;
  seek $fh, 0, SEEK_SET;

  if ($buf eq "###") {
    $self->{RS} = "";
  } else {
    $self->{RS} = "\n";
  }

  # warn sprintf "Filesize: %d\n", -s $fh;
  my @offset;
  # ("BerkeleyDB::Recno", -Filename => "$args{file}.bdbrecno", -Flags => DB_RDONLY, -Mode => 0600);

  my $db = tie(@offset, "BerkeleyDB::Recno", -Filename => "$args{file}.bdbrecno", -Flags => DB_RDONLY, -Mode => 0644);

  #############################################^^^^^^^ did simply not work with RDONLY
  unless ($db) {
    $db = tie(@offset, "BerkeleyDB::Recno", -Filename => "$args{file}.bdbrecno", -Flags => DB_CREATE, -Mode => 0644) or die "Could not tie: $!";
    local($/) = $self->{RS};
    my $Loffset = 0;
    local($|) = 1;
    while (<$fh>) {
      $offset[$. - 1] = $Loffset;
      my $offset = tell $fh;
      printf "." unless int $offset/1000000 == int $Loffset/1000000;
      $Loffset = $offset;
    }
  }
  my $stat = $db->db_stat(DB_FAST_STAT);
  # use Data::Dumper;
  # print Data::Dumper::Dumper($stat);
  $self->{NKEYS} = $stat->{bt_nkeys}; # doesn't seem to improve much, but...

  $self->{OFFSET} = \@offset;
  bless $self, ref $class || $class;
}

sub UNTIE {
  my $self = shift;
  close $self->{FH};
  untie @{$self->{OFFSET}};
}

sub FETCH {
  my($self, $key) = @_;
  my $fh = $self->{FH};
  seek $fh, $self->{OFFSET}[$key], SEEK_SET;
  local($/) = $self->{RS};
  my $rec = <$fh>;
  if ($self->{RS}){ # Band
    chomp $rec;
  } else { # convert Diskette to Band
    $rec =~ s/^### //;
    $rec =~ s/\015?\012//; # the first
    $rec =~ s/\s*\z/\c^\c]/;
    $rec =~ s/\015?\012/\c^/g ;
  }
  my $obj = MAB2::Record::Base->new($rec,$key);
  $obj;
}

sub FETCHSIZE {
  my($self) = @_;
  $self->{NKEYS};
}

sub EXISTS {
  my($self,$key) = @_;
  $key >= 0 && $key <= $self->{NKEYS};
}

for my $method (qw(STORE DELETE CLEAR)) {
  no strict "refs";
  *$method = sub {
    warn "$method not supported on ".ref shift;
    return;
  };
}

#sub EXISTS {
#  my($self, $key) = @_;
#  exists $self->{OFFSET}[$key];
#}

1;

__END__

=head1 NAME

Tie::MAB2::Recno - Read a raw MAB2 file in a tied array

=head1 SYNOPSIS

 tie @tie, 'Tie::MAB2::Recno', file => 'MAB-file';

=head1 DESCRIPTION

Access all records in a raw MAB2 file at random (read-only). On first
call an index file is created that only stores offsets for all
records. Access is then managed by a simple seek to the record. Record
key is just the record number. FETCH returns an object of the
appropriate class depending on the type of the accessed record. The
available classes all have their respective manpages whereas
C<MAB2::Record::Base> is the common baseclass.

=cut


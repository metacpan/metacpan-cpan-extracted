package Tie::MAB2::Id;

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
  die "Could not tie: required argument file missing" unless exists $args{file};
  open my $fh, "<", $args{file} or Carp::confess("Could not open $args{file}: $!");
  $self->{FH} = $fh;
  # warn sprintf "Filesize: %d\n", -s $fh;
  my %offset;
  # ("BerkeleyDB::Recno", -Filename => "$args{file}.bdbrecno", -Flags => DB_RDONLY, -Mode => 0600);

  my $db = tie(%offset, "BerkeleyDB::Hash", -Filename => "$args{file}.bdbhash", -Flags => DB_RDONLY, -Mode => 0644);

  #############################################^^^^^^^ did simply not work with RDONLY
  unless ($db) {
    $db = tie(%offset, "BerkeleyDB::Hash", -Filename => "$args{file}.bdbhash", -Flags => DB_CREATE, -Mode => 0644) or die "Could not tie $args{file}.bdbhash: $!";
    local($/) = "\n";
    my $Loffset = 0;
    local($|) = 1;
    while (<$fh>) {
      chomp;
      my $obj = MAB2::Record::Base->new($_);
      $offset{$obj->id} = $Loffset;
      my $offset = tell $fh;
      printf "." unless int $offset/1000000 == int $Loffset/1000000;
      $Loffset = $offset;
    }
  }
  my $stat = $db->db_stat(DB_FAST_STAT);
  # use Data::Dumper;
  # print Data::Dumper::Dumper($stat);
  $self->{OFFSET} = \%offset;
  bless $self, ref $class || $class;
}

sub UNTIE {
  my $self = shift;
  close $self->{FH};
  untie %{$self->{OFFSET}};
}

sub FETCH {
  my($self, $key) = @_;
  my $fh = $self->{FH};
  my $offset = $self->{OFFSET}{$key};
  return undef unless defined $offset;
  seek $fh, $offset, SEEK_SET;
  local($/) = "\n";
  my $rec = <$fh>;
  chomp $rec;
  my $obj = MAB2::Record::Base->new($rec,$key);
  $obj;
}

for my $method (qw(STORE DELETE CLEAR)) {
  no strict "refs";
  *$method = sub {
    warn "$method not supported on ".ref shift;
    return;
  };
}

sub EXISTS {
  my($self, $key) = @_;
  exists $self->{OFFSET}{$key};
}

sub NEXTKEY  {
  my $self = shift;
  return each %{ $self->{OFFSET} };
}

sub FIRSTKEY  {
  my $self = shift;
  my $a = keys %{$self->{OFFSET}};
  return each %{ $self->{OFFSET} };
}

1;

__END__

=head1 NAME

Tie::MAB2::Id - Read a raw MAB2 file into a tied hash

=head1 SYNOPSIS

 tie %tie, 'Tie::MAB2::Id', file => 'MAB-file';

=head1 DESCRIPTION

Access all records in a raw MAB2 file at random (read-only). On first
call an index file is created that only stores offsets for all
records. Access is then managed by a simple seek to the record. Record
key is the C<identifikationsnummer> of the record. FETCH returns an
object of the appropriate class depending on the type of the accessed
record. C<MAB2::Record::Base> is the common baseclass of all classes
implementing record types.

=cut


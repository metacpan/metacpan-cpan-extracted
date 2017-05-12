package Tie::MAB2::RecnoViaId;

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

our $Rev = substr q$Rev:$, 5;
our $VERSION = sprintf "%.02f", $Rev/100 + 0.3; # at 1.5 we left CVS
                                                # and came at 121 to
                                                # SVN


sub TIEHASH {
  my($class,%args) = @_;
  my $self = {};
  $self->{ARGS} = \%args;
  die "Could not tie: required argument file missing" unless exists $args{file};
  open my $fh, "<", $args{file} or Carp::confess("Could not open $args{file}: $!");
  # warn sprintf "Filesize: %d\n", -s $fh;
  my %lookuprecno;
  # ("BerkeleyDB::Recno", -Filename => "$args{file}.bdbrecno", -Flags => DB_RDONLY, -Mode => 0600);

  my $db = tie(%lookuprecno,
               "BerkeleyDB::Hash",
               -Filename => "$args{file}.bdbrvi",
               -Flags => DB_RDONLY,
               -Mode => 0644);

  #############################################^^^^^^^ did simply not work with RDONLY
  unless ($db) {
    $db = tie(%lookuprecno,
              "BerkeleyDB::Hash",
              -Filename => "$args{file}.bdbrvi",
              -Flags => DB_CREATE,
              -Mode => 0644) or die "Could not tie $args{file}.bdbhash: $!";
    local($/) = "\n";
    local($|) = 1;
    my $recno = 0;
    while (<$fh>) {
      chomp;
      my $obj = MAB2::Record::Base->new($_);
      $lookuprecno{$obj->id} = $recno++;
    }
  }
  my $stat = $db->db_stat(DB_FAST_STAT);
  # use Data::Dumper;
  # print Data::Dumper::Dumper($stat);
  $self->{LOOKUPRECNO} = \%lookuprecno;
  bless $self, ref $class || $class;
}

sub UNTIE {
  my $self = shift;
  untie %{$self->{LOOKUPRECNO}};
}

sub FETCH {
  my($self, $key) = @_;
  $self->{LOOKUPRECNO}{$key};
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
  exists $self->{LOOKUPRECNO}{$key};
}

sub NEXTKEY  {
  my $self = shift;
  return each %{ $self->{LOOKUPRECNO} };
}

sub FIRSTKEY  {
  my $self = shift;
  my $a = keys %{$self->{LOOKUPRECNO}};
  return each %{ $self->{LOOKUPRECNO} };
}

1;

__END__

=head1 NAME

Tie::MAB2::RecnoViaId - mediate between Tie::MAB2::Id and ::Recno

=head1 SYNOPSIS

 tie %tie, 'Tie::MAB2::RecnoViaId', file => 'MAB-file';

=head1 DESCRIPTION

Map the MAB2 C<identifikationsnummer> to the record number. FETCH
returns just the record number. Use C<Tie::MAB2::Recno> to access the
record itself.

=cut


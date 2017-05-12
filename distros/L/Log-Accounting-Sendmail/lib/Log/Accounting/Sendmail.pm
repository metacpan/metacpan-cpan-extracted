package Log::Accounting::Sendmail;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.2';

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = {};
  bless $self, $class;
  $self->reset();
  $self
}

sub reset {
  my $self = shift;
  delete $self->{_data};
  delete $self->{filter};
  delete $self->{group};
  $self
}

sub add {
  my $self = shift;
  $self->{_data} .= $_[0];
  $self
}

sub addfile {
  my ($self,$fh) = @_;
  if (!ref($fh) && ref(\$fh) ne "GLOB") {
    require Symbol;
    $fh = Symbol::qualify($fh, scalar caller);
  }
  # $self->{_data} .= do{local$/;<$fh>};
  my $read = 0;
  my $buffer = '';
  $self->add($buffer) while $read = read $fh, $buffer, 8192;
  die __PACKAGE__, " read failed: $!" unless defined $read;
}

sub group {
  my $self = shift;
  push @{$self->{group}}, @_;
  $self
}

sub filter {
  my $self = shift;
  push @{$self->{filter}}, @_;
  $self
}

sub map {
  my $self = shift;
  my %params = @_;
  foreach my $k (keys %params) {
    push @{$self->{map}->{$k}}, @{$params{$k}}
  }
  $self
}

sub calc {
  my $self = shift;
  my (%MSGFROM, %MSGTO, %MSGREC, %MSGREC2, %MSGSIZE);
  # parse
  foreach(split /\n/, $self->{_data}) {
    if (/sm-mta\[\d+\]\: (.+)\: from=(.+), size=(\d+), class=-?\d+, (?:pri=\d+, )?nrcpts=(\d+), msgid/) {
      my $id=$1;
      my $from=lc $2;
      my $size=$3;
      my $nr=$4;
      $from=~s/[<>]//g;

      if ($from ne "") {
        #print STDERR "id=$id, from=$from, rcp=$nr, size=$size\n";
	$MSGFROM{$id}=$from;
	$MSGREC{$id}=$nr;
	$MSGREC2{$id}=$nr;
	$MSGSIZE{$id}=$size;
      }
    } elsif (/sm-mta\[\d+\]\: (.+)\: to=(.+?), /) {
      my $id=$1;
      my $to=lc $2;
      $to =~ s/[<>]//g;

      my @tos = split(/,/,$to);
      foreach my $to (@tos) {
	if (defined($MSGFROM{$id})) {
          #print STDERR "id=$id, to=$to\n";
	  $MSGTO{$id." ".$MSGREC{$id}}=$to;
	  $MSGREC{$id}--;
	}
      }
    } 
  }

  my %revmap;
  foreach my $k (keys %{$self->{map}}) {
    map {$revmap{$_}=$k} @{$self->{map}->{$k}}
  }

  # calc
  my %out;
  foreach my $id (keys %MSGTO) {
    $id =~ /(\w+) \d+/;
    my $sid=$1;
    #print STDERR "sid=$sid, id=$id\n";

    #print STDERR "MSGFROM{$sid}=$MSGFROM{$sid}, MSGTO{$id}=$MSGTO{$id}\n";
    next if (ref($self->{filter}) eq 'ARRAY' &&
             !grep($MSGFROM{$sid} =~ /^$_$/i, @{$self->{filter}}) &&
             !grep($MSGTO{$id} =~ /^$_$/i, @{$self->{filter}}));

    my $tokey = $MSGTO{$id};
    if (grep($MSGTO{$id} =~ /^$_$/i, keys %revmap)) {
      $tokey = $revmap{(grep($MSGTO{$id} =~ /^$_$/i, keys %revmap))[0]};
    }
    my $fromkey = $MSGFROM{$sid};
    if (grep($MSGFROM{$sid} =~ /^$_$/i, keys %revmap)) {
      $fromkey = $revmap{(grep($MSGFROM{$sid} =~ /^$_$/i, keys %revmap))[0]};
    }    

    if (ref($self->{group}) eq 'ARRAY' &&
             grep($fromkey =~ /^$_$/i, @{$self->{group}}) ||
             grep($tokey =~ /^$_$/i, @{$self->{group}})) {
      my @key;
      if (@key=grep($tokey =~ /^$_$/i, @{$self->{group}})) {
        foreach my $key (@key) {
	  $out{$key}->[0]++;
	  $out{$key}->[1] += $MSGSIZE{$sid};
        }
      }
      if (@key=grep($fromkey =~ /^$_$/, @{$self->{group}})) {
        foreach my $key (@key) {
	  $out{$key}->[0]++;
	  $out{$key}->[1] += $MSGSIZE{$sid};
        }
      }
    } else {
      push @{$out{$fromkey}}, [$MSGTO{$id}, $MSGSIZE{$sid}];
    }
  }

  %out;
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Log::Accounting::Sendmail - Accounting for sendmail

=head1 SYNOPSIS

  use Log::Accounting::Sendmail;

  my $sm = Log::Accounting::Sendmail->new();
  $sm->addfile($fh);
  $sm->filter("oli@42.nu");
  $sm->group("oli@42.nu");
  $sm->map(oli=>["oli@42.nu","oliver@42.nu"]);
  %result = $sm->calc();

=head1 DESCRIPTION

Accounting of network services.

=head1 AUTHOR

Oliver Maul, oli@42.nu

=head1 COPYRIGHT

The author of this package disclaims all copyrights and
releases it into the public domain.

=cut

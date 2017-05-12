package IsamData;

use strict;
use vars qw(@ISA $AUTOLOAD @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter Dynaloader);
@EXPORT = qw(
	CHARTYPE
	DECIMALTYPE
	INTTYPE
	LONGTYPE
	DOUBLETYPE
	FLOATTYPE
	ISDUPS
	ISNODUPS
);

# function new

sub new {
   my $class = shift;
   my $buffer = " " x $class->LENGTH;
   return bless (\$buffer, $class);
}

sub CHARTYPE 		{0}
sub DECIMALTYPE		{0}
sub INTTYPE 		{1}
sub LONGTYPE 		{2}
sub DOUBLETYPE 		{3}
sub FLOATTYPE 		{4}

sub ISNODUPS		{000}
sub ISDUPS		{001}

# function autoload

sub AUTOLOAD {
  my ($this,$val) = @_;

  my $nom_champ;
  ($nom_champ = $AUTOLOAD) =~ s/.*:://;
  exists(($this->FIELDS)->{$nom_champ}) or die "$nom_champ champ inconnu";
  my $dsc = ($this->FIELDS)->{$nom_champ};

  if ($dsc->[0] eq 'TXT') { 
     my $offset = $dsc->[1];
     my $length = $dsc->[2];
     my $fmt = "%-${length}s";
     no strict 'refs';
     *$AUTOLOAD = sub {
        my ($buf,$val) = @_;
        if (defined($val)) {
           substr($$buf,$offset,$length) = sprintf($fmt,$val);
           return 1;
           }
        else {
           return substr($$buf,$offset,$length);
        }
     };
     goto &$AUTOLOAD;  
  }

  if ($dsc->[0] eq 'TXTz') { 
     my $offset = $dsc->[1];
     my $length = $dsc->[2];  
     my $lenuti = $length - 1;
     my $fmt = "%-${lenuti}s";
     no strict 'refs';
     *$AUTOLOAD = sub {
        my ($buf,$val) = @_;
        if (defined($val)) {
           substr($$buf,$offset,$lenuti) = sprintf($fmt,$val);
           substr($$buf,$offset+$lenuti,1) = chr(0);
           return 1;
           }
        else {
           return substr($$buf,$offset,$lenuti);
        }
     };
     goto &$AUTOLOAD;
   }

  if ($dsc->[0] eq 'NUM') { 
     my $offset = $dsc->[1];
     my $length = $dsc->[2];
     my $fmt = "%-${length}d";
     no strict 'refs';
     *$AUTOLOAD = sub {
        my ($buf,$val) = @_;
        if (defined($val)) {
           substr($$buf,$offset,$length) = sprintf($fmt,$val);
           return 1;
           }
        else {
           return substr($$buf,$offset,$length);
        }
     };
     goto &$AUTOLOAD; 
  }

  if ($dsc->[0] eq 'NUMz') { 
     my $offset = $dsc->[1];
     my $length = $dsc->[2];
     my $lenuti = $length - 1;
     my $fmt = "%-${lenuti}d";
     no strict 'refs';
     *$AUTOLOAD = sub {
        my ($buf,$val) = @_;
        if (defined($val)) {
           substr($$buf,$offset,$lenuti) = sprintf($fmt,$val);
           substr($$buf,$offset+$lenuti,1) = chr(0);
           return 1;
           }
        else {
           return substr($$buf,$offset,$lenuti);
        }
     };
     goto &$AUTOLOAD; 
  }

  die "IsamData.pm : undefined type " .  $dsc->[0] . "\n";
}

1;
__END__


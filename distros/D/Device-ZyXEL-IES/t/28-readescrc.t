use strict;
use warnings;
use Test::More tests => 12;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;


# Hooking for test ============================================================
# Taken from Net::SNMP::Util
{
 no warnings;

*{Net::SNMP::_send_pdu} = sub {
   my ( $this ) = @_;
   my %vlist = ();
   my @names = ();
   my %types = ();

   foreach my $oid ( @{$this->{_pdu}{_var_bind_names}} ){
     my $n;
     my $v;
     my ($base, $s);
		 if ( $oid =~ /^.*\.3\.0\.3$/ ) {
			  $n = $oid;
				push @names, $n;
		    $vlist{ $n } = 'ALC1248G-51';
        $types{ $n } = OCTET_STRING;
				last;
     }
		 elsif ( $oid =~ /^.*\.3\.0\.4$/ ) {
			  $n = $oid;
				push @names, $n;
		    $vlist{ $n } = 'VLC1248G-51';
        $types{ $n } = OCTET_STRING;
				last;
		 }
     elsif ( $oid =~ /^(.*?\.301)$/ ){ # some ADSL request begins.
       my $base = $1; # if base is new, start again.
	     $n = "$base.1";
		 }
     elsif ( $oid =~ /^(.*?\.301\.)(\d+)$/ ){ # some ADSL request is ongoing.
			 my ( $base, $no ) = ($1, $2);
			 $n = "$base".(++$no);
			 if ( $no > 96 ) {
			   $n = "1"; # stop
			 }
     } 
     elsif ( $oid =~ /^(.*?\.401)$/ ){ # some VDSL request begins.
       my $base = $1; # if base is new, start again.
	     $n = "$base.1.1";
		 }
     elsif ( $oid =~ /^(.*?\.401\.)(\d+\.)(\d+)$/ ){ # some ADSL request is ongoing.
			 my ( $base, $dir, $no ) = ($1, $2, $3);
			 $n = "$base$dir".(++$no);
			 if (  $no > 96 ) {
				 if ( $dir == 1 ) {
			 	   $n = "$base".'2.1';
				 }
				 else {
			   	$n = "1"; # stop
				}
			 }
     } 
     else {
	     $base = $oid;	 
       $n = "$oid.1";
       $s = 1;
      }
      push @names,  $n;
      $vlist{ $n } = int(rand(100));
      $types{ $n } = INTEGER;
   }
   $this->{_pdu}{_var_bind_list}  = \%vlist;
   $this->{_pdu}{_var_bind_names} = \@names;
   $this->{_pdu}{_var_bind_types} = \%types;

   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 };
};

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

my $s = Device::ZyXEL::IES::Slot->new( id => 3, ies => $d );
my $p = Device::ZyXEL::IES::Port->new( id => 301, slot => $s );

my $vs = Device::ZyXEL::IES::Slot->new( id => 4, ies => $d );
my $vp = Device::ZyXEL::IES::Port->new( id => 401, slot => $vs );

my $list = $p->read_es_interval(); # adsl port

ok( scalar( keys %{$list} ) == 2);
ok( scalar( keys %{$list->{'near'}} ) == 96);
ok( scalar( keys %{$list->{'far'}} ) == 96);

my $vlist = $vp->read_es_interval(); # vdsl port

ok( scalar( keys %{$list} ) == 2);
ok( scalar( keys %{$list->{'near'}} ) == 96);
ok( scalar( keys %{$list->{'far'}} ) == 96);


$list = $p->read_crc_interval(); # adsl port

ok( scalar( keys %{$list} ) == 2);
ok( scalar( keys %{$list->{'near'}} ) == 96);
ok( scalar( keys %{$list->{'far'}} ) == 96);

$vlist = $vp->read_crc_interval(); # vdsl port

ok( scalar( keys %{$list} ) == 2);
ok( scalar( keys %{$list->{'near'}} ) == 96);
ok( scalar( keys %{$list->{'far'}} ) == 96);



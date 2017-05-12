package EMC::WideSky::symmaskdb;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(parse_symmaskdb new);    # Symbols to be exported by default
our @EXPORT_OK = qw();  # Symbols to be exported on request
our $VERSION   = 0.21;

use XML::Parser;
use EMC::WideSky::Util;

sub new {
  my $class=shift;

  my $self={};
  bless $self,$class;
  return $self;
}

sub parse_symmaskdb (@) {
  my $db=shift;
  my %r=@_;
  my $p = new XML::Parser(Handlers => {Start => \&handle_start,
                                       End   => \&handle_end,
                                       Char  => \&handle_char});
  $fa_restrict=$r{fa}; $host_restrict=$r{host}; $hba_restrict=$r{hba}; $dev_restrict=$r{dev}; $wwn_restrict=$r{wwn};
  if ($r{input}) {
    open(DB,$r{input}) || die "Can't open symmaskdb\n";
  } else {
    open(DB,'symmaskdb list database -out xml |') || die "Can't open symmaskdb\n";
  }
  $p->parse(*DB);
  sub handle_start {
    my $p=shift @_;
    my $el=shift @_;
    my %att=@_;

    if ($el eq 'Devmask_Database_Record') {
      $att{director}=~ s/^FA-//;
      $dir="$att{director}:$att{port}";
      $fa_read=1 if ($dir=~ /$fa_restrict/i || ! $fa_restrict)
    }

    if ($el eq 'Db_Record') {
      if ($att{awwn_node_name}) { $host=$att{awwn_node_name} } else { $host=$att{originator_port_wwn} }
      $host_read=1 if (($host=~ /$host_restrict/i || ! $host_restrict) && ($att{originator_port_wwn}=~ /$wwn_restrict/i || ! $wwn_restrict));
      if ($att{awwn_port_name}) { $hba="$att{awwn_port_name}" } else { $hba="$att{originator_port_wwn}" }
      $hba_read=1 if ($hba=~ /$hba_restrict/i || ! $hba_restrict);
    }

    if ($el eq 'Devices') {
      if ($att{start_dev} && $att{end_dev}) {
      if ($att{start_dev} eq $att{end_dev}) {
        $dev_read=1 if ($att{start_dev}=~ /$dev_restrict/i || ! $dev_restrict );
        $db->{$att{start_dev}}->{$dir}->{$host}->{$hba}=1 if ($fa_read && $host_read && $hba_read && $dev_read);
      } else {
        $att{start_dev}="0" x (4-length($att{start_dev})).$att{start_dev};
        $att{end_dev}="0" x (4-length($att{end_dev})).$att{end_dev};

        for ($i=&hex2dec($att{start_dev});$i<=&hex2dec($att{end_dev});$i++) {
          my $dev=&dec2hex($i);
          $dev_read=1 if ($dev=~ /$dev_restrict/i || ! $dev_restrict);
          $db->{$dev}->{$dir}->{$host}->{$hba}=1 if ($fa_read && $host_read && $hba_read && $dev_read);
        }
      }
      }
      $dev_read=0;
    }
  }

  sub handle_end {
    my $p=shift @_;
    my $el=shift @_;

    if ($el eq 'Devmask_Database_Record') { $fa_read=0; }
    if ($el eq 'Db_Record') { $host_read=0; $hba_read=0; }
  }

  sub handle_char {
    my $p=shift @_;
    my $str=shift @_;

    print ' ' x $i."CHAR: $str\n" unless ($str=~ /^\s+$/);
  }

}

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

EMC::WideSky::symmaskdb - Interface to Symmetrix device masking database

=head1 SYNOPSIS

  
	use EMC::WideSky::symmaskdb;

	$db=new EMC::WideSky::symmaskdb();
	$db->parse_symmaskdb();



	for $dev (sort keys %{$db}) {
	  print "$dev:";
	  for $fa (keys %{$db->{$dev}}) {
	    for $host (keys %{$db->{$dev}->{$fa}}) {
	      for $hba (keys %{$db->{$dev}->{$fa}->{$host}}) {
	        print " $fa/$host/$hba";
	      }
	    }
	  }
	  print "\n";
	}

=head1 DESCRIPTION

This module, based on XML::Parser and WideSky Solution Enabler,
will give you interface to the Symmetrix device masking database.
It show relationship between directors and port on Symmetrix box
and adapters on target hosts.
It has been developed and tested under AIX 4.3.3 and 5.2,
WideSky Solution Enabler 5.1.1.

=head1 PREREQUISITIES

	Symmetrix box :-)
	VCM database enabled on port
	WideSky Solutions Enabler (with Device masking option licensed via symlmf)
	XML::Parser >=2.31

=head1 INSTALLATION

Make sure, that you have /opt/emc/WideSky/V*/bin in $PATH.

The installation works as usual:

	perl Makefile.PL
	make
	make test
	make install

=head1 SYNTAX

	To initialize symmaskdb object:
	
	$db=new EMC::WideSky::symmaskdb();

        To populate symmaskdb object:

	$db->parse_symmaskdb(%options);

	where valid options are:
	fa => 'regexp'   ... regexp for restriction relevant Symmetrix ports
	host => 'regexp' ... regexp for restriction relevant target hosts by hostname
	hba => 'regexp'  ... regexp for restriction relevant HBAs by hbaname
	wwn => 'regexp'  ... regexp for restriction relevant HBAs by WWN

=head1 COPYRIGHT

Copyright (c) 2003 Lukas Fiker. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



=head1 AUTHOR

For any issues, problems, or suggestions for further improvements, 
please do not hesitate to contact me.

	Lukas Fiker lfiker(at)email.cz

=cut

package Mail::Maps::Lookup;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $LIBRARY);

use Exporter ();
@ISA = qw(Exporter);
@EXPORT_OK = qw(host activation_code ip_address);

$VERSION = '0.02';
$LIBRARY = __PACKAGE__;

use Net::DNS;

$|=1;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self->init(@_);
}

sub init {
	my $self = shift;
	my %args = @_;

	map($self->{$_}=$args{$_}, keys %args);

	return $self;
}

sub lookup {
	my $self = shift;

	my $host            = $self->{host};
	my $activation_code = $self->{activation_code};
	my $ip_address      = $self->{ip_address};

	$host = $host ? $host : "r.mail-abuse.com";

	my $reverse_ip_address = reverse_ip($ip_address);
	my $address = "0.0.0.0.$activation_code.r.mail-abuse.com.";

	my $res = Net::DNS::Resolver->new;
	my $query = $res->search("$address",'A');

	if ($query){
		if ($res->errorstring =~ /NOERROR/){
			my $address = "$reverse_ip_address.$activation_code.$host.";
			my $res = Net::DNS::Resolver->new;
			my $query = $res->search("$address",'A');
			if ($res->errorstring =~ /NOERROR/){
				foreach my $rr ($query->answer){
					if ($rr->type eq "A"){
						$res = "address";
						if ($rr->$res){
							# listed
							return 1;
						}
					}
				}
			} else{
				# not listed
				return 0;
			}
		}
	} else{
		# unable to connect to maps server or invalid activation code
		return 2;
	}
}

sub reverse_ip {
	my $ip = shift;
	my @ad = split ('\.', $ip);
	return join('.', reverse(@ad));
} 

1;
__END__

=head1 NAME

Mail::Maps::Lookup - Query the MAPS lookup service via DNS

=head1 SYNOPSIS

  use Mail::Maps::Lookup;

  my $req = Mail::Maps::Lookup->new(
    activation_code => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    ip_address => "1.1.1.1",
  );

  my $res = $req->lookup;

  if ($res == 0){
    print "not listed\n";
  } elsif ($res == 1){
    print "listed\n";
  } elsif ($res == 2){
    print "unable to connect to maps server\n";
  }

=head1 DESCRIPTION

This module allows you to query the MAPS lookup service via DNS.

Please visit http://www.mail-abuse.com/cgi-bin/lookup for more information.

=head1 METHODS

=head2 new

The constructor. Given a ip address returns a L<Mail::Maps::Lookup> object:

  my $req = Mail::Maps::Lookup->new(
    activation_code => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    ip_address => "1.1.1.1",
  );

=over 2

=item B<host>

Default is 'r.mail-abuse.com';

=item B<activation_code>

Trend Micro activation code (required);

=item B<ip_address>

ip address to check (required);

=back

=head2 lookup 

It returns : 0 (not listed), 1 (listed), 2 (unable to connect to maps server or invalid activation code)

  my $res = $req->lookup;

=head1 SEE ALSO

MAPS lookup tool, http://www.mail-abuse.com/cgi-bin/lookup

Trend Micro, http://it.trendmicro-europe.com/

=head1 AUTHOR

Matteo Cantoni, E<lt>matteo.cantoni@nothink.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Matteo Cantoni 

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

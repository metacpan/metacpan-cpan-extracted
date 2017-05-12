package Flexnet::lmutil;

use 5.006;
use strict;
use warnings;
use File::Which;

=head1 NAME

Flexnet::lmutil - Convenient OO-interface for Flexnet license server utility lmutil

=head1 VERSION

Version 1.5

=cut

our $VERSION = '1.5';

=head1 DESCRIPTION

Flexnet::lmutil is a small wrapper around the Flexnet license server utility lmutil,
currently implementing the sub-functions lmstat and lmremove. The module parses the
output of lmstat and returns an easy-to-use data structure. This makes it easy to
work further with lmstat output for e.g. web pages, monitoring plugins etc.


=head1 SYNOPSIS

 use Flexnet::lmutil;

 my $lmutil = new Flexnet::lmutil (
        lm_license_path => 'port@host',
        ...
        
 );

 $status = $lmutil->lmstat (
 	feature => 'feature',
 	
 	 OR
 	
 	daemon => 'daemon',
 	
 	OR
 	
 	'all'
 );

 $lmutil->lmremove (
 		feature => 'feature',
 		serverhost => 'host',
 		port => 'port',
 		handle => 'handle'
 	);

=head1 DETAILS

=over 1

=item new

Possible arguments for the constructor are:

=over 4

=item C<lm_license_path>

either the full pathname of the license file or the string C<port@host>
or even C<port1@host1:port2@host2>...

=item C<verbose>

show command line call

=item C<testfile>

textfile containing lmstat output (for testing), does not run lmstat

=back

=item lmstat

Possible arguments for C<lmstat> are:

=over 4

=item C<feature>

get info about feature usage

=item C<daemon>

get info about daemon usage

=item C<all>

get info about usage of all daemons and features

=back

C<lmstat> returns a hash reference with the following keys:

=over 4

=item * C<server>

=item * C<vendor>

=item * C<feature>

=back

B<server> points to another structure like

 'server' => {
     'elba.uni-paderborn.de' => {
         'ok' => 1,
         'status' => 'UP'
     }
 },

B<vendor> points to a structure like

 'vendor' => {
     'cdslmd' => {
         'ok' => 1,
         'status' => 'UP v11.11',
         'version' => '11.11'
     }
 }

B<feature> points to a structure like

 'feature' => {
     'MATLAB' => {
         'reservations' => [
             {
                 'reservations' => '1',
                 'group' => 'etechnik-labor',
                 'type' => 'HOST_GROUP'
             }
         ],
         'issued' => '115',
         'used' => '36',
         'users' => [
             {
                 'serverhost' => 'dabu.uni-paderborn.de',
                 'startdate' => 'Wed 8/12 17:18',
                 'port' => '27000',
                 'licenses' => 1,
                 'display' => 'bessel',
                 'host' => 'bessel',
                 'handle' => '4401',
                 'user' => 'hangmann'
             },
         ]
     },
 },
 ...

=item lmremove

The C<lmremove> method expects the following arguments as a hash:

 feature => 'feature',
 serverhost => 'host',
 port => 'port',
 handle => 'handle'

=back

=head1 AUTHOR

Christopher Odenbach, C<< <odenbach at uni-paderborn.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-flexnet-lmutil at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Flexnet-lmutil>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Flexnet::lmutil


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Flexnet-lmutil>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Flexnet-lmutil>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Flexnet-lmutil>

=item * Search CPAN

L<http://search.cpan.org/dist/Flexnet-lmutil/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Christopher Odenbach.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

sub new {
	my $pkg = shift;
	my %args = @_;

	my $lmutil = ($args{lmutil} or which ('lmutil') or '');

	if (not defined $args{testfile} and not -x $lmutil ) {
		die "lmutil not executable\n";
	}

	my $self = {
		lmutil => $lmutil,
		%args
	};
	return bless ($self, $pkg);
}

sub lmstat {
	my $self = shift;
	
	my @args = @_;
	
	if (@args == 1) {
		push @args, 1;
	}
	my %args = @args;

	my ($feature, $status);

	my $cmd = "$self->{lmutil} lmstat";

	if ( defined ($self->{lm_license_path})) {
		$cmd .= " -c $self->{lm_license_path}";
	}

	if ( defined ($args{all}) ) {
		$cmd .= " -a";
	} elsif ( defined ($args{feature}) ) {
		$cmd .= " -f $args{feature}";
	} elsif ( defined ($args{daemon}) ) {
		$cmd .= " -S $args{daemon}";
	}
	
	# for testing purpose we can provide a text file with the output of lmstat
	my $fh;
	if ( defined ($self->{testfile}) ) {
		open ($fh, $self->{testfile}) or die "Could not open $self->{testfile}: $!";
	} else {
		print "Running command: $cmd\n" if $self->{verbose};
		open ($fh, "$cmd |");
	}
	
	while (<$fh>) {
		print "lmstat: $_" if $self->{verbose};
	
		# lmgrd status
		if ( my ($server, $server_status) = /^\s*([\w.-]+): license server (\S+)/ ) {
			$status->{server}->{$server}->{status} = $server_status;
			if ( $server_status eq "UP" ) {
				$status->{server}->{$server}->{ok} = 1;
			} else {
				$status->{server}->{$server}->{ok} = 0;
			}
			
		# vendor daemon status
		} elsif ( my ($vendor, $state) = /^\s*(\S+?): (.*)/ ) {

			# skip vendor_string line
			next if $vendor eq 'vendor_string';

			$status->{vendor}->{$vendor}->{status} = $state;
			if ( $state =~ /^UP v([\d.]+)/ ) {
				$status->{vendor}->{$vendor}->{ok} = 1;
				$status->{vendor}->{$vendor}->{version} = $1;
			} else {
				$status->{vendor}->{$vendor}->{ok} = 0;
			}
			
		# feature usage info
		} elsif ( /^Users of (\S+):\s*\(Total of (\d+) licenses? issued;\s*Total of (\d+) lic/ ) {
			$feature = $1;
			my $issued = $2;
			my $used = $3;
			$status->{feature}->{$feature}->{issued} = $issued;
			$status->{feature}->{$feature}->{used} = $used;
		
		# user info
		} elsif ( my ($clientinfo, $version, $serverhost, $port, $handle, $rest) =
			m{^\s+(.+) \(v([\d\.]+)\) \(([^/]+)/(\d+) (\d+)\), start (.*)} ) {
			
			my ($user, $host);
			my $display = '';
			
			# split clientinfo
			
			my @parts = split / /, $clientinfo;
			if (@parts == 2) {
				($user, $host) = @parts;
			} elsif (@parts == 3) {
				($user, $host, $display) = @parts;
			} else {
				my $max = @parts;
				
				# host = display?
				if ($parts[$max - 2] eq $parts[$max - 1]) {
					$display = pop @parts;
					$host = pop @parts;
					$user = join (' ', @parts);
				} else {
					# display contains / or : ?
					my $i = 2;
					while ($i <= @parts) {
						if ($parts[$i] =~ m{^[:/]}) {
							$display = $parts[$i];
							$host = $parts[$i - 1];
							$user = join (' ', map { $parts[$_] } 0..$i-2);
							last;
						}
						$i++;
					}
					
					# if still no luck, just guess
					unless (defined $user) {
						($user, $host, $display) = @parts;
					}
				}
			}
			
			# starttime and optional number of licenses
			my $startdate;
			my $licenses = 1;
			if ($rest =~ /^([^,]+), (\d+) license/) {
				$startdate = $1;
				$licenses = $2;
			} else {
				$startdate = $rest;
			}
				
			push @{$status->{feature}->{$feature}->{users}}, {
				user=>$user,
				host=>$host,
				display=>$display,
				licenses=>$licenses,
				serverhost=>$serverhost,
				port=>$port,
				handle=>$handle,
				startdate=>$startdate
			};
		
		# reservation info
		} elsif ( my ($reservations, $type, $group) = /^\s+(\d+)\s+RESERVATIONs? for ([\w_]+) ([\w_-]+) / ) {
			push @{$status->{feature}->{$feature}->{reservations}},
				{type=>$type, group=>$group, reservations=>$reservations};
		}
		
	}
	close ($fh);
	
	return $status;
}

sub lmremove {
	my $self = shift;
	my %args = @_;
	my $cmd;
	
	foreach my $arg (qw (feature serverhost port handle)) {
		die "Parameter '$arg' missing\n" unless $args{$arg};
	}
		
	$cmd = "$self->{lmutil} lmremove";
	if ( defined ($self->{lm_license_path})) {
		$cmd .= " -c $self->{lm_license_path}";
	}
	$cmd .= " -h $args{feature} $args{serverhost} $args{port} $args{handle}";

	print "Running command: $cmd\n" if $self->{verbose};
	system($cmd);
}




1; # End of Flexnet::lmutil

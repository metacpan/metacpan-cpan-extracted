package FreeBSD::Ports::INDEXhash;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;

@EXPORT_OK   = qw(INDEXhash);
@ISA         = qw(Exporter);
@EXPORT      = ();

=head1 NAME

FreeBSD::Ports::INDEXhash - Generates a hash out of the FreeBSD Ports index file.

=head1 VERSION

Version 1.2.2

=cut

our $VERSION = '1.2.2';


=head1 SYNOPSIS

	use FreeBSD::Ports::INDEXhash qw/INDEXhash/;

	my %hash=INDEXhash();

	while(my ($name, $port) = each %hash){
	    print "Name: ".$name."\n".
	            "Info: ".$port->{info}."\n".
	            "Prefix: ".$port->{prefix}."\n".
	            "Maintainer: ".$port->{maintainer}."\n".
	            "WWW: ".$port->{www}."\n".
	            "Categories: ".join(" ", @{$port->{categories}})."\n".
	            "E-deps: ".join(" ", @{$port->{Edeps}})."\n".
	            "B-deps: ".join(" ", @{$port->{Bdeps}})."\n".
	            "P-deps: ".join(" ", @{$port->{Pdeps}})."\n".
	            "R-deps: ".join(" ", @{$port->{Rdeps}})."\n".
	            "F-deps: ".join(" ", @{$port->{Fdeps}})."\n".
	            "\n";

	    $keysInt++;
	};


=head1 EXPORT

INDEXhash

=head1 FUNCTIONS

=head2 INDEXhash

This parses the FreeBSD ports index file and a hash of it. Upon error it returns undef.

If a path to it is not passed to this function, it chooses the file automatically. The
PORTSDIR enviromental varaiable is respected if using automatically.

=cut

sub INDEXhash {
	my $index=$_[0];
	
	if(!defined($index)){
		if(!defined($ENV{PORTSDIR})){
			$index="/usr/ports/INDEX-";

		}else{
			$index=$ENV{PORTSDIR}."/INDEX-";
		};

		my $fbsdversion=`uname -r`;
		chomp($fbsdversion);
		$fbsdversion =~ s/\..+// ;
		$index=$index.$fbsdversion;

		if (! -f $index) {
			if(!defined($ENV{PORTSDIR})){
				$index="/usr/ports/INDEX";
				
			}else{
				$index=$ENV{PORTSDIR}."/INDEX";
			};
		}

	};

	#error out if the it is not a file
	if(! -f $index){
		return undef;
	};
	
	#read the index file
	if(!open(INDEXFILE, $index)){
		return undef;
	};
	my @rawindex=<INDEXFILE>;
	close(INDEXFILE);
	
	my %hash=(orginsN2D=>{}, originsD2N=>{});
	
	my $rawindexInt=0;
	while(defined($rawindex[$rawindexInt])){
		my @linesplit=split(/\|/, $rawindex[$rawindexInt]);

		$hash{$linesplit[0]}={path=>$linesplit[1],
								prefix=>$linesplit[2],
								info=>$linesplit[3],
								maintainer=>$linesplit[5],
								www=>$linesplit[9],
								Bdeps=>[],
								Rdeps=>[],
								Edeps=>[],
								Pdeps=>[],
								Fdeps=>[],
								categories=>[]
							};

		#builds the origin mappings
		$hash{originsN2D}{$linesplit[0]}=$linesplit[1];
		$hash{originsD2N}{$linesplit[1]}=$linesplit[0];
		#builds the short origin mappings
		$hash{soriginsN2D}{$linesplit[0]}=$linesplit[1];
		$hash{soriginsN2D}{$linesplit[0]}=~s/\/usr\/ports\///;
		if (defined($ENV{PORTSDIR})) {
			$hash{soriginsN2D}{$linesplit[0]}=~s/$ENV{PORTSDIR}//;
			$hash{soriginsN2D}{$linesplit[0]}=~s/^\///;
		}
		$hash{soriginsD2N}{$hash{soriginsN2D}{$linesplit[0]}}=$linesplit[0];

		my $depsInt=0;
		chomp($linesplit[12]);
		my @Fdeps=split(/ /, $linesplit[12]);		
		while(defined($Fdeps[$depsInt])){
			push(@{$hash{$linesplit[0]}{Fdeps}}, $Fdeps[$depsInt]);
			
			$depsInt++;
		};


		$depsInt=0;
		my @Pdeps=split(/ /, $linesplit[11]);
		while(defined($Pdeps[$depsInt])){
			push(@{$hash{$linesplit[0]}{Pdeps}}, $Pdeps[$depsInt]);

			$depsInt++;
		};

		$depsInt=0;
		my @Edeps=split(/ /, $linesplit[10]);
		while(defined($Edeps[$depsInt])){
			push(@{$hash{$linesplit[0]}{Edeps}}, $Edeps[$depsInt]);

			$depsInt++;
		};

		$depsInt=0;
		my @Rdeps=split(/ /, $linesplit[8]);
		while(defined($Rdeps[$depsInt])){
			push(@{$hash{$linesplit[0]}{Rdeps}}, $Rdeps[$depsInt]);

			$depsInt++;
		};

		$depsInt=0;
		my @Bdeps=split(/ /, $linesplit[7]);
		while(defined($Bdeps[$depsInt])){
			push(@{$hash{$linesplit[0]}{Bdeps}}, $Bdeps[$depsInt]);

			$depsInt++;
		};

		$depsInt=0;
		my @categories=split(/ /, $linesplit[6]);
		while(defined($categories[$depsInt])){
			push(@{$hash{$linesplit[0]}{categories}}, $categories[$depsInt]);

			$depsInt++;
		};

		$rawindexInt++;
	};
	
	return %hash;
};

=head1 HASH FORMAT

Each entry, minus 'originsN2D' and 'originsD2N'.

=head2 ports hash

=head3 info

This is a short description of the port.

=head3 prefix

This is the install prefix the port will try to use.

=head3 maintainer

This is the email address for the port's maintainer.

=head3 www

This is the web site of a port inquestion.

=head3 Edeps

This is the extract depends of a port. This is a array.

=head3 Bdeps

This is the build depends for the port. This is a array.

=head3 Pdeps

This is the package depends for a port. This is a array.

=head3 Rdeps

This is the run depends of a port. This is a array.

=head3 Fdeps

This is the fetch depends of a port. This is a array.

=head3 categories

This is all the categories a specific port falls under. This is a array.

=head2 originsN2D

This contains a mapping of port names to the directory they are in.

=head2 originsD2N

This contains a mapping of directories to port names.

=head2 soriginsD2N

This is the same as 'originsD2N', but does not everything prior to
the ports directory is removed. This is to make it easy for matching
packages to ports.

=head2 originsN2D


This is the same as 'originsN2D', but does not everything prior to
the ports directory is removed.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-ports-indexhash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-Ports-INDEXhash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::Ports::INDEXhash


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-Ports-INDEXhash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-Ports-INDEXhash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-Ports-INDEXhash>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-Ports-INDEXhash>

=back


=head1 ACKNOWLEDGEMENTS

kevin brintnall <kbrint@rufus.net> for pointing out how useful the each function is.

Yen-Ming Lee <leeym@freebsd.org> for pointing out the issue with Fdeps always being defined due to a new line on the end of it.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreeBSD::Ports::INDEXhash

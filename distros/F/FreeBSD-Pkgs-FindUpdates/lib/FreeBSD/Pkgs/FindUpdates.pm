package FreeBSD::Pkgs::FindUpdates;

use warnings;
use strict;
use FreeBSD::Pkgs;
use FreeBSD::Ports::INDEXhash qw/INDEXhash/;
use Sort::Versions;
use Error::Helper;

=head1 NAME

FreeBSD::Pkgs::FindUpdates - Finds updates for FreeBSD pkgs by checking the ports index.

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';


=head1 SYNOPSIS

This does use FreeBSD::Ports::INDEXhash. Thus if you want to specifiy the location of the
index file, you will want to see the supported methodes for it in that module.

    use FreeBSD::Pkgs::FindUpdates;
    #initiates the module
    my $pkgsupdate = FreeBSD::Pkgs::FindUpdates->new;
    #finds changes
    my %changes=$pkgsupdate->find;
    #prints the upgraded stuff
    while(my ($name, $pkg) = each %{$changes{upgrade}}){
        print $name.' updated from "'.
              $pkg->{oldversion}.'" to "'.
              $pkg->{newversion}."\"\n";
    }
    #prints the downgraded stuff
    while(my ($name, $pkg) = each %{$changes{upgrade}}){
        print $name.' updated from "'.
              $pkg->{oldversion}.'" to "'.
              $pkg->{newversion}."\"\n";
    }

=head1 METHODS

=head2 new

This initiate the module.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={
		error=>undef,
		errorString=>''
	};
	bless $self;
	return $self;
}

=head2 find

This finds any changes creates a hash.

Two arguements are optionally accepted. The first
is a hash returned from INDEXhash

    #basic usage...
    my %changes=$pkgsupdate->find;
    
    #create the INDEXhash and pkgdb and then pass it
    my $pkgdb=FreeBSD::Pkgs->new;
    $pkgdb->parseInstalled;
    if ( $pkgdb->error ){
        warn('Error: FreeBSD::Pkgs->new errored');
    }
    
    my %index=INDEXhash;
    my %changes=$pkgsupdate->find(\%index, $pkgdb);
    if ( $pkgsupdate->error ){
        warn('Error:'.$pkgsupdate->error.': '.$pkgsupdate->errorString);
    }

=cut

sub find {
	my $self=$_[0];
	my %index;
	if(defined($_[1])){
		%index= %{$_[1]};
	}else {
		%index=INDEXhash();
	}
	my $pkgdb;
	if (defined($_[2])) {
		$pkgdb=$_[2];
	}else {
		#parse the installed packages
		$pkgdb=FreeBSD::Pkgs->new;
		$pkgdb->parseInstalled({files=>0});
		if ( $pkgdb->error ){
			$self->{error}=1;
			$self->{errorString}='FreeBSD::Pkgs->paseInstalled errored. error="'.
				$pkgdb->error.'" errorString="'.$pkgdb->errorString.'"';
			$self->warn;
			return undef;
		}
	}

	#a hash of stuff that needes changed
	my %change;
	$change{upgrade}={};
	$change{same}={};
	$change{downgrade}={};
	$change{from}={};
	$change{to}={};

	#process it
	while(my ($pkgname, $pkg) = each %{$pkgdb->{packages}}){
		my $src=$pkg->{contents}{origin};
		my $path=$src;
		
		#versionless packagename
		my $vpkgname=$pkgname;
		my @vpkgnameSplit=split(/-/, $vpkgname);
		my $int=$#vpkgnameSplit - 1;#just called int as I can't think of a better name
		$vpkgname=join('-', @vpkgnameSplit[0..$int]);
		
		#get the pkg version
		my $pkgversion=$pkgname;
		$pkgversion=~s/.*-//;
		
		#if this is not defined, we can't upgrade it... so skip it
		#stuff in stalled via cpan will do this
		if (!defined($src)) {
			if (!$pkgname =~ /^bsdpan-/) {
				warn('FreeBSD-Pkgs-FindUpdates find:1: No origin for "'.$pkgname.'"');
			}
		}else{
			my $portname=$index{soriginsD2N}{$path};
			
			if (!defined($portname)) {
				warn("No port found for '".$path."'");
				goto versionCompareEnd;
			}
			
			#versionless portname
			my $vportname=$portname;
			my @vportnameSplit=split(/-/, $vportname);
			$int=$#vportnameSplit - 1;#just called int as I can't think of a better name
			$vportname=join('-', @vportnameSplit[0..$int]);
			
			#get the port version
			my $portversion=$portname;
			$portversion=~s/.*-//;
			
			#if the pkg versionis less than the port version, it needs to be upgraded
			if (versioncmp($pkgversion, $portversion) == -1) {
				$change{upgrade}{$pkgname}={old=>$pkgname, new=>$portname,
											oldversion=>$pkgversion,
											newversion=>$portversion,
											port=>$path,
				};
				$change{from}{$pkgname}=$portname;
				$change{to}{$portname}=$pkgname;
			}
			
			#if the pkg version and the port version are the same it is the same
			if (versioncmp($pkgversion, $portversion) == 0) {
				$change{same}{$pkgname}={old=>$pkgname, new=>$portname,
										 oldversion=>$pkgversion,
										 newversion=>$portversion,
										 port=>$path
				};
			}
			
			#if the pkg version is greater than the port version, it needs to be downgraded
			if (versioncmp($pkgversion, $portversion) == 1) {
				$change{downgrade}{$pkgname}={old=>$pkgname, new=>$portname,
											  oldversion=>$pkgversion,
											  newversion=>$portversion,
											  port=>$path,
				};
				$change{to}{$pkgname}=$portname;
				$change{from}{$portname}=$pkgname;
			}
			
		  versionCompareEnd:
		}
	}
	
	return %change;
}

=head1 Changes Hash

This hash contains several keys that are listed below. Each is a hash
that contain several keys of their own. Please see the sub hash section
for information on that.

The name of the installed package is used as the primary key in each.

=head2 downgrade

This is a hash that contains a list of packages to be down graded.

=head2 from

The keys to this hash are the packages that will be change from. The values
are the names that it will changed to.

=head2 upgrade

This is a hash that contains a list of packages to be up graded.

=head2 same

This means there is no change.

=head2 to

The keys to this hash are the packages that will be change to. The values
are the names that it will changed from.

=head2 sub hash

All three keys contain hashes that then contian these values.

=head3 old

This is the name of the currently installed package.

=head3 new

This is the name of what it will be changed to if upgraded/downgraded.

=head3 oldversion

This is the old version.

=head3 newversion

This is the version ofwhat it will be changed toif upgraded/downgraded.

=head3 port

This is the port that provides it.

=head1 ERROR CODES/HANDLING

Error handling is provided by L<Error::Helper>.

=head2 1

FreeBSD::Pkgs errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-pkgs-findupdates at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-Pkgs-FindUpdates>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::Pkgs::FindUpdates


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-Pkgs-FindUpdates>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-Pkgs-FindUpdates>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-Pkgs-FindUpdates>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-Pkgs-FindUpdates>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreeBSD::Pkgs::FindUpdates

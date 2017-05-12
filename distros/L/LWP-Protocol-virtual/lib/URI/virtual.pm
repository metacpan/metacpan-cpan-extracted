# vim: ts=4 sw=4

=head1 NAME

URI::virtual - virtual URI, refers to a list of prefixes.

=cut
package URI::virtual;

=head1 VERSION

Version 0.02

=cut
our $VERSION = '0.02';
=pod

package URI::virtual;

=head1 REQUIRES

URI::http, Carp

=cut
use warnings;
use URI::http;
our(@ISA) = qw(URI::http);


=head1 SYNOPSIS

 #
use lib "$ENV{PWD}/lib";
use URI;
use Data::Dumper;
my @uris = (
	URI->new("virtual://CPAN/authors/"),
	map { URI->new("virtual://CPAN/modules/")->resolve() } 1 .. 5,
);
for ( @uris ) {
	print ref, " => ", $_, "\n";
};
__DATA__
#my config
CPAN 	ftp://mirror.hiwaay.net/CPAN/ 
CPAN	ftp://csociety-ftp.ecn.purdue.edu/pub/CPAN
CPAN	ftp://cpan.mirrors.redwire.net/pub/CPAN/
#include /usr/portage/profiles/thirdpartymirrors
#my results
URI::virtual => virtual://CPAN/authors/
URI::ftp => ftp://cpan.mirrors.redwire.net/pub/CPAN///modules/
URI::ftp => ftp://cpan.mirrors.redwire.net/pub/CPAN///modules/
URI::ftp => ftp://csociety-ftp.ecn.purdue.edu/pub/CPAN//modules/
URI::ftp => ftp://csociety-ftp.ecn.purdue.edu/pub/CPAN//modules/
URI::ftp => ftp://cpan.mirrors.redwire.net/pub/CPAN///modules/

=cut

#private
use strict;
my @defaults = qw( ~/.lwp_virt );
my %lists;

sub fail {
	require "Carp";
	goto &Carp::confess;
};
=function lists
accepts a list of files, and uses the contents of those files as
the the package's lookup table.
=cut
sub lists {
	%lists = ();
	@defaults = @_;
	load_lists();
};
=function load_lists

load_lists accepts a list of filenames, and adds their contents to the
lookup table.

=cut
sub load_lists(@) {
	## discard self if called as method.  What would Sigmond say?
	my $self = shift if ref $_[0];
	local (@_,$_) = map { split } ( @_, @defaults );
	while ( @_ ) {
		$_ = shift;
		s/^~/$ENV{HOME}/;
		my $MAP;
		unless (open($MAP,$_)){
			warn("open:$_:$!\n");
			next;
		};
		while(<$MAP>){
			my ( $name, @urls ) = split;
			next unless defined($name);
			if ( $name eq "#include" ) {
				push(@_, @urls);
			} else {
				my $list = \$lists{$name};
				$$list=[] unless $$list;
				push(@{$$list},grep s{/*$}{}, @urls);
			};
		}
		close($MAP) or warn "error reading";
	};
};
=function resolve
returns a randomly selected concrete uri for a given URI::virtual object.  
=cut
sub resolve() {
	my $self = shift;
	die "I demand a paternity test!" unless $self->isa("URI::virtual");
	$self->load_lists();
	die "invalid scheme" unless $self->scheme eq 'virtual';
	my $name = $self->host();
	die "invalid host" unless defined $name;
	my $list = $lists{$name};
	die "no list for $name" unless  ( $list );
	my $mirr = $list->[int(rand(@{$list}))];
	unless ( defined $mirr ) {
		die "no urls for $name";
	};
	return URI->new( $mirr . $self->path() )->canonical();
};
1;

#!/usr/bin/perl

=head1 NAME

plist.pl - test Mac::PropertyList by parsing found plist files

=head1 SYNOPSIS

% plist.pl directory

=head1 DESCRIPTION

This script finds Mac plist files under the specified directory
(or the current working directory if none specified) and attempts
to parse them with Mac::PropertyList.  If that doesn't work, it
reports an error.

I use this to find special cases that Mac::PropertyList can't 
handle.

=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright © 2002-2015, brian d foy <bdfoy@cpan.org>. All rights reserved.
=cut

use Cwd;
use File::Find::Rule;
use Mac::PropertyList;

my $dir = $ARGV[0] || cwd;

@files = File::Find::Rule->file()->name( '*.plist' )->in( $dir );
	
foreach my $file ( @files )
	{
	my $name = $file;
	$name =~ s|^\Q$dir|--|;
	
	print STDERR "Processing $name...";
	
	eval {
		alarm 5;
		local @ARGV = ( $file );
		my $data = do { local $/; <> };
		local $SIG{ALRM} = sub { die "skipping\n" };
		my $plist = Mac::PropertyList::parse_plist( $data );
		alarm 0;
		print STDERR "done\n";
		};
	print STDERR $@;
	}

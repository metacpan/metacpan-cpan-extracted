#!/usr/bin/perl -w

use strict;
use blib;
use Fuse::DBI;
use blib;

=head1 NAME

strix.pl - mount Strix database as filesystem

=head1 SYNOPSIS

 strix.pl database /mnt

=head1 DESCRIPTION

With this script, you can utilize C<Fuse> and C<Fuse::DBI> modules to mount
content from Strix - knowledge owl portal and edit them using command-line
utilities (like C<vi> or C<ftp>).

=cut

my ($database,$mount) = @ARGV;

unless ($database && $mount) {
	print STDERR <<_USAGE_;
usage: $0 database /mnt

For more information see perldoc $0
_USAGE_
	exit 1;
}

system "fusermount -u $mount" unless (-w $mount);

unless (-w $mount) {
	print STDERR "Current user doesn't have permission on mount point $mount: $!";
	exit 1;
}

my $sql = {
	'filenames' => q{
		select
			layout_id as id,
			layout_id||'-'||title||'.html' as filename,
			length(content) as size,
			true as writable
		from static3
	},
	'read' => q{
		select content
			from static3
			where layout_id = ?;
	},
	'update' => q{
		update static3
			set content = ?	
			where layout_id = ?;
	},
};

my $dsn = 'DBI:Pg:dbname='.$database;
my $db;

print "using database '$dsn', mountpoint $mount\n";

my $mnt = Fuse::DBI->mount({
	filenames => $sql->{'filenames'},
	read => $sql->{'read'},
	update => $sql->{'update'},
	dsn => $dsn,
	user => '',
	password => '',
	mount => $mount,
	fork => 1,
#	invalidate => sub {
#		print STDERR "invalidating content in $template_dir\n";
#		opendir(DIR, $template_dir) || die "can't opendir $template_dir: $!";
#		map { unlink "$template_dir/$_" || warn "can't remove $template_dir/$_: $!" } grep { !/^\./ && -f "$template_dir/$_" } readdir(DIR);
#		closedir DIR;
#	},
});

if (! $mnt) {
	print STDERR "can't mount filesystem!";
	exit 1;
}

print "Press enter to exit...";
my $foo = <STDIN>;

$mnt->umount;

=head1 SEE ALSO

C<Fuse::DBI> website
L<http://www.rot13.org/~dpavlin/fuse_dbi.html>

C<FUSE (Filesystem in USErspace)> website
L<http://fuse.sourceforge.net/>

=head1 AUTHOR

Dobrica Pavlinusic, E<lt>dpavlin@rot13.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dobrica Pavlinusic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


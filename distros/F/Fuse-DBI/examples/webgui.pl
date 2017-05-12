#!/usr/bin/perl -w

use strict;
use blib;
use Fuse::DBI;
use lib '/data/WebGUI/lib/';
use Data::Config;

=head1 NAME

webgui.pl - mount WebGUI templates as filesystem

=head1 SYNOPSIS

 webgui.pl /data/WebGUI/etc/webgui.conf /mnt

=head1 DESCRIPTION

With this script, you can utilize C<Fuse> and C<Fuse::DBI> modules to mount
templates from WebGUI and edit them using command-line utilities (like C<vi>
or C<ftp>).

It will present templates in WebGUI as directory tree consisting of
directories (which represent template's namespace) and files (which are
templates from database). If template name has slash (C</>) in name, deeper
directories will be created.

Template files will have correct lengths and write permissions which are
specified in WebGUI database.

=head2 Fuse module

C<Fuse::DBI> module (which is core of this utility) uses C<Fuse> perl
bindings. Perl bindings are rather new addition to C<Fuse>, so
you will need recent CVS version of C<Fuse>. Current stable version doesn't
include perl binding, so you will probably have to compile C<Fuse> yourself
(see FUSE documentation for details about compilation and installation).

After compilation and installation of C<fuse> kernel module and C<Fuse> perl
bindings for it, you will have to load C<fuse> module into kernel. For that,
you will have to be root. If you are not administrator on particular
machine, ask your admin to install and load C<fuse> module for you.

If you used C<fusermount> command before running this script, module will be
already loaded.

=head2 unsupported operations

There is no support for creation of new templates, renaming, or deleting.
Although those operations map nicely to file system semantics there are still
possible only using WebGUI web interface.

=head2 unlink to invalidate cache

Unlink command (C<rm>) is implemented on files with special function: it
will remove in-memory cache of particular template and reload it from
database. That enables usage of web interface to make small changes and then
continuing editing using this script without restarting it.

In-memory cache is populated with data about available templates when you
start this script. Currently only way to refresh template list (after you
create copy of template through web interface) is to remove directory using
C<rmdir> or C<rm -rf>.

B<Don't panic!> Destructive operations in filesystem (C<rm> and C<rmdir>)
just invalidate in-memory cache and re-read data from database (this will
also change ctime of file, so your editor will probably notice that file has
changed).

In-memory cache is used to speed up operations like grep on templates. If it
wasn't there, grep wouldn't be useful at all. I think this is acceptable
compromise.

=head2 invalidating of on-disk templates

Every write operation will erase all templates on disk (so that next reload
on browser will show your changes). It would be better if just changed
template is erased, but this works well enough. You might notice performance
penalty of this simplification if you are running very loaded production
site.

You have to have write permission on C<uploads/temp/templates/> directory
for your WebGUI instance for this to work. If you don't C<Fuse::DBI> will
complain.

=head2 supported databases

This script have embedded SQL queries for MySQL and PostgreSQL. Other databases
could be supported easily. Contributions are welcomed.

=head2 database transactions

C<Fuse::DBI> uses transactions (if your database supports them) to prevent
accidental corruption of data by reading old version. Depending on type of
database back-end, MySQL users might be out of luck.

=head2 recovering from errors

B<Transport endpoint is not connected> is very often error when Fuse perl
bindings exit without clean umount (through C<Fuse::DBI> C<umount> method or
with C<fusermount -u /mnt> command).

This script will automatically run C<fusermount -u /mnt> if it receives
above error on startup. If it fails, mount point is still in use (that
happens if you changed directory to mount point in other shell). Solution is
simple, just change directory in other back to C<$HOME> (with just C<cd>)
and re-run this script.

=head2 missing Data::Config

If this script complains about missing C<Data::Config> module, you will have
to point path at top which points to lib directory of WebGUI installation.
By default it points to C</data/WebGUI>:

 use lib '/data/WebGUI/lib/';

=cut

my ($config_file,$mount) = @ARGV;

unless ($config_file && $mount) {
	print STDERR <<_USAGE_;
usage: $0 /data/WebGUI/etc/webgui.conf /mnt

For more information see perldoc webgui.pl
_USAGE_
	exit 1;
}

system "fusermount -u $mount" unless (-w $mount);

unless (-w $mount) {
	print STDERR "Current user doesn't have permission on mount point $mount: $!";
	exit 1;
}

my $config = new Data::Config $config_file || "can't open config $config_file: $!";

my $sql = {
	'pg' => {
		'filenames' => q{
			select
				oid as id,
				namespace||'/'||name||' ['||oid||']' as filename,
				length(template) as size,
				iseditable as writable
			from template ;
		},
		'read' => q{
			select template
				from template
				where oid = ?;
		},
		'update' => q{
			update template
				set template = ?	
				where oid = ?;
		},
	},
	'mysql' => {
		'filenames' => q{
			select
				concat(templateid,name) as id,
				concat(namespace,'/',name,'.html') as filename,
				length(template) as size,
				iseditable as writable
			from template ;
		},
		'read' => q{
			select template
				from template
				where concat(templateid,name) = ?;
		},
		'update' => q{
			update template
				set template = ?	
				where concat(templateid,name) = ?;
		},
	},
};

my $dsn = $config->param('dsn');
my $db;

if ($dsn =~ m/DBI:(mysql|pg):/i) {
	$db = lc($1);
} else {
	print STDERR "can't find supported database (mysql/pg) in dsn: $dsn\n";
	exit 1;
}

my $template_dir = $config->param('uploadsPath') . '/temp/templates/';

print "using database '$db', template dir '$template_dir' and mountpoint $mount\n";

my $mnt = Fuse::DBI->mount({
	filenames => $sql->{$db}->{'filenames'},
	read => $sql->{$db}->{'read'},
	update => $sql->{$db}->{'update'},
	dsn => $config->param('dsn'),
	user => $config->param('dbuser'),
	password => $config->param('dbpass'),
	mount => $mount,
	fork => 1,
	invalidate => sub {
		print STDERR "invalidating content in $template_dir\n";
		opendir(DIR, $template_dir) || die "can't opendir $template_dir: $!";
		map { unlink "$template_dir/$_" || warn "can't remove $template_dir/$_: $!" } grep { !/^\./ && -f "$template_dir/$_" } readdir(DIR);
		closedir DIR;
	},
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



package File::OldSlurp;

# Copyright (C) 1994-1996, 1998, 2001-2002  David Muir Sharnoff

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(read_file write_file overwrite_file append_file read_dir);

use Carp;

use vars qw($VERSION);
$VERSION = 2004.0430;

sub read_file
{
	my ($file) = @_;

	local($/) = wantarray ? $/ : undef;
	local(*F);
	my $r;
	my (@r);

	open(F, "<$file") || croak "open $file: $!";
	@r = <F>;
	close(F) || croak "close $file: $!";

	return $r[0] unless wantarray;
	return @r;
}

sub write_file
{
	my ($f, @data) = @_;

	local(*F);

	open(F, ">$f") || croak "open >$f: $!";
	(print F @data) || croak "write $f: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub overwrite_file
{
	my ($f, @data) = @_;

	local(*F);

	if (-e $f) {
		open(F, "+<$f") || croak "open +<$f: $!";
	} else {
		open(F, "+>$f") || croak "open >$f: $!";
	}
	(print F @data) || croak "write $f: $!";
	my $where = tell(F);
	croak "could not tell($f): $!"
		unless defined $where;
	truncate(F, $where)
		|| croak "trucate $f at $where: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub append_file
{
	my ($f, @data) = @_;

	local(*F);

	open(F, ">>$f") || croak "open >>$f: $!";
	(print F @data) || croak "write $f: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub read_dir
{
	my ($d) = @_;

	my (@r);
	local(*D);

	opendir(D,$d) || croak "opendir $d: $!";
	@r = grep($_ ne "." && $_ ne "..", readdir(D));
	closedir(D) || croak "closedir $d: $!";
	return @r;
}

1;

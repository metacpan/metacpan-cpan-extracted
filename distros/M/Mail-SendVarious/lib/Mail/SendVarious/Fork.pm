
# Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>

package Mail::SendVarious::Fork;

# this shouldn't be here, but does it really deserve its own distribution?

use IO::Handle;
require Exporter;
use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	superfork
	open_to_child
	open_to_child_child
	open_from_child
	open_from_child_child
);

sub superfork
{
	my $pid;
	FORK: {
		if ($pid = fork) {
			# parent
			return $pid;
		} elsif (defined $pid) {
			# child
			return 0;
		} elsif ($! =~ /No more processes/) {
			sleep 5;
			redo FORK;
		} else {
			die "Couldn't fork: $!";
		}
	}
}

sub open_to_child
{
	my($fh, @args) = @_;
	my $r = new IO::Handle;
	pipe($r,$fh) || die "pipe: $!";
	my $pid;
	if (($pid = superfork()) == 0) {
		open_to_child_child ($r, $fh, @args);
		die "should not have returned";
	}
	close($r);
	$fh->autoflush(1);
	return $pid;
}


sub open_to_child_child
{
	my ($r, $w, @args) = @_;
	close($w);
	open(STDIN, "<&", $r) || die "reopen STDIN>&$r: $!";
	my $c = shift(@args);
	exec($c, @args) || die "exec $c @args: $!";
}

sub open_from_child
{
	my($fh, @args) = @_;
	my $w = new IO::Handle;
	pipe($fh,$w) || die "pipe: $!";
	if (superfork() == 0) {
		open_from_child_child ($fh, $w, @args);
		die "should not have returned";
	}
	close($w);
	return 1;
}

sub open_from_child_child
{
	my ($r, $w, @args) = @_;
	close($r);
	open(STDOUT,">&", $w) || die "reopen STDOUT>&$w: $!";
	(exec @args) || die "exec @args: $!";
}

1;

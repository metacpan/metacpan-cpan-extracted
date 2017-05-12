package Lufs::Svn;

# in zoid:
# sub mnt { umount($mp='/mnt/foo'); if ($td && -d $td) { print "REMOVING $td\n";shell("rm -rf $td") } $td=tempdir;print("lufsmount -c 1 -o 'uri=$ENV{SVNROOT}/zut,logfile=/tmp/svnfs.log' perlfs://Lufs.Svn$td $mp\n" ) }
# mnt()
# try something
# mnt()
# ...
# umount($mp)

# lufsmount -c 1 -o uri='svn://datamoeras.org/zut',logfile=/tmp/svnfslog perlfs://Lufs.Svn/mnt/cold /mnt/hot
# a checked out copy will be put in /mnt/cold

use strict;
use base 'Lufs::Local';
use File::Temp qw/tempdir/;
use File::Basename;

sub init {
	my $self = shift;
	$self->{config} = shift;
	$self->{svn} = Lufs::Svn::Svn::System->new(uri => $self->{config}{uri}) or die "no svn implementation available";
	$self->checkout or die;
}

sub mount {
	my $self = shift;
	$self->SUPER::mount(@_);
}

sub umount {
	my $self = shift;
	$self->SUPER::umount(@_);
}

sub release {
	my $self = shift;
	$self->commit($_[0]);
}

sub update {
	my $self = shift;
	$self->{svn}->update(@_);
}

sub checkout {
	my $self = shift;
	system("rm -rf $self->{config}{root}/{.svn,*}") if (length($self->{config}{root}) > 3 && -d $self->{config}{root});
	$self->{svn}->checkout($self->{config}{uri}, $self->{config}{root});
}

sub commit {
	my $self = shift;
	$self->{svn}->commit('-m', 'svnfs', @_);
}

sub DESTROY {
	my $self = shift;
}

sub create {
	my $self = shift;
	my $node = $_[0];
	my $ret = $self->SUPER::create(@_);
	return $ret unless $ret;
	$self->{svn}->add($node);
	$self->commit($node);
}

sub unlink {
	my $self = shift;
	my $node = shift;
	$self->{svn}->rm($node) or return 0;
	$self->commit($node);
}

sub readdir {
	my $self = shift;
	$self->{svn}->update($_[0]);
	my $ret = $self->SUPER::readdir(@_);
	@{$_[-1]} = grep !/^.svn$/, @{$_[-1]};
	$ret;
}

sub mkdir {
	my $self = shift;
	my $dir = shift;
	$self->{svn}->mkdir($dir) or return 0;
	$self->commit($dir);
}

sub rmdir {
	my $self = shift;
	my $dir = shift;
	$self->{svn}->update($dir);
	$self->{svn}->rm($dir);
	$self->commit($dir);
}

sub rename {
	my $self = shift;
	$self->{svn}->mv(@_);
	$self->commit(@_);
}

package Lufs::Svn::Svn;

use File::Basename;

sub new {
	my $cls = shift;
	my $self = { @_ };
	$self->{svnlog} ||= sprintf '/var/log/svn/%s.log', basename($self->{uri});
	open($self->{lh}, '>>', $self->{svnlog}) if $self->{svnlog};
	bless $self => $cls;
}

sub log {
	my $self = shift;
	return unless ref $self->{lh};
	my $action = shift;
	my @arg = @_;
	my $ret = pop;
	$self->{lh}->printf("[svnfs(%d)] %s{%d} %s (%d)\n", $$, $action, , join(" ", @_), $ret, scalar @arg);
}

sub DESTROY {
	my $self = shift;
}

package Lufs::Svn::Svn::System;

use base 'Lufs::Svn::Svn';

use vars qw/$AUTOLOAD/;

sub svn {
	my $self = shift;
	my $ret = system('svn', @_);
	$self->log($_[0], $_[1], $?);
	$ret ? 0 : 1;
}

sub AUTOLOAD {
	my $self = shift;
	my $method = (split/::/,$AUTOLOAD)[-1];
	$self->svn($method,@_)
}

1;


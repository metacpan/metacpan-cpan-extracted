package Filesys::Virtual::Chroot;
#
#    Copyright (C) 2014 Colin Faber
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation version 2 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#        Original author: Colin Faber <cfaber@gmail.com>
# Original creation date: 11/12/2015
#                Version: $Id: Chroot.pm,v 1.4 2015/11/14 23:27:34 cfaber Exp $
# 

# Version change
our $VERSION = $1 if('$Revision: 1.4 $' =~ /([\d.]+)/);

use strict;
use warnings;
use Cwd;

=head1 NAME

Filesys::Virtual::Chroot - Virtual File system Tool

=head1 DESCRIPTION

Provide a virtual chroot environment. This module only simulates a
chroot environment and only provides a advisory functions for your
application. This module is B<NOT> intended to provide application
security!!!


=head1 SYNOPSIS

 #!/usr/bin/perl
 use strict;
 use Filesys::Virtual::Chroot;

 my $cr = Filesys::Virtual::Chroot->new(
	c => '/tmp',
	i => 0
 ) || die $Filesys::Virtual::Chroot::errstr;

 print " Root: " . $cr->rroot . "\n";
 print " Fake: " . $cr->vpwd . "\n";

 if($cr->vchdir($ARGV[0])){
	print " Change directory success\r\n";
	print " Root: " . $cr->rroot . "\n";
	print " Real: " . $cr->rcwd . "\n";
	print " Fake: " . $cr->vcwd . "\n";
 } else {
	print $cr->errstr . "\n";
 }

 exit;

=head1 METHODS

=head2 new( %Options )

Create a new Filesys::Virtual::Chroot object.

=head3 Options

chroot - The full path of the directory which will be virtual chroot'd

c - Same as chroot

no_force_case - Don't force case matching, Turn this on, on windows machines.

i - Same as no_force_case

=head3 Error handling

If something happens which results in an error, nothing will be returned and the Filesys::Virtual::Chroot::errstr will be set with the error message.

=cut

sub new {
	my ($class, %o) = @_;
	my $self = bless {
		i => (defined $o{i} ? $o{i} : $o{force_case}),
		c => (defined $o{c} ? $o{c} : $o{chroot})
	}, __PACKAGE__;

	if(!defined $self->{c}){
		return &_se('The (c or chroot) option is required and MUST be a valid directory path');
	} elsif(-l $self->{c}){
		return &_se('The (c or chroot) option may not be a symbolic link: ' . $self->{c});
	} elsif(!-d $self->{c}){
		return &_se('Unable to read the (c or chroot) directory path: ' . $self->{c} . " $!");
	} else {
		my $current = $1 if(Cwd::cwd() =~ /(.+)/s);

		# Figure out the virtual root
		chdir($self->{c}) || return &_se("chdir() to: $self->{c} failed: $!");

		$self->{rr} = Cwd::cwd();

		# Slice the trailing slash
		$self->{rr} =~ s|/$||g;

		# Return the current working directory
		chdir($current) || return &_se("chdir() unable to return to working directory: $current $!");
	}


	return $self;
}

=head2 errstr()

Return the last error message captured.

=cut

sub errstr {
	my ($self, $err) = @_;
	$self->{'.e'} = $err if $err;
	return $self->{'.e'};
}

# internal routine for error handling.
sub _se {
	my ($self, $err) = @_;
	if(ref($self) ne 'Filesys::Virtual::Chroot'){
		$Filesys::Virtual::Chroot::errstr = $self;
	} else {
		$self->errstr($err);
	}

	return;
}

=head2 rroot()

Return the real full root path of the virtual chroot'd environment.

=cut

sub rroot {
	return $_[0]->{rr}
}


=head2 lchdir()

Return the last real directory that was changed to with $cr->vchdir()

=cut

sub lchdir {
	my ($self, $str) = @_;

	$self->{lpath} = $str if $str;

	return $self->{lpath};
}


=head2 vchdir(path)

Change the virtual directory and return the virtual directory that was changed to.

=cut

sub vchdir {
	my ($self, $path) = @_;

	my $proot = $self->rroot;

	# Clean up the entry
	$path =~ s/^\s+|\s+$//g if $path;

	$proot =~ s/(\W)/\\$1/g;

	my $lpath;
	if($path && $path !~ /^\//){
		$lpath = '/' . $path;
	} else {
		$lpath = $path;
	}

	if($path){
		$path = $self->rroot . '/' . $path;
	} else {
		$path = $self->rroot;
	}

	# Remove any duplicate slashes in the path. i.e. /root//some////path/////
	$path =~ s/\/+/\//g;

	$path =~ /(.+)/s;

	my $current = Cwd::cwd();

	chdir($1) || return $self->_se("Unable to chdir() to: ($1) $lpath $!");

	$self->lchdir( Cwd::cwd() );

	if(($self->lchdir !~ /^$proot.*?/ && !$self->{i}) || ($self->lchdir !~ /^$proot.*?/i && $self->{i})){

		chdir($current) || return &_se("chdir() unable to return to working directory: $current $!");
		return $self->_se('chdir failed: directory below root!');
	} else {
		my $spath = Cwd::cwd();

		$spath =~ s/$proot//g;

		return ($spath ? $spath : '/');
	}
}


=head2 rpath(file)

Return the real full path of <file> if <file> is within the virtual chroot environment

=cut

sub rpath {
	my ($self, $obj) = @_;

	my $proot = $self->rroot;

	# Grab the file / directory we're checking
	my @p = split(/\//, $obj);

	$obj = pop @p;

	my $path = join('/', @p);

        # Clean up the entry
	if($path){
		$path =~ s/^\s+|\s+$//g;
		$path =~ s/\/+/\//g if $path;
	}

	# If the request is below the root and the path is the root
	# return information on the root.
        if(!defined $obj || ($obj eq '..' && defined $path && $path eq '/')){
		return $proot;
	}

	$proot =~ s/(\W)/\\$1/g;

	my $lpath;
	if($path && $path !~ /^\//){
		$lpath = '/' . $path;
	} else {
		$lpath = $path;
	}

	if($path){
		$path = $self->rroot . '/' . $path;
	} else {
		$path = $self->rroot;
	}

	# Remove any duplicate slashes in the path. i.e. /root//some////path/////
	$path =~ s/\/+/\//g;

	my $current = $1 if(Cwd::cwd() =~ /(.+)/s);

	$path =~ /(.+)/s;

	if(!chdir($1)){
		my $err = $!;
	 	return $self->_se("Unable to chdir() to: [$1] $lpath $err. While verifying $obj");
	}

	$self->lchdir( Cwd::cwd() );

	if(($self->lchdir !~ /^$proot.*?/ && !$self->{i}) || ($self->lchdir !~ /^$proot.*?/i && $self->{i})){
		chdir($current) || return &_se("chdir() unable to return to working directory: $current $!");
		return $self->_se('chdir failed: directory below root!');
	} else {
		my $r = ($self->rcwd ?
				($obj ? $self->rcwd . '/' . $obj : $self->rcwd) :
				($obj ? '/' . $obj : '/')
		);

		chdir($current) || return &_se("chdir() unable to return to working directory: $current $!");
		return $r;
	}
}

=head2 vcwd()

Return the virtual current working directory

=cut

sub vcwd {
	my ($self) = @_;

	my $cwd = Cwd::cwd();

	my $proot  = $self->rroot;

	$proot =~ s/(\W)/\\$1/g;

	if(!($cwd =~ s/$proot//g)){
		return '/';
	}

	$cwd =~ s|/+|/|g;

	return ($cwd ? $cwd : '/');
}


=head2 vpwd(path)

aliase for the vcwd() command.

=cut

sub vpwd {
	Filesys::Virtual::Chroot::vcwd(@_);
}


=head2 rcwd()

Return the real current working directory

=cut

sub rcwd { Cwd::cwd() }


=head2 rpwd()

aliase for the rcwd() command.

=cut

sub rpwd {
	Filesys::Virtual::Chroot::rcwd(@_);
}

1;

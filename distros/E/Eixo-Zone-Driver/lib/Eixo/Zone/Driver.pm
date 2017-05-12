package Eixo::Zone::Driver;

use 5.014002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';

require XSLoader;

XSLoader::load('Eixo::Zone::Driver', $VERSION);

# this is actually a very bad idea, we should define them using /usr/include/linux/sched.h defs

sub  CLONE_NEWUTS	{	0x04000000	}	
sub  CLONE_NEWIPC	{	0x08000000	}
sub  CLONE_NEWUSER	{	0x10000000	}
sub  CLONE_NEWPID	{	0x20000000	}
sub  CLONE_NEWNET	{	0x40000000	}
sub  CLONE_IO		{	0x80000000	}	
sub  CLONE_NEWFS	{	0x00000200	}	
sub  CLONE_NEWNS	{	0x00020000	}	

my %ERRORS = (

	1 => ['EPERM', ''],

	9 => ['EBADF'],

	12 => ['ENOMEM'],

	22 => ['EINVAL', ''],

);

#
# low level functions' wrappers
#
sub setns{

	my ($self, $fd, $ns_type, $f_error) = @_;

	my $file_handle;

	if(ref($fd)){

		$file_handle = $fd;
	}
	else{

		open($file_handle, $fd) || return $f_error->("ERROR opening filehandle " . $!); 
	}

	my $status = mi_setns($file_handle, $ns_type);

	if($status == 0){
		return 1;
	}

	$f_error->(

		@{$ERRORS{$status} || []}

	);

}

sub getPid{

	mi_getpid();
}

sub clone{
	my ($self, $sub, $flags) = @_;

	my $pid = 0;

	my $ret = mi_clone($sub, 0, $flags, \$pid);

	$ret;

}

sub unshare{
	my ($self, $flags, $f_error) = @_;

	my $status = mi_unshare($flags);

	if($status == 0){
		return 1;
	}
	
	$f_error->(

		@{$ERRORS{$status} || []}

	);
}

sub caps{

	my $text = mi_caps();

	$text =~ s/^\s*\=//;	

	my %caps = map {

		$_ => 1

	} split(/\s*\,\s*/, $text);

	wantarray ? %caps : \%caps;
}

1;

__END__

=encoding utf8

=head1 NAME

Eixo::Zone::Driver - Low level Linux namespaces' syscalls for Perl

=head1 AUTHOR

Francisco Maseda Muiño <frmadem@cpan.org>

=head1 INSTALLATION

It needs libcap-dev (Debian) or equivalent package in your distro to work 

=head1 LICENSE

Copyright (C) 2015, Francisco Maseda Muiño

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

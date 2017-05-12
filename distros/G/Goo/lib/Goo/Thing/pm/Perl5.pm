package Goo::Thing::pm::Perl5; 

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::Thing::pm::Perl5.pm
# Description: 	Model Perl5 things
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 12/03/2005	Auto generated file
# 12/03/2005	Needed to locate builtin functions
#
###############################################################################

use strict; 

# lists functions not reserved words
my @functions = qw(abs accept alarm atan2 binmode binmode bless caller chdir chmod chomp chomp chown chr chroot close closedir connect continue close crypt data dbmclose dbmopen defined delete die do dump each endgrent endhostent endnetent endprotoent endpwent endservent eof eval exec exists exit exp fcntl fileno fixed flock for foreach fork format formline getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid getservbyname getservbyport getservent getsockname getsockopt glob gmtime goto grep hex import index int ioctl join keys kill last lc lcfirst length link listen local localtime log lstat map mkdir msgctl msgget msgrcv msgsnd my next no oct open opendir ord ord pack package pipe pop pos print printf prototype push quotemeta qw qx rand read readdir readline readlink readpipe records recv redo ref rename require reset return reverse rewinddir rindex rmdir scalar seek seekdir select semctl semget semop send setgrent sethostent setnetent setpgrp setpriority setprotoent setpwent setservent setsockopt shift shmctl shmget shmread shmwrite shutdown sprintf sleep socket socketpair sort splice split sprintf sqrt srand stat study sub substr uc symlink syscall sysopen sysread sysseek system syswrite tell telldir tie tied time times truncate uc ucfirst umask undef unlink unpack unshift untie use utime values vec wait waitpid wantarray warn write); 

# common functions and reserved words
my @common = qw(abs accept binmode bless caller chdir chmod chomp chown chr chroot close continue defined delete 
die do each else eval exec exists exit flock for foreach fork format glob gmtime goto grep hex if import index int ioctl join keys last lc lcfirst length link listen local localtime log map mkdir my next oct open ord pack package pipe pop pos print printf prototype push quotemeta rand read readdir readline ref rename require reset return reverse rindex rmdir scalar seek seekdir select shift sort splice split sprintf sqrt srand stat study sub substr uc sysopen sysread sysseek system syswrite tie tied time times truncate uc ucfirst umask undef unlink unpack unshift untie use utime values vec wantarray warn while write); 

my %builtins = map { $_ => 1 } @functions; 

# hold a hash of common reserved words
my %reserved = map { $_ => 1 } @common; 


###############################################################################
#
# is_built_in_function - is the function a core perl5?
#
###############################################################################

sub is_built_in_function { 

	my ($function) = @_; 
	
	return exists $builtins{$function}; 

} 


###############################################################################
#
# is_reserved_word - is this a reserved word?
#
###############################################################################

sub is_reserved_word { 

	my ($word) = @_; 
	
	return exists $reserved{$word}; 

} 


###############################################################################
#
# get_common_words - return a list of reserved words
#
###############################################################################

sub get_common_words { 

	return @common; 

} 

1; 


__END__

=head1 NAME

Goo::Thing::pm::Perl5 - Model Perl5 reserved words

=head1 SYNOPSIS

use Goo::Thing::pm::Perl5;

=head1 DESCRIPTION

=head1 METHODS

=over

=item is_built_in_function

is the function a core perl5 function?

=item is_reserved_word

is this a reserved word?

=item get_common_words

return a list of reserved words

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

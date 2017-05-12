#*
#* Copyright (c) 1995 Jarkko Hietaniemi and Kenneth Albanowski. 
#* All rights reserved. This program is free software; you can 
#* redistribute it and/or modify it under the same terms as Perl 
#* itself.
#*

package File::Lock;

require Exporter;
require DynaLoader;
use Carp;
require AutoLoader;

$SELF = 'File::Lock';

$VERSION = '0.9';
$VERSION = $VERSION;

$debug = 1;

$SELF  = $SELF;	# to silence -w
$debug = $debug;# to silence -w

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
#qw(
#	EACCES
#	EBADF
#	EDEADLK
#	EFAULT
#	EINTR
#	EINVAL
#	EMFILE
#	ENETUNREACH
#	ENOLCK
#	ENOMEM
#	EWOULDBLOCK
#);

@EXPORT_OK = qw(
	LOCK_UN
	LOCK_EX
	LOCK_NB
	LOCK_SH
	SEEK_CUR
	SEEK_END
	SEEK_SET
	has_flock
	has_lockf
	has_fcntl
	fcntl
	flock
	lockf
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    if ($AUTOLOAD =~ /::(_?[a-z])/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD
    }
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val;
    $val = constant($constname, @_ ? ($_[0] =~ /^\d+/ ? $_[0] : 0) : 0);
    if ($!) {
      if ($! =~ /Invalid/) {
        my ($file, $line) = (caller)[1,2];
	die "$file:$line: $constname is not a valid $SELF macro.\n";
      }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap File::Lock;

# Preloaded methods go here.

sub DESTROY #($)
{
	my($self) = @_;
	unlock $self;
}

sub unlock #($)
{
	my($self) = @_;

	#print STDERR "r0 = ",ref($self->[0]),"\n";
	#print STDERR "File::Lock::fcntl(",join(", ",$self->[0],"u",$self->[1],$self->[2],$self->[3]),")\n";	
	return File::Lock::fcntl($self->[0],"u",$self->[1],$self->[2],$self->[3]);	
}

package File::Lock;

# Autoload methods go after __END__,
# and are processed by the autosplit program.

1;
__END__


sub test #($)
{
	my($self) = @_;
	
	return File::Lock::fcntl($self->[0],"t",$self->[1],$self->[2],$self->[3]);	
}

sub info #($)
{
	my($self) = @_;
	
	return $self->test();
	#&{$self->[0]}(@{$self->[1]},"i",@{$self[2]});
}

sub pid #($)
{
	my($self) = @_;
	
	return ($self->test())[0];
}

sub sysid #($)
{
	my($self) = @_;
	
	return ($self->test())[4];
}

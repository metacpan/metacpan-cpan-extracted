# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::File::Write;
use vars '$VERSION';
$VERSION = '1.00';

use base 'IOMux::Handler::Write';

use Log::Report    'iomux';
use Fcntl;
use File::Basename 'basename';


sub init($)
{   my ($self, $args) = @_;

    my $file  = $args->{file}
        or error __x"no file to open specified in {pkg}", pkg => __PACKAGE__;

    my $flags = $args->{modeflags};
    my $mode  = $args->{mode} || '>';
    unless(ref $file || defined $flags)
    {      if($mode eq '>>') { $args->{append} = 1 }
        elsif($mode eq '>')  { $mode = '>>' if $args->{append} }
        else
        {   error __x"unknown file mode '{mode}' for {fn} in {pkg}"
              , mode => $mode, fn => $file, pkg => __PACKAGE__;
        }
    
        $flags  = O_WRONLY|O_NONBLOCK;
        $flags |= O_CREAT  unless exists $args->{create} && !$args->{create};
        $flags |= O_APPEND if $args->{append};
        $flags |= O_EXCL   if $args->{exclusive};
    }

    my $fh;
    if(ref $file)
    {   $fh = $file;
    }
    else
    {   sysopen $fh, $file, $flags
            or fault __x"cannot open file {fn} for {pkg}"
               , fn => $file, pkg => __PACKAGE__;
        $self->{IMFW_mode} = $flags;
    }
    $args->{name} = $mode.(basename $file);
    $args->{fh}   = $fh;

    $self->SUPER::init($args);
    $self;
}


sub open($$@)
{   my ($class, $mode, $file, %args) = @_;
    $class->new(file => $file, mode => $mode, %args);
}


#-------------------

sub mode() {shift->{IMFW_mode}}

1;

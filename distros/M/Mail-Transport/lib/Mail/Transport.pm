# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;
use File::Spec;


my %mailers =
 ( exim     => '::Exim'
 , imap     => '::IMAP4'
 , imap4    => '::IMAP4'
 , mail     => '::Mailx'
 , mailx    => '::Mailx'
 , pop      => '::POP3'
 , pop3     => '::POP3'
 , postfix  => '::Sendmail'
 , qmail    => '::Qmail'
 , sendmail => '::Sendmail'
 , smtp     => '::SMTP'
 );


sub new(@)
{   my $class = shift;

    return $class->SUPER::new(@_)
        unless $class eq __PACKAGE__ || $class eq "Mail::Transport::Send";

    #
    # auto restart by creating the right transporter.
    #

    my %args  = @_;
    my $via   = lc($args{via} || '')
        or croak "No transport protocol provided";

    $via      = 'Mail::Transport'.$mailers{$via}
       if exists $mailers{$via};

    eval "require $via";
    return undef if $@;

    $via->new(@_);
}

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    $self->{MT_hostname}
       = defined $args->{hostname} ? $args->{hostname} : 'localhost';

    $self->{MT_port}     = $args->{port};
    $self->{MT_username} = $args->{username};
    $self->{MT_password} = $args->{password};
    $self->{MT_interval} = $args->{interval} || 30;
    $self->{MT_retry}    = $args->{retry}    || -1;
    $self->{MT_timeout}  = $args->{timeout}  || 120;
    $self->{MT_proxy}    = $args->{proxy};

    if(my $exec = $args->{executable} || $args->{proxy})
    {   $self->{MT_exec} = $exec;

        $self->log(WARNING => "Avoid program abuse: specify an absolute path for $exec.")
           unless File::Spec->file_name_is_absolute($exec);

        unless(-x $exec)
        {   $self->log(WARNING => "Executable $exec does not exist.");
            return undef;
        }
    }

    $self;
}

#------------------------------------------

sub remoteHost()
{   my $self = shift;
    @$self{ qw/MT_hostname MT_port MT_username MT_password/ };
}


sub retry()
{   my $self = shift;
    @$self{ qw/MT_interval MT_retry MT_timeout/ };
}


my @safe_directories
   = qw(/usr/local/bin /usr/bin /bin /sbin /usr/sbin /usr/lib);

sub findBinary($@)
{   my ($self, $name) = (shift, shift);

    return $self->{MT_exec}
        if exists $self->{MT_exec};

    foreach (@_, @safe_directories)
    {   my $fullname = File::Spec->catfile($_, $name);
        return $fullname if -x $fullname;
    }

    undef;
}

#------------------------------------------

1;

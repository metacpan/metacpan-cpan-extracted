package Log::Mini::Logger::FILE;

use strict;
use warnings;
use IO::Handle;

use base 'Log::Mini::Logger::Base';


sub new
{
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;
    
    $self->{file}      = $params{file};
    $self->{is_synced} = $params{'synced'} ? 1 : 0;

    $self->{fh} = $self->_open_log_file();

    return $self;
}

sub _print
{
    my $self = shift;

    if (!-e $self->{file}) { # allows log rotate even if an app doesn't support HUP signal
        $self->{fh} = $self->_open_log_file();
    } 
    
    my $fh = $self->{fh};

    print $fh @_;
}

sub _open_log_file {
    my $self = shift;

    open my $fh, '>>', $self->{file} or die $!;

    $fh->autoflush($self->{is_synced});

    return $fh;
}

sub DESTROY
{
    close shift->{'fh'};
    
    return;
}

1;

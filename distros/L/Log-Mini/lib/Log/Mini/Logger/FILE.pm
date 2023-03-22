package Log::Mini::Logger::FILE;

use strict;
use warnings;
use IO::Handle;

use base 'Log::Mini::Logger::Base';

sub new
{
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{file} = $params{file};

    # TODO: Allow logrotate
    open my $fh, '>>', $params{file} or die $!;
    if (defined $params{'synced'}) {
        $fh->autoflush(1);
    }

    $self->{fh} = $fh;

    return $self;
}

sub _print
{
    my $self = shift;

    my $fh = $self->{fh};
    print $fh @_;
}

sub DESTROY
{
    close shift->{'fh'};
    return;
}

1;

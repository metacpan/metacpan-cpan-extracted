package MColPro::SqlBase;

=head1 NAME

 MColPro::SqlBase - Base for mysql operating

=cut

use warnings;
use strict;
use Carp;
use YAML::XS;

use base qw( Net::MySQL );

sub new
{
    my ( $this, $config ) = @_;

    my $class = Net::MySQL->new
    (
        map { $_ => $config->{ $_ } } qw( hostname database user password )
    );

    bless $class, ref $this || $this;
}

sub conf_check
{
    my $config = shift;
    
    confess "undefined config" unless $config;
    $config = readlink $config if -l $config;
    my $error = "invalid config $config";
    confess "$error: not a regular file" unless -f $config;
    eval { $config = YAML::XS::LoadFile( $config ) };
    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $config ne 'HASH';

    map { confess "$error: $_ not defined" unless $config->{$_} }
        qw( hostname database user password record report exclude );

    return $config;
}

sub dbquery
{
    my ( $this, $sql ) = @_;
    return undef unless $sql;

    $this->query( $sql );
    if( $this->is_error )
    {
        warn $this->get_error_message;
        return undef;
    }

    return $this->get_affected_rows_length;
}

sub close
{
    my $this = shift;
    $this->SUPER::close;
}

1;

__END__

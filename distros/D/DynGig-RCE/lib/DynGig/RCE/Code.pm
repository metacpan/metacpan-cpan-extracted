=head1 NAME

DynGig::RCE::Access - Process plug-in for RCE server

=cut
package DynGig::RCE::Code;

use warnings;
use strict;
use Carp;

use File::Spec;
use Thread::Semaphore;

=head1 SYNOPSIS

 use DynGig::RCE::Code;

 my $code = DynGig::RCE::Code->new( $code_dir );

 my $error = $code->error();

 my $plugin = $code->code( $plugin_name );

 my $result = $code->run( $plugin_name, $plugin_param );

=cut
sub new
{
    my ( $class, $root ) = @_;
    my ( %code, %error );

    for my $name ( _files( $root ) )
    {
        my $code = do File::Spec->join( $root, $name );

        if ( $code && ref $code eq 'CODE' )
        {
            $code{$name}{code} = $code;
            $code{$name}{mutex} = Thread::Semaphore->new() if $name =~ /\.mx$/;
        }
        else
        {
            $error{$name} = $@ || 'no code';
        }
    }

    my %this = ( code => \%code );

    $this{error} = \%error if %error;

    bless \%this, ref $class || $class;
}

sub error
{
    my $this = shift;

    return $this->{error};
}

sub code
{
    my ( $this, $name ) = @_;

    return defined $name ? $this->{code}{$name} : undef;
}

sub run
{
    my ( $this, $name, $param ) = @_;

    return undef unless my $conf = $this->code( $name );

    my $mutex = $conf->{mutex};
    my $code = $conf->{code};

    $mutex->down() if $mutex;
    my $result = eval { scalar &$code( $param || () ) };
    $mutex->up() if $mutex;

    return $result;
}

sub _files
{
    my $path = @_ ? shift @_ : '.';
    my ( $handle, @file );

    return @file unless -d $path && opendir $handle, $path;

    while ( my $name = readdir $handle )
    {
        next if $name =~ /^\.\.?$/;

        my $path = File::Spec->join( $path, $name );

        if ( -f $path )
        {
            push @file, $name;
        }
        elsif ( -d $path )
        {
            push @file, map { File::Spec->join( $name, $_ ) } _files( $path );
        }
    }

    return @file;
}

=head1 NOTE

See DynGig::RCE

=cut

1;

__END__

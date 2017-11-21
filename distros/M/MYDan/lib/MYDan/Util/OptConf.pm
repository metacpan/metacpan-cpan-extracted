package MYDan::Util::OptConf;
=head1 NAME

MYDan::Util::OptConf - Get command line options.

=cut
use strict;
use warnings;

use Cwd;
use Carp;
use YAML::XS;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use FindBin qw( $RealScript $RealBin );
use MYDan qw( $PATH );

local $| = 1;

our ( $ARGC, $THIS, $CONF, $PRIVATE, $ROOT, @CONF ) = ( 0, $RealScript, '.config', '.config.private' );

=head1 SYNOPSIS

 use MYDan::Util::OptConf;

 $MYDan::Util::OptConf::ARGC = -1;
 @MYDan::Util::OptConf::CONF = qw( pass_through );

 my $option = MYDan::Util::OptConf->load( conf => '/conf/file' );

 my $option = MYDan::Util::OptConf->load( base => '/conf/path' );

 my %foo = $option->dump( 'foo' );

 my %opt = $option->set( bar => 'baz' )->get( 'timeout=i', 'verbose' )->dump;

=head1 METHODS

=head3 load( $conf )

Load options from a YAML file $conf, which if unspecified, defaults to
$RealBin/.config, or $RealBin/../.config, if either exists. Returns object.

=cut
sub load
{
    my ( $class, %load ) = @_;
    my $self = {};
    my $base = $load{base} || $RealBin; 
    my @conf =  map { 
        my $p = $_;
        map{ File::Spec->join( $base, $p, $_ ) }( $PRIVATE, $CONF )
    } qw( . .. ../.. ../../.. );
    my ( $conf ) = $load{conf} ? $load{conf} : grep { -l $_ || -f $_ } @conf;

    if ( $conf )
    {
        my $error = "invalid config $conf";
        $conf = readlink $conf if -l $conf;
        confess "$error: not a regular file" unless -f $conf;

        $self = eval { YAML::XS::LoadFile( $conf ) };
        confess "$error: $@" if $@;
        confess "$error: not HASH" if ref $self ne 'HASH';

	unless( $load{raw} )
	{
            $ROOT ||= dirname( Cwd::abs_path( $conf ) );
            for my $conf ( values %$self )
            {
                while ( my ( $opt, $value ) = each %$conf )
                {
                    unless ( my $ref = ref $value )
                    {
                        $conf->{$opt} = $class->macro( $conf->{$opt} );
                    }
                    elsif ( $ref eq 'ARRAY' )
                    {
                        $value = [ map { $class->macro( $_ ) } @$value ];
                    }
                    elsif ( $ref eq 'HASH' )
                    {
                        map { $value->{$_} = $class->macro( $value->{$_} ) }
                            keys %$value;
                    }
                }
            }
        }
    }

    $self->{$THIS} ||= {};
    bless $self, ref $class || $class;
}

=head3 dump( $name )

Dump options by $name, or that of $0 if $name is unspecified.
Returns HASH in scalar context or flattened HASH in list context.

=cut
sub dump
{
    my $self = shift;
    my %opt = %{ $self->{ @_ ? shift : $THIS } || {} };
    return wantarray ? %opt : \%opt;
}

=head3 set( %opt )

Set options specified by %opt for $0. Returns object.

=cut
sub set
{
    my ( $self, %opt ) = splice @_;
    map { $self->{$THIS}{$_} = $opt{$_} } keys %opt;
    return $self;
}

=head3 get( @option )

Invoke Getopt::Long to get @option, if any specified. Returns object.

Getopt::Long is configured through @CONF.

The leftover @ARGV size is asserted through $ARGC. @ARGV cannot be empty
if $ARGC is negative, otherwise size of @ARGV needs to equal $ARGC.

=cut
sub get
{
    my $self = shift;
    push @CONF, 'auto_help' unless grep /auto_help/, @CONF;
    Getopt::Long::Configure( @CONF );
    $self->assert() if ! Getopt::Long::GetOptions( $self->{$THIS}, @_ )
        || $ARGC < 0 && ! @ARGV || $ARGC > 0 && @ARGV != $ARGC;
    return $self;
}

=head3 assert( @option )

print help and exit, if any of @option is not defined.

=cut
sub assert
{
    my $self = shift;
    Pod::Usage::pod2usage( -input => $0, -output => \*STDERR, -verbose => 2 )
        if ! @_ || grep { ! defined $self->{$THIS}{$_} } @_;
    return $self;
}

=head3 macro( $path )

Replace $ROOT in $path if defined.

=cut
sub macro
{
    my ( $self, $path ) = splice @_;

    if ( $path && defined $ROOT )
    {
        $path =~ s/\$ROOT\b/$ROOT/g;
        $path =~ s/\$\{ROOT\}/$ROOT/g;

        $path =~ s/\$MYDanPATH\b/$PATH/g;
        $path =~ s/\$\{MYDanPATH\}/$PATH/g;
    }

    return $path;
};

sub save
{
    my ( $class, %save ) = @_;

    return unless defined $save{name} && $save{key};

    my $self = {};
    my $base = $save{base} || $RealBin; 
    my @conf =  map { 
        my $p = $_;
        map{ File::Spec->join( $base, $p, $_ ) }( $PRIVATE, $CONF )
    } qw( . .. ../.. ../../.. );
    return unless my ( $conf ) = $save{conf} ? $save{conf} : grep { -l $_ || -f $_ } @conf;

    my $error = "invalid config $conf";
    $conf = readlink $conf if -l $conf;
    confess "$error: not a regular file" unless -f $conf;
    
    my $data = eval { YAML::XS::LoadFile( $conf ) };
    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $self ne 'HASH';
    
    if( defined $save{value} )
    {
        $data->{$save{name}}{$save{key}} = $save{value};
    }
    else
    {
        delete $data->{$save{name}}{$save{key}};
    }
    eval { YAML::XS::DumpFile( $conf, $data ) };

    confess "save error: $@" if $@;
}

1;

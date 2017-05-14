=head1 NAME

DynGig::CLI::OpsDB - CLI for a simple operations database

=cut
package DynGig::CLI::OpsDB;

use warnings;
use strict;
use Carp;

use YAML::XS;
use File::Spec;
use IO::Select;
use Pod::Usage;
use Digest::MD5;
use Sys::Hostname;
use Getopt::Long qw( :config no_ignore_case );

use DynGig::Util::CLI;
use DynGig::Util::EZDB;
use DynGig::Util::Sysrw;
use DynGig::Range::String;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::OpsDB;

 DynGig::CLI::OpsDB->main
 (
     master => 'hostname',
     database => '/database/directory/path',
 );

=head1 SYNOPSIS

$exe B<--help>

$exe B<--range> range [B<--count> | B<--delete>] [B<--format> format]

$exe B<--Regex> range [B<--count> | B<--delete>] [B<--format> format]

[echo YAML |] $exe YAML [B<--count> | B<--delete>] [B<--format> format]

[echo YAML |] $exe YAML B<--update>

e.g.

To read help menu

 $exe --help

To display records of host001 to host004, in CSV form by name,colo,rack

 $exe -r host001~4 -f '"%s,%s,%s",name,colo,rack'

To display records that match /host00?/, in raw YAML form

 $exe -R 'host00?'

To display the records of hosts in area A, cab 6, in raw YAML form

 $exe '{area: A, rack: 6}'

To count the above records

 $exe '{area: A, rack: 6}' -c

To delete the above records

 $exe '{area: A, rack: 6}' -d

To add/update host008,

 $exe 'host008: {area: A, rack: 6, ..}' -u

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( master database );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help',"print help menu",
        'u|update','update database',
        'c|count','count',
        'd|delete','delete from database',
        'r|range=s','range of nodes',
        'R|Regex=s','pattern of nodes',
        'f|format=s','display format',
    );

    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", $menu->string(), "\n";
        return 0;
    }

    if ( $option{u} || $option{d} )
    {
        my %addr;
        my %host =
        ( 
            master => $option{master},
            local => Sys::Hostname::hostname()
        );

        if ( $host{local} ne $host{master} )
        {
            map { croak "Cannot resolve host '$host{$_}'.\n" unless
                $addr{$_} = gethostbyname( $host{$_} ) } keys %host;

            croak "Update must be made on master host '$host{master}'."
                if $addr{local} ne $addr{master};
        }
    }

    croak "poll: $!\n" unless my $select = IO::Select->new();

    my ( $buffer, $length );

    $select->add( *STDIN );

    map { $length = DynGig::Util::Sysrw->read( $_, $buffer ) }
        $select->can_read( 0.1 );

    @ARGV = ( $buffer ) if $length;

    Pod::Usage::pod2usage( %pod_param )
        unless @ARGV || $option{r} || $option{R};

    my @input = map { YAML::XS::Load $_ } @ARGV if @ARGV;
    my $error = "Invalid input. Operations aborted.\n";

    map { croak $error if ref $_ ne 'HASH' } @input;

    if ( $option{u} )                ## update
    {
        my %shard;

        for my $input ( @input )
        {
            while ( my ( $table, $input ) = each %$input )
            {
                croak $error if ref $input ne 'HASH';

                map { croak $error if ref $_ } values %$input;

                my $shard = $shard{table}{$table} = $class->_md5( $table );

                push @{ $shard{db}{$shard} }, $table;
            }
        }

        my %db = map
        {
            $_ => DynGig::Util::EZDB->new
            (
                File::Spec->join( $option{database}, $_ ),
                table => $shard{db}{$_}
            )
        } keys %{ $shard{db} };

        for my $input ( @input )
        {
            while ( my ( $table, $input ) = each %$input )
            {
                while ( my ( $key, $val ) = each %$input )
                {
                    $db{ $shard{table}{$table} }->set( $table, $key, $val );
                }
            }
        }

        return 0;
    }

    my %range = map { $_ => 1 }
        DynGig::Range::String->new( $option{r} )->list() if $option{r};

    my @hex = ( 0 .. 9, qw( A B C D E F ) );
    my $count = 0;

    for my $shard ( map { my $hex = $_; map { $_ . $hex } @hex } @hex )
    {
        my $database = File::Spec->join( $option{database}, $shard );
        my $db = DynGig::Util::EZDB->new( $database );
        my @table = $db->table();
        my %record;

        if ( $option{r} )                ## by range
        {
            map { $record{$_} = $db->dump( $_ ) if $range{$_} } @table;
        }
        elsif ( $option{R} )             ## by regex
        {
            map { $record{$_} = $db->dump( $_ ) if $_ =~ /$option{R}/ } @table;
        }
        else                             ## by query
        {
            for my $table ( @table )
            {
                my $record = $db->dump( $table );
        
                for my $query ( @input ) ## or->and
                {
                    map { next unless $record->{$_}
                        && $record->{$_} eq $query->{$_} } keys %$query;
    
                    $record{$table} = $record;
                    last;
                }
            }
        }
    
        next unless %record;
    
        if ( $option{c} )                ## count
        {
            $count += keys %record;
        }
        elsif ( $option{d} )             ## delete
        {
            $class->_dump( \%record );
    
            map { $db->drop( $_ ) } keys %record;
        }
        else                             ## search
        {
            $class->_dump( \%record, $option{f} );
        }
    }

    if ( $option{c} )
    {
        print "$count\n";
    }
    elsif ( $option{d} )
    {
        print STDERR "\nThe records above have been deleted.\n";
    }

    return 0;
}

sub _md5
{
    my ( $this, $table ) = @_;

    return uc substr Digest::MD5::md5_hex( $table ), -2;
}

sub _dump
{
    my ( $this, $record, $format ) = @_;

    if ( $format )
    {
        my @format = $format =~ /^\s*(".+?")\s*,\s*([^"]+)$/;
        my @field = split /\s*,\s*/, $format[1];

        $format = eval $format[0];

        for my $table ( sort keys %$record )
        {
            my $record = $record->{$table};

            $record->{name} = $table;

            printf $format,
                map { defined $record->{$_} ? $record->{$_} : '' } @field;

            print "\n";
        }
    }
    else
    {
        YAML::XS::DumpFile \*STDOUT, $record;
    }
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__

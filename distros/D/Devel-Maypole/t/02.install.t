#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::File;

use File::Temp();
use Path::Class();

use Devel::Maypole qw/ :install /;

my $tempdir = File::Temp::tempdir( CLEANUP => 1 );

$ENV{MAYPOLE_RESOURCES_INSTALL_PREFIX} = $tempdir;

# install

                                # for             from           set
lives_ok { install_templates  ( 'Devel::Maypole', 't/templates', 'test' ) } 'survived installing templates';
lives_ok { install_yaml_config( 'Devel::Maypole', 'config',      'test' ) } 'survived installing configs';
lives_ok { install_ddl        ( 'Devel::Maypole', 'sql/ddl',     'test' ) } 'survived installing ddl';
lives_ok { install_data       ( 'Devel::Maypole', 'sql/data',    'test' ) } 'survived installing data';


my %resources = ( templates => { dest   => [ ( $tempdir, 'templates', 'Devel/Maypole/test/custom' ) ],
                                 source => 't/templates/custom',
                                 },
              yaml_config    => { dest => [ ( $tempdir, 'yaml_config', 'Devel/Maypole/test' ) ],
                             source => 'config',
                             },
              ddl       => { dest => [ ( $tempdir, 'ddl', 'Devel/Maypole/test' ) ],
                             source => 'sql/ddl',
                             },
              data      => { dest => [ ( $tempdir, 'data', 'Devel/Maypole/test' ) ],
                             source => 'sql/data',
                             },
              );

foreach my $what ( keys %resources )
{
    my $source_dir  = Path::Class::Dir->new( $resources{ $what }->{source} );
    my $dest_dir    = Path::Class::Dir->new( '', map { split '/', $_ } @{ $resources{ $what }->{dest} } );
    
    while ( my $file = $source_dir->next ) 
    {
        next unless -f $file;
        next if $file =~ /^\./;
        
        my $dest_file = $dest_dir->file( $file->basename );
    
        file_exists_ok( $dest_file );
    }
}


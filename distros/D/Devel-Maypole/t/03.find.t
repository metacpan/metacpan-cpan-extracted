#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use Test::File;

use Path::Class();

use Devel::Maypole qw/ :find /;

my %resources = ( templates => { dest   => [ ( 'tmp', 'templates', 'Devel/Maypole/default' ) ],
                                 source => 't/templates',
                                 },
              yaml_config    => { dest => [ ( 'tmp', 'yaml_config', 'Devel/Maypole/default' ) ],
                             source => 'config',
                             },
              ddl       => { dest => [ ( 'tmp', 'ddl', 'Devel/Maypole/default' ) ],
                             source => 'sql/ddl',
                             },
              data      => { dest => [ ( 'tmp', 'data', 'Devel/Maypole/default' ) ],
                             source => 'sql/data',
                             },
              );


foreach my $what ( keys %resources )
{
    my $source_dir  = Path::Class::Dir->new( $resources{ $what }->{source} );
    #my $dest_dir    = Path::Class::Dir->new( '', map { split '/', $_ } @{ $resources{ $what }->{dest} } );
    
    # these were installed by Build.PL
    my $installed_to;
    
    lives_ok { $installed_to = find( $what, 'Devel::Maypole', 'default' ) } "survived find $what";
    
    next unless $installed_to;
    
    my $dest_dir = Path::Class::Dir->new( '', split '/', $installed_to );
    
    while ( my $file = $source_dir->next ) 
    {
        next unless -f $file;
        next if $file =~ /^\./;
        
        my $dest_file = $dest_dir->file( $file->basename );
    
        file_exists_ok( $dest_file );
    }
}
              










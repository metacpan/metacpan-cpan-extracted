
use strict;
use warnings;

use Test::More tests => 13; # 'no_plan';
use Test::Exception;

use Maypole::Plugin::Config::Apache;

{   # for testing complicated hash merging - MaypoleMasonx
    package Foo::Bar::Baz;
    sub new { bless { a => 'z' }, 'Foo::Bar::Baz' }
}

my %in = (
    # plain_strings
    MaypoleApplicationName   => "BeerDB Maypole App",
    MaypoleUriBase           => '/',
    MaypoleTemplateRoot      => '/home/blah/www/bleh/htdocs',
    MaypoleRowsPerPage       => 25,
    
    # multiple_plain_strings
    foo => [ qw( bar baz ) ],
    
    # single entry hash
    MaypoleSession => "args => {Directory => '/tmp/sessions/ltsidb2', LockDirectory => '/tmp/sessionlocks/ltsidb2'}",
    
    # merge PerlAddVars into a hashref value
    MaypoleSession2 => [ "args => { Directory     => '/tmp/sessions/ltsidb2' }",
                         "args => { LockDirectory => '/tmp/sessionlocks/ltsidb2' }",
                         ],
    
        
    # more complicated hash merge
    MaypoleMasonx => [ "comp_root  => [ [ factory => '/usr/local/www/maypole/factory' ] ]",
                       "comp_root  =>   [ library => '/usr/local/www/mason/lib' ]",
                       "data_dir   => '/home/ltsi/www/database/mdata'",
                       "in_package => 'LocalApps::LTSIFB'",
                       "plugins    => [ Foo::Bar::Baz->new ]",
                       "plugins    =>   Foo::Bar::Baz->new",
                       ],
    
    
    );

my @plain_strings = qw( MaypoleApplicationName MaypoleUriBase  MaypoleTemplateRoot MaypoleRowsPerPage );
my @multiple_plain_strings = qw( foo );
    
my %c;
    
while ( my ( $k, $v ) = each %in )
{
    my @v = ref( $v ) eq 'ARRAY' ? @$v : ( $v );
    
    # sanity
    if ( $k eq 'foo' )
    {
        is_deeply( \@v, $in{foo} );
    }
    
    $c{ $k } = Maypole::Plugin::Config::Apache::_fixup( $k, @v );
}

# 
# plain strings (PerlSetVar)
#
is( $c{$_}, $in{$_} ) for @plain_strings;

# 
# multiple values
#
is_deeply( $c{$_}, $in{$_} ) for @multiple_plain_strings;

#
# hash with just one entry
#
is_deeply( $c{MaypoleSession}, { args => { Directory => '/tmp/sessions/ltsidb2', 
                                           LockDirectory => '/tmp/sessionlocks/ltsidb2',
                                           },
                                 } );
                                 
#
# merge multiple PerAddVars into a single hashref
#
#warn Dumper( $c{MaypoleSession2} );
is_deeply( $c{MaypoleSession2}, { args => { Directory => '/tmp/sessions/ltsidb2', 
                                            LockDirectory => '/tmp/sessionlocks/ltsidb2',
                                            },
                                  } );
                                  
is_deeply( $c{MaypoleMasonx}, { comp_root  => [ [ factory => '/usr/local/www/maypole/factory' ],
                                                [ library => '/usr/local/www/mason/lib' ] 
                                                ],
                                data_dir   => '/home/ltsi/www/database/mdata',
                                in_package => 'LocalApps::LTSIFB',
                                plugins    => [ Foo::Bar::Baz->new, Foo::Bar::Baz->new ],
                                } );
                                
#use Data::Dumper;
#warn Dumper( $c{MaypoleMasonx} );

#
# bad multiple entries - one with =>, one without
#                                 
my $bad_multi = [ "fi => 'fo'",
                  "'foo', 'fum'",
                  ];

dies_ok   { Maypole::Plugin::Config::Apache::_fixup( 'bad_var', @$bad_multi ) };
throws_ok { Maypole::Plugin::Config::Apache::_fixup( 'bad_var', @$bad_multi ) } 
    qr/\Q'=>' present in some but not all values of bad_var/;


#
# bad Perl dies
#
my $bad_perl = "has => noquotes";
dies_ok   { Maypole::Plugin::Config::Apache::_fixup( 'bad_perl', $bad_perl ) };
throws_ok { Maypole::Plugin::Config::Apache::_fixup( 'bad_perl', $bad_perl ) } 
    qr/\QError extracting value for bad_perl: Bareword "noquotes" not allowed while "strict subs" in use/;




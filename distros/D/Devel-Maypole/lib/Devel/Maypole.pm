package Devel::Maypole;

use warnings;
use strict;
use Carp();

use UNIVERSAL::require;
use Maypole::Config;
use File::Temp;
use File::Slurp;
use File::Copy::Recursive;
use Path::Class();
use Data::Dumper;
use DBI;    
use Sysadm::Install();

use base qw/ Exporter /;
use vars qw/ $VERSION @EXPORT_OK %EXPORT_TAGS /;

$VERSION = '0.2';

@EXPORT_OK = qw/ database  application        run_standard_tests
                 install   install_templates  install_yaml_config     install_data    install_ddl 
                 find      find_templates     find_yaml_config        find_data       find_ddl
                 /;

%EXPORT_TAGS = ( test    => [ qw/ database application run_standard_tests / ],
                 install => [ qw/ install install_templates install_yaml_config install_data install_ddl / ],
                 find    => [ qw/ find find_templates find_yaml_config find_data find_ddl / ],
                 );

# these have to stick around until the script exits, at which point, they 
# will be automatically unlinked
my ( $APP_FILE, $DB_FILE );

=head1 NAME

Devel::Maypole - support utilities for developing the Maypole stack

=head1 SYNOPSIS

    # =================================================
    # In a test script:
    
    use Test::More tests => 42;
    
    use Devel::Maypole qw/ :test /;
    
    my ( $database, $application );
    
    BEGIN { 
    
        $ENV{MAYPOLE_CONFIG}    = 'config/beerdb.simple.yaml';
        $ENV{MAYPOLE_TEMPLATES} = 't/templates';
    
        $database = database( ddl  => 'sql/ddl/beerdb.simple.sql',
                              data => 'sql/data/beerdb.simple.sql',
                              );
        
        $application = application( plugins => [ qw( Config::YAML AutoUntaint Relationship ) ],
                                    );    
    }
    
    use Test::WWW::Mechanize::Maypole $application, $database;
    
    # ----- BEGIN TESTING -----
    
    # frontpage
    {   
    
        my $mech = Test::WWW::Mechanize::Maypole->new;
        $mech->get_ok("http://localhost/beerdb/");
        
        $mech->content_contains( 'This is the frontpage' );
        
        is($mech->ct, "text/html");
        is($mech->status, 200);
    }
    
    
    # =================================================
    # In an installation script:
    
    use Maypole::Devel qw/ :install /;
    
    # optionally suppress interactive questions:
    # $ENV{MAYPOLE_RESOURCES_INSTALL_PREFIX} = '/usr/local/maypole';
    
    install_templates( 'Maypole::Plugin::Foo', 'distribution-templates-dir/set1', 'set1' );
    
    install_ddl( 'Maypole::Plugin::Foo', 'distribution-sql-dir/ddl/basic', 'basic' );
    install_ddl( 'Maypole::Plugin::Foo', 'distribution-sql-dir/ddl/advanced', 'advanced' );
            

    # =================================================
    # Somewhere else:
    
    package My::App;
    use Devel::Maypole qw/ :find /;
        
    my $templates = find_templates( 'Maypole::Plugin::Foo', 'set1' );

    my $ddl_sql_dir = find_ddl( 'Maypole::Plugin::Foo', 'advanced' );
    

=head1 DESCRIPTION

Builds a database and a simple application driver, ready to use in test scripts for Maypole 
plugins and components. Provides functions for installing resources (SQL files, configurations, 
templates), and for discovering the directories these resources were installed to at a later date. 
    
=head1 EXPORTS

Nothing is exported by default. You can import individual functions, or groups of functions 
using these tags:

    tag         functions
    -----------------------------------------------------------
    :test       database application run_standard_tests
    :install    install install_templates install_yaml_config install_ddl install_data 
    :find       find    find_templates    find_yaml_config    find_ddl    find_data   

=head1 TESTING UTILITIES

=over 4

=item database

Builds and populates an SQLite database in a temporary file, and returns a DBI connection 
string to the database. 

Suitable SQL files will be (ASAP) included in the distribution to build a reasonably complex 
version of the beer database.

Returns a DBI connection string.

Options:

=over 4

=item ddl

Path to the SQL DDL (schema) file to use. A couple of suitable files are installed by this 
distribution - C<beerdb.default.sql> and C<beerdb.simple.sql>. 

=item data

Path to the SQL data file to use. A couple of suitable files are installed by this 
distribution - C<beerdb.default.sql> and C<beerdb.simple.sql>. 

=item unlink 

Set false to not unlink the generated database file. Default true (unlink when script exits).

=back

=cut

sub database
{
    my %args = @_;
    
    my $ddl  = $args{ddl}  || die 'need a DDL file';
    my $data = $args{data} || die 'need a data file';
    my $unlink  = defined $args{unlink} ? $args{unlink} : 1;
    
    $DB_FILE = File::Temp->new( TEMPLATE => 'MaypoleTestDB_XXXXX',
                                SUFFIX   => '.db',
                                UNLINK   => $unlink,
                                );
                                
    $DB_FILE->close; # or SQLite thinks it's locked

    my $driver = 'SQLite';
    
    eval { require DBD::SQLite } or do {
        warn "Error loading DBD::SQLite, trying DBD::SQLite2\n";
        eval {require DBD::SQLite2} ? $driver = 'SQLite2'
            : die "DBD::SQLite2 is not installed";
    };
    
    my $connect = "dbi:$driver:dbname=$DB_FILE";
    
    my $dbh = DBI->connect( $connect );
    
    my $ddl_sql  = read_file( $ddl );
    my $data_sql = read_file( $data );
    
    my $sql = $ddl_sql.';'.$data_sql;

    foreach my $statement ( split /;/, $sql ) 
    {
        $statement =~ s/\#.*$//mg;           # strip # comments
        $statement =~ s/auto_increment//g;
        next unless $statement =~ /\S/;
        eval { $dbh->do($statement) };
        die "$@: $statement" if $@;
    }
    
    return $connect;                                    
}


=item application

Builds a simple Maypole driver in a temporary file in the current directory. 

Returns the package name of the application, which will be C<MaypoleTestApp_XXXXX> 
where C<XXXXX> are random characters.

Options:

=over 4

=item plugins

Arrayref of plugin names, just as you would supply to C<use Maypole::Application>.

See C<Custom driver code> below.

=item config

Hashref of Maypole options, or a Maypole::Config object. See C<Configuration> below.

=item unlink 

Set false to not unlink the generated application file. Default true (unlink when script exits).

=back

=cut

sub application
{
    my ( %args ) = @_;
    
    my @plugins = @{ $args{plugins} || [] };
    my $config  = $args{config} || {};
    my $unlink  = defined $args{unlink} ? $args{unlink} : 1;

    $APP_FILE = File::Temp->new( TEMPLATE => 'MaypoleTestApp_XXXXX',
                                 SUFFIX   => '.pm',
                                 UNLINK   => $unlink,
                                 );
                                 
    my $filename = $APP_FILE->filename;
    
    ( my $package = $filename ) =~ s/\..+$//;
    
    if ( ref $config eq 'HASH' )
    {
        $config = Maypole::Config->new( %$config );
    }
    
    my $cfg_str = Data::Dumper->Dump( [$config], ['$config'] );
    
    my $plugins = @plugins ? "qw( @plugins )" : '';
    
    my $app_code = _application_template();
    
    $app_code =~ s/__APP_NAME__/$package/;
    $app_code =~ s/__PLUGINS__/$plugins/;
    $app_code =~ s/__CONFIG__/$cfg_str/;
    
    print $APP_FILE $app_code;
    
    $APP_FILE->close; # or else it can't be read later 
    
    return $package;
}

sub _application_template
{
return <<'';
package __APP_NAME__;
use strict;
use warnings;
use Maypole::Application __PLUGINS__;
my $config;
eval q~__CONFIG__~;
die $@ if $@;
__PACKAGE__->config( $config );
__PACKAGE__->setup;
1;

}

=item run_standard_tests( $application, $database, $templates )

A canned set of tests that should be runnable against most plugins. 

B<NOT YET IMPLEMENTED>.

=cut

sub run_standard_tests
{
    my ( $application, $database, $templates ) = @_;

    die "run_standard_tests() not implemented";

}

=back

=head2 Configuration

You can build up configuration data in your test script, either as a hashref or 
as a L<Maypole::Config> object, and supply that as the C<config> parameter to 
C<application()>. 

Alternatively, include L<Maypole::Plugin::Config::YAML> in the list of plugins, 
and set C<$ENV{MAYPOLE_CONFIG}> to the path to a config file. See the  
L<Maypole::Plugin::Config::YAML> docs for details.

This distribution includes a couple of canned config files, in the C<config> subdirectory. 

    $ENV{MAYPOLE_CONFIG} = 'path/to/config/beerdb.simple.yaml'; 
    $ENV{MAYPOLE_CONFIG} = 'path/to/config/beerdb.default.yaml'; 
    
You can considerably simplify your config by including L<Maypole::Plugin::AutoUntaint> 
in the list of plugins - the supplied config files assume this.

The supplied configs also assume L<Maypole::Plugin::Relationship> is included in the 
plugins. 

=head2 Custom driver code

If you need to add custom code to the application, you could put the code in 
a plugin, and supply the name of the plugin to C<plugins>.    
    
Alternatively, C<eval> code in your test script, e.g. from C<01.simple.t>:

    # For testing classmetadata
    eval <<CODE;
        sub $application\::Beer::classdata: Exported {};
        sub $application\::Beer::list_columns  { return qw/score name price style brewery url/};
    CODE

    die $@ if $@;
    
=head1 INSTALLATION SUPPORT    

=head2 install_* functions

Import these functions with the C<:install> tag. 

These functions are intended to be called from a command line script, preferably a C<Build.PL> script. 
They will interactively ask the user to confirm install locations, 
unless C<$ENV{MAYPOLE_RESOURCES_INSTALL_PREFIX}> is defined, in which case that location will be used 
as the root of the install location.

Returns the path in which the material was installed. You should store this in the config package for the 
module being installed, so that other packages can find your templates. In C<Build.PL>, you can say 

    use Devel::Maypole qw/:install/;
    
    my $cfg = $builder->config_data( 'templates' ) || {};
    
    $cfg->{set1} = install_templates( 'Maypole::Plugin::Foo', 'dist-templates-dir', 'set1' );
        
    $builder->config_data( templates => $cfg ); 
    
    # similarly for config files, databases etc.
    
The call to C<config_data> will cause L<Module::Build> to create and install the config package 
for you.

You can retrieve the install location directly from C<Maypole::Plugin::Foo::ConfigData>, 
or you can use the C<find_*> functions (see below), which will use 
C<Maypole::Plugin::Foo::ConfigData> under the hood.

On Unix-like systems, the default install root is C</usr/local/maypole/$what>, where C<$what> identifies 
the type of material (i.e. templates, yaml_config, ddl or data). 

On Windows, the default is C<C:/Program Files/Maypole/$what>. 

C<$for> should be the name of a package. This will be converted into a subdirectory, e.g. C<Maypole::Plugin::Foo> 
becomes C<Maypole/Plugin/Foo>. 

C<$from> is the relative path to the resource directory in your distribution, e.g. C<templates> 
or C<sql/ddl>. 

C<$set> is an optional subdirectory to install to. So if you say 

    install_templates( 'Maypole::Plugin::Foo', 'templates/set1', 'set1' )
    
the templates will be installed in C</usr/local/maypole/templates/Maypole/Plugin/Foo/set1>. 

C<$set> defaults to 'default'.


=over 4

=item install_templates( $for, $from, [ $set ] )

=item install_ddl( $for, $from, [ $set ] )

=item install_data( $for, $from, [ $set ] )

=item install_yaml_config( $for, $from, [ $set ] )

=item install( $what, $for, $from, [ $set ] )

The C<install_*> functions all delegate to C<install>, passing C<$what> as the first 
parameter. Use this function to install other types of material 
(e.g. C<install( 'images', 'Maypole::Plugin::Pretty', 'img/themes/sunny', 'sunny' )>), 
or for cycling through several types.

=back

=cut

sub install_templates   { install( 'templates',   @_ ) }
sub install_ddl         { install( 'ddl',         @_ ) }
sub install_data        { install( 'data',        @_ ) }
sub install_yaml_config { install( 'yaml_config', @_ ) }

sub install
{
    my ( $what, $for, $from, $to ) = @_;
    
    Sysadm::Install->import( qw/:all/ );
    
    $what or Carp::croak 'Need to know what type of thing to install';
    $for  || Carp::croak 'need a package name for installing templates';
    $from ||= ''; # unlikely
    $to   ||= 'default'; # unwise
    
    my ( $PREFIX, @alt_prefixes );
    
    if ( $^O eq 'MSWin32' )   
    {  
        $PREFIX  = 'C:/Program Files/Maypole';
        @alt_prefixes = ( 'C:/Program Files/Maypole2', 'C:/Program Files/Perl/Maypole', 
                            'C:/Program Files/Perl/Maypole2' );
    }
    else 
    {
        $PREFIX  = '/usr/local/maypole';
        @alt_prefixes = ( '/usr/local/maypole2', '/usr/lib/maypole', '/usr/lib/maypole2',
                          '/usr/local/lib/maypole','/usr/local/lib/maypole2', 
                          '/home/maypole', '/home/maypole2', 
                          '/usr/www/maypole', '/usr/www/maypole2', 
                          '/usr/local/www/maypole', '/usr/local/www/maypole2', 
                          );
    }
    
    my $prefix = $ENV{MAYPOLE_RESOURCES_INSTALL_PREFIX};
    
    my $no_install = "do not install";
    
    if ( ! $prefix )
    {
        my @prefix_opts = ( $PREFIX, @alt_prefixes, 'other', $no_install );
        
        my $question = 'Installation location:';
        
        $prefix = pick( $question, [ @prefix_opts ], 1 ); # default is #1
        
        $prefix = ask( $question, $PREFIX ) if $prefix eq 'other';
        
        return unless $prefix;
    }
    
    # Generally we'll be asking to install several types of resource, one after another, 
    # in the same script. This prevents repeat questions.
    $ENV{MAYPOLE_RESOURCES_INSTALL_PREFIX} = $prefix;
    
    # this must be outside the loop to catch 2nd and subsequent repeat
    return if $prefix eq $no_install; 
    
    $for =~ s|::|/|g;
    
    my $dest = Path::Class::Dir->new( '', map { split '/', $_ } $prefix, $what, $for, $to );
    
    File::Copy::Recursive::dircopy( $from, $dest->stringify ) || Carp::croak "nothing copied: $!";
    
    return $dest->stringify;
}

=head1 RESOURCE DISCOVERY

=head2 find_* functions

Import these functions with the C<:find> tag.

Each of these methods loads the appropriate C<*::ConfigData> package for the package C<$for>, 
and queries it for the location of the C<$set> set of material.

C<$set> defaults to 'default'.

    use Devel::Maypole qw/ :find /;
    
    my $templates_dir = find_templates( $for, $set );
    
    my $ddl_dir = find_ddl( $for, $set );
    
It is up to you to extract the list of files in the directory.
        
=over 4

=item find_templates( $for, [ $set ] )

=item find_ddl( $for, [ $set ] )

=item find_data( $for, [ $set ] )

=item find_yaml_config( $for, [ $set ] )

=item find( $what, $for, [ $set ] )

The C<find_*> functions all delegate to C<find>, passing C<$what> as the first 
parameter. Use this function to locate other types of material (see C<install()>), 
or for cycling through several types.

=back

=cut

sub find_templates   { find( 'templates',  @_ ) }
sub find_ddl         { find( 'ddl',        @_ ) }
sub find_data        { find( 'data',       @_ ) }
sub find_yaml_config { find( 'yaml_config',@_ ) }

sub find
{
    my ( $what, $for, $set ) = @_;
    
    $what || Carp::croak 'Need to know what type of thing to install';
    $for  || Carp::croak "Need a package name";
    $set  ||= 'default';

    my $config = "$for\::ConfigData";
    
    my $ok = $config->require;
     
    if ( ! $ok )
    {
        Carp::carp "Couldn't load configuration package for $config: $@";    
        return;
    }
    
    my $what_cfg = $config->config( $what ) || Carp::croak "No config data for '$what'";
    
    return $what_cfg->{ $set };
}


=head1 RESOURCES INSTALLED BY Devel::Maypole

These are installed under the resource root selected during installation.

=over 4

=item templates

    templates/default/*
    
=item DDL SQL

    ddl/default/beerdb.default.sql
    ddl/default/beerdb.simple.sql
    
=item data SQL
    
    data/default/beerdb.default.sql
    data/default/beerdb.simple.sql
    
=item configs

    yaml_config/default/beerdb.simple.yaml
    
=back    
    
=head1 Putting it all together

This is how you might start a test script in the distribution of a Maypole 
add-on. 

Include L<Devel::Maypole> in the requirements for your module. During 
its installation, the Devel::Maypole resource kit(s), as well as persistent config 
data recording the installation locations of these resources, will be set up. 

    # in a test script for Maypole::Plugin::Foo
    use Test::More tests => 42;
    use Devel::Maypole qw/ :test :find /;
    
    my ( $application, $database );
    
    BEGIN {
    
        my $mp_cfg      = find_yaml_config( 'Devel::Maypole', 'default' );
        my $templates   = find_templates  ( 'Devel::Maypole', 'default' );
        my $ddl         = find_ddl        ( 'Devel::Maypole', 'default' );
        my $data        = find_data       ( 'Devel::Maypole', 'default' );
    
        $ENV{MAYPOLE_CONFIG}    = "$mp_cfg/beerdb.simple.yaml";
        $ENV{MAYPOLE_TEMPLATES} = $templates;
    
        $database = database( ddl  => "$ddl/beerdb.simple.sql",
                              data => "$data/beerdb.simple.sql",
                              );
        
        $application = application( plugins => [ qw( Foo Config::YAML AutoUntaint Relationship ) ],
                                    );    
    }
    
    use Test::WWW::Mechanize::Maypole $application, $database;
    
    # run some canned tests from Devel::Maypole - not implemented yet...
    run_standard_tests( $application );       
    
    # now run some custom tests!
    
In time, more resource kits will be added (in addition to 'default' ), and/or more 
files will be added to the default resource kit, and canned sets of tests will be added.
    
=head1 TODO

Canned tests 

Complex schema, with sufficient data for paging. 

More template sets. 

Support for other RDBMS's (easy enough to implement, patches welcome).

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-maypole@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Maypole>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Devel::Maypole::Test

package Fake::Loader;

use strict;
use warnings;

#----------------------------------------------------------------------------
# Libraries

use Config::IniFiles;
use File::Basename;
use File::Copy;
use File::Path;
use IO::File;

use Module::Pluggable   search_path => ['Labyrinth::Plugin'];

# Required Core
use Labyrinth;
use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::Globals  qw(:all);
use Labyrinth::Mailer;
use Labyrinth::Plugins;
use Labyrinth::Request;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Writer;
use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Test Variables

my $config      = 't/_DBDIR/test-config.ini';
my $directory   = 't/_DBDIR';

#----------------------------------------------------------------------------
# Tests

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    return $self;
}

sub directory {
    return $directory;
}

sub prep {
    my ($self,@sql) = @_;
    $self->{error} = '';

    # prep test directories
    rmtree($directory);
    mkpath($directory) or ( $self->{error} = "cannot create test directory" && return 0 );

    for my $dir ('html','cgi-bin') {
        unless (copy_files("vhost/$dir","$directory/$dir")) {
            $self->{error} = "cannot create test files";
            return 0;
        }
    }

    mkpath("$directory/html/cache") or ( $self->{error} = "cannot create cache directory" && return 0 );

    # prep database
    eval "use Test::Database";
    if($@) {
        $self->{error} = "Unable to load Test::Database: $@";
        return 0;
    }

    my $td1 = Test::Database->handle( 'mysql' );
    unless($td1) {
        $self->{error} = "Unable to load  a test database instance";
        return 0;
    }

    create_mysql_databases($td1,@sql);

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td1->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %db_config = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    # prep config files
    unless( create_config(\%db_config) ) {
        $self->{error} = "Failed to create config file";
        return 0;
    }

    return 1;
}

sub cleanup {
    my ($self) = @_;

    # remove test directories
    rmtree($directory);

    # remove test database
    eval "use Test::Database";
    return 0    if($@);

    my $td1 = Test::Database->handle( 'mysql' );
    return 0    unless($td1);

    $td1->{driver}->drop_database($td1->name);
}

sub labyrinth {
    my ($self,@plugins) = @_;
    $self->{error} = '';

    eval {
        # configure labyrinth instance
        $self->{labyrinth} = Labyrinth->new;

        Labyrinth::Variables::init();   # initial standard variable values

        UnPublish();                    # Start a fresh slate
        LoadSettings($config);          # Load All Global Settings

        DBConnect();

        load_plugins( @plugins );
    };

    return 1    unless($@);
    $self->{error} = "Failed to load Labyrinth: $@";
    return 0;
}

sub action {
    my ($self,$action) = @_;
    $self->{error} = '';

    eval {
        # run plugin action
        $self->{labyrinth}->action($action);
    };

    return 1    unless($@);
    $self->{error} = "Failed to run action: $action: $@";
    return 0;
}

sub vars {
    my ($self) = @_;
    return \%tvars;
}

sub set_vars {
    my ($self,%hash) = @_;
    for my $name (keys %hash) {
        $tvars{$name} = $hash{$name}
    }
}

sub params {
    my ($self) = @_;
    return \%cgiparams;
}

sub set_params {
    my ($self,%hash) = @_;
    for my $name (keys %hash) {
        $cgiparams{$name} = $hash{$name}
    }
}

sub error {
    my ($self) = @_;
    return $self->{error};
}

#----------------------------------------------------------------------------
# Internal Functions

sub copy_files {
    my ($source_dir,$target_dir) = @_;

    return 0    unless($source_dir);

    my @dirs = ($source_dir);
    while(@dirs) {
        my $dir = shift @dirs;

        my @files = glob("$dir/*");

        for my $filename (@files) {
            my $source = $filename;
            if(-f $source) {
                my $target = $filename;
                $target =~ s/^$source_dir/$target_dir/;
                next    if(-f $target);

                mkpath( dirname($target) );
                if(-d dirname($target)) {
                    copy( $source, $target );
                } else {
                    return 0;
                }
            } elsif(-d $source) {
                push @dirs, $source;

            } else {
                return 0;
            }
        }
    }

    return 1;
}

sub create_config {
    my ($db_config) = @_;
    my $admin = 'barbie@cpan.org';

    # main config
    unlink $config if -f $config;

    my $dbcfg1 = join("\n", map { "$_=$db_config->{$_}" } grep { $db_config->{$_}} qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($config,'w+') or return 0;
    print $fh <<PRINT;
[PROJECT]
icode=testsite
iname=Test Site
administrator=$admin
mailhost=
cookiename=session
timeout=3600
autoguest=1
copyright=2002-2014 Barbie
lastpagereturn=0
minpasslen=6
maxpasslen=20

evalperl=1

[INTERNAL]
phrasebook=t/data/phrasebook.ini
logfile=$directory/html/cache/audit.log
loglevel=4
logclear=1

[HTTP]
webpath=
cgipath=/cgi-bin
realm=public
basedir=$directory
webdir=$directory/html
cgidir=$directory/cgi-bin

requests=$directory/cgi-bin/config/requests

; database configuration

[DATABASE]
$dbcfg1

[CMS]
htmltags=+img
maxpicwidth=500
randpicwidth=400
blank=images/blank.png

testing=0

PRINT

    $fh->close;
    return 1;
}

# this is primitive, but works :)

sub create_mysql_databases {
    my ($db1,@files) = @_;

    my (@statements);
    my $sql = '';

    for my $file (@files) {
#print STDERR "# file=$file\n";
        my $fh = IO::File->new($file,'r') or return 0;
        while(<$fh>) {
            next    if(/^--/);  # ignore comment lines
            s/;\s+--.*/;/;      # remove end of line comments
            s/\s+$//;           # remove trailing spaces
            next    unless($_);

#print STDERR "# line=$_\n";
            $sql .= ' ' . $_;
#print STDERR "# sql=$sql\n";
#exit;
            if($sql =~ /;$/) {
                $sql =~ s/;$//;
                push @statements, $sql;
                $sql = '';
            }
        }
        $fh->close;
    }

#print STDERR "# statements=".join("\n# ",@statements)."\n";
    dosql($db1,\@statements);
}

sub dosql {
    my ($db,$sql) = @_;

    for(@$sql) {
        #diag "SQL: [$db] $_";
        eval { $db->dbh->do($_); };
        if($@) {
            diag $@;
            return 1;
        }
    }

    return 0;
}

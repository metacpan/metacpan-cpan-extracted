package Games::Lacuna::Task::Storage;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
with qw(Games::Lacuna::Task::Role::Logger);

use Games::Lacuna::Task;

use DBI;
use Digest::MD5 qw(md5_hex);
use JSON qw();

our %LOCAL_CACHE;
our $JSON = JSON->new->pretty(0)->utf8(1)->indent(0);

has 'file' => (
    is              => 'ro',
    isa             => 'Path::Class::File',
    required        => 1,
    coerce          => 1,
);

has 'current_version' => (
    is              => 'rw',
    isa             => 'Num',
    lazy_build      => 1,
    required        => 1,
);

has 'latest_version' => (
    is              => 'ro',
    isa             => 'Num',
    default         => $Games::Lacuna::Task::VERSION,
    required        => 1,
);

has 'dbh' => (
    is              => 'ro',
    isa             => 'DBI::db',
    lazy_build      => 1,
);

sub _build_current_version {
    my ($self) = @_;
    
    my ($current_version) = $self->dbh->selectrow_array('SELECT value FROM meta WHERE key = ?',{},'database_version');
    $current_version ||= 2.00;
    return $current_version;
}

sub _build_dbh {
    my ($self) = @_;
    
    my $dbh;
    my $database_ok = 1;
    my $file = $self->file;
    
    # Touch database file if it does not exist
    unless (-e $file->stringify) {
        $database_ok = 0;
        
        $self->log('info',"Initializing storage file %s",$file->stringify);
        my $file_dir = $file->parent->stringify;
        unless (-e $file_dir) {
            mkdir($file_dir)
                or $self->abort('Could not create storage directory %s: %s',$file_dir,$!);
        }
        $file->touch
            or $self->abort('Could not create storage file %s: %s',$file->stringify,$!);
    }
    
    # Connect database
    {
        no warnings 'once';
        $dbh = DBI->connect("dbi:SQLite:dbname=$file","","",{ sqlite_unicode => 1 })
            or $self->abort('Could not connect to database: %s',$DBI::errstr);
    }
    
    # Set dbh
    $self->meta->get_attribute('dbh')->set_raw_value($self,$dbh);
    
    # Check database for meta table
    if ($database_ok) {
        ($database_ok) = $dbh->selectrow_array('SELECT COUNT(1) FROM sqlite_master WHERE type=? AND name = ?',{},'table','meta');
    }
    
    # Initialize database
    unless ($database_ok) {
        sleep 1;
        $self->initialize();
    
    # Upgrade existing database
    } else {
        $self->upgrade();
    }
    
    # Create distance function
    $dbh->func( 'distance_func', 4, \&Games::Lacuna::Task::Utils::distance, "create_function" );
    
    return $dbh;
}

sub initialize {
    my ($self) = @_;
    
    $self->log('info',"Initializing storage tables in %s",$self->file->stringify);

    my $dbh = $self->dbh;
    my $data_fh = *DATA;
    
    my $sql = '';
    while (my $line = <$data_fh>) {
        $sql .= $line;
        if ($sql =~ m/;/) {
            $dbh->do($sql)
                or $self->abort('Could not excecute sql %s: %s',$sql,$dbh->errstr);
            undef $sql;
        }
    }
    close DATA;
    
    # Set version
    $self->current_version($self->latest_version);
    $dbh->do('INSERT INTO meta (key,value) VALUES (?,?)',{},'database_version',$self->current_version);
}

sub upgrade {
    my ($self) = @_;
    
    return
        if $self->current_version == $self->latest_version;
    
    my $dbh = $self->dbh;
    
    $self->log('info',"Upgrading storage from version %.2f to %.2f",$self->current_version(),$self->latest_version);
    
    my @sql;
    
    if ($self->current_version() < 2.01) {
        $self->log('debug','Upgrade for 2.00->2.01');
        
        push(@sql,'ALTER TABLE star RENAME TO star_old');
        
        push(@sql,'CREATE TABLE IF NOT EXISTS star (
            id INTEGER NOT NULL PRIMARY KEY,
            x INTEGER NOT NULL,
            y INTEGER NOT NULL,
            name TEXT NOT NULL,
            zone TEXT NOT NULL,
            last_checked INTEGER,
            is_probed INTEGER,
            is_known INTEGER
        )');
        
        push(@sql,'INSERT INTO star (id,x,y,name,zone,last_checked,is_probed,is_known) SELECT id,x,y,name,zone,last_checked,probed,probed FROM star_old');
        
        push(@sql,'DROP TABLE star_old');
        
        push(@sql,'DELETE FROM cache');
    }

    if ($self->current_version() < 2.02) {
        $self->log('debug','Upgrade for 2.01->2.02');
        push(@sql,'ALTER TABLE empire ADD COLUMN alliance INTEGER');
        push(@sql,'ALTER TABLE empire ADD COLUMN colony_count INTEGER');
        push(@sql,'ALTER TABLE empire ADD COLUMN level INTEGER');
        push(@sql,'ALTER TABLE empire ADD COLUMN date_founded INTEGER');
        push(@sql,'ALTER TABLE empire ADD COLUMN affinity TEXT');
        push(@sql,'ALTER TABLE empire ADD COLUMN last_checked INTEGER');
    }
    
    if ($self->current_version() < 2.03) {
        $self->log('debug','Upgrade for 2.02->2.03');
        
        push(@sql,'ALTER TABLE body RENAME TO body_old');
        
        push(@sql,'CREATE TABLE IF NOT EXISTS body (
          id INTEGER NOT NULL PRIMARY KEY,
          star INTEGER NOT NULL,
          x INTEGER NOT NULL,
          y INTEGER NOT NULL,
          orbit INTEGER NOT NULL,
          size INTEGER NOT NULL,
          name TEXT NOT NULL,
          normalized_name TEXT NOT NULL,
          type TEXT NOT NULL,
          water INTEGER,
          ore TEXT,
          empire INTEGER,
          is_excavated INTEGER
        )');
        
        push(@sql,'INSERT INTO body (id,star,x,y,orbit,size,name,normalized_name,type,water,ore,empire) SELECT id,star,x,y,orbit,size,name,normalized_name,type,water,ore,empire FROM body_old');
        
        push(@sql,'DROP TABLE body_old');
    }
    
    if (scalar @sql) {
        foreach my $sql (@sql) {
            $dbh->do($sql)
                or $self->abort('Could not excecute sql %s: %s',$sql,$dbh->errstr);
        }
    }
    
    $self->current_version($self->latest_version);
    
    $dbh->do('INSERT OR REPLACE INTO meta (key,value) VALUES (?,?)',{},'database_version',$self->latest_version);
    
    return;
}

sub selectrow_array {
    my ($self,$sql,@bind) = @_;
    
    my $sth = $self->prepare($sql);
    $sth->execute(@bind)
        or return;
    
    my (@row) = $sth->fetchrow_array()
        and $sth->finish;
    
    return @row;
}

sub selectrow_hashref {
    my ($self,$sql,@bind) = @_;
    
    my $sth = $self->prepare($sql);
    $sth->execute(@bind)
        or return;
    
    my $row = $sth->fetchrow_hashref()
        and $sth->finish;
    
    return $row;
}

sub do {
    my ($self,$sql,@params) = @_;
    
    my $sql_log = $sql;
    $sql_log =~ s/\n/ /g;

    foreach my $element (@params) {
        if (ref $element) {
            $element = $JSON->encode($element);
        }
    }
    
    return $self->dbh->do($sql,{},@params)
        or $self->abort('Could not run SQL command "%s": %s',$sql_log,$self->dbh->errstr);
}

sub prepare {
    my ($self,$sql) = @_;
    
    my $sql_log = $sql;
    $sql_log =~ s/\n/ /g;
    
    return $self->dbh->prepare($sql)
        or $self->abort('Could not prepare SQL command "%s": %s',$sql_log,$self->dbh->errstr);
}

sub get_cache {
    my ($self,$key) = @_;
    
    return $LOCAL_CACHE{$key}->[0]
        if defined $LOCAL_CACHE{$key};
    
    my ($value,$valid_until) = $self
        ->selectrow_array(
            'SELECT value, valid_until FROM cache WHERE key = ?',
            $key
        );
    
    return
        if ! defined $value
        || $valid_until < time();
    
    return $JSON->decode($value);
}

sub set_cache {
    my ($self,%params) = @_;
    
    $params{max_age} ||= 3600;

    my $valid_until = $params{valid_until} || ($params{max_age} + time());
    my $key = $params{key};
    my $value = $JSON->encode($params{value});
    my $checksum = md5_hex($value);
    
    return
        if defined $LOCAL_CACHE{$key} 
        && $LOCAL_CACHE{$key}->[1] eq $checksum;
    
    $LOCAL_CACHE{$key} = [ $params{value},$checksum ];
    
#    # Check local write cache
#    my $checksum = $cache->checksum();
#    if (defined $LOCAL_CACHE{$key}) {
#        my $local_cache = $LOCAL_CACHE{$key};
#        return $cache
#            if $local_cache eq $checksum;
#    }
#    
#    $LOCAL_CACHE{$key} = $checksum;
    
    $self->do(
        'INSERT OR REPLACE INTO cache (key,value,valid_until,checksum) VALUES (?,?,?,?)',
        $key,
        $value,
        $valid_until,
        $checksum,
    );
    
    return;
}

sub clear_cache {
    my ($self,$key) = @_;
    
    delete $LOCAL_CACHE{$key};
    
    $self->do(
        'DELETE FROM cache WHERE key = ?',
        $key,
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__DATA__
DROP TABLE IF EXISTS star;

CREATE TABLE IF NOT EXISTS star (
  id INTEGER NOT NULL PRIMARY KEY,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  name TEXT NOT NULL,
  zone TEXT NOT NULL,
  last_checked INTEGER,
  is_probed INTEGER,
  is_known INTEGER
);

DROP TABLE IF EXISTS body;

CREATE TABLE IF NOT EXISTS body (
  id INTEGER NOT NULL PRIMARY KEY,
  star INTEGER NOT NULL,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  orbit INTEGER NOT NULL,
  size INTEGER NOT NULL,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  type TEXT NOT NULL,
  water INTEGER,
  ore TEXT,
  empire INTEGER,
  is_excavated INTEGER
);

CREATE INDEX IF NOT EXISTS body_star_index ON body(star);

DROP TABLE IF EXISTS empire;

CREATE TABLE IF NOT EXISTS empire (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  alignment TEXT NOT NULL,
  is_isolationist TEXT NOT NULL,
  alliance INTEGER,
  colony_count INTEGER,
  level INTEGER,
  date_founded INTEGER,
  affinity TEXT,
  last_checked INTEGER
);

DROP TABLE IF EXISTS cache;

CREATE TABLE IF NOT EXISTS cache ( 
  key TEXT NOT NULL PRIMARY KEY, 
  value TEXT NOT NULL, 
  valid_until INTEGER,
  checksum TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS meta ( 
  key TEXT NOT NULL PRIMARY KEY, 
  value TEXT NOT NULL
);

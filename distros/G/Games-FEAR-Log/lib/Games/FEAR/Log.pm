package Games::FEAR::Log;
{

use warnings;
use strict;

use Carp;
use DBI;
use File::Copy;
use File::Temp;

## Object Attributes ##

# objects of this class have the following attributes...
my %dbh_of;           # open database handle of type DBI
my %create_of;        # indicator of whether to create table if doesnt exist
my %table_of;         # main stats table in database
my %logfile_of;       # logfile of the source logfile
my %tempfile_of;      # temp file via File::Temp (only if truncate is false)
my %history_of;       # length of time before
my %truncate_of;      # indicator of whether to truncate logfile after analysis

## Object Methods ##

# class constructor, takes hashref of arguments
sub new {
  my ($class, $args) = @_;
  
  # bless a scalar to instantiate the new object...
  my $new_object = bless \do{my $anon_scalar}, $class;
  
  # temporary variable (to save on expensive hash accesses, etc)
  my $temp_arg;
  
  # if no hashref of arguments provided, croak with error
  if (ref $args ne 'HASH') {
    croak "missing hash reference of constructor arguments";
  }
  
  # if logfile argument doesnt exist or is undef
  if ( !exists $args->{'-logfile'} || !defined $args->{'-logfile'} ) {
    # set logfile and tempfile attributes as undef
    $logfile_of{ident $new_object} = undef;
    $tempfile_of{ident $new_object} = undef;
  }
  else {
    # if logfile is anything other than a scalar value, scalar ref, or glob ref
    $temp_arg = ref $args->{'-logfile'};
    if ($temp_arg ne 'SCALAR' && $temp_arg ne 'GLOB' && $temp_arg ne '') {
      # croak on invalid logfile
      croak "invalid logfile attribute, must be string, scalar ref, or filehandle ref";
    }
    
    # set logfile as attribute
    $logfile_of{ident $new_object} = $args->{'-logfile'};
    
    # set tempfile (File::Temp object) as attribute
    $tempfile_of{ident $new_object} = new File::Temp();
  }
  
  # if dbh doesnt exist or is undefined
  if ( !exists $args->{'-dbi'} || !defined $args->{'-dbi'} ) {
    # croak on missing db handle
    croak "missing or undefined dbi attribute"
  }
  
  # if anonymous hash of 3 elements (dsn, user, pass) is not provided
  my $dbh = $args->{'-dbi'};
  if( ref $dbh ne 'ARRAY' || $#{$dbh} != 2 ) {
    # croak on invalid arguments
    croak "invalid dbi attribute, must be an arrayref of dsn, username, and password";
  }
  
  # get database driver name from the dsn
  (undef,$temp_arg,undef) = split /\:/, $dbh->[0],3;
  
  # if support for this db driver not found in the %_QUERIES hash
  if ( ! exists $Games::FEAR::Log::_QUERIES{$temp_arg} ) {
    # croak with reason
    croak "database driver '$temp_arg' is not yet supported";
  }
  
  # create dbi connection
  $dbh = DBI->connect(
    $dbh->[0], $dbh->[1], $dbh->[2], # dsn, username, password
    { PrintError => 0, PrintWarn => 0, RaiseError => 1, AutoCommit => 0}
  ) or croak "could not connect to database: $DBI::errstr";
  
  # set dbi object as attribute
  $dbh_of{ident $new_object} = $dbh;
  
  # if create is not provided or undefined
  if ( ! exists $args->{'-create'} || ! defined $args->{'-create'} ) {
    # default to one (true)
    $args->{'-create'} = 1;
  }
  
  # if not true
  $temp_arg = $args->{'-create'};
  if (! $temp_arg ) {
    # set to zero (false)
    $temp_arg = 0;
  }
  
  # set create mode as attribute
  $create_of{ident $new_object} = $temp_arg;
  
  # if stats tablename doesnt exist or is undefined
  if ( ! exists $args->{'-table'} || ! defined $args->{'-table'} || $args->{'-table'} !~ m/\A[a-z0-9_]+\z/) {
    # croak on missing table name
    croak "missing, undefined, or invalid table attribute"
  }
  
  # test if stats table exists, trapping potential errors in an eval
  $temp_arg = $args->{'-table'};
  eval {
    # select with an always false WHERE clause, will return an empty but existing dataset
    my $query_ref = $dbh->selectall_arrayref( _build_query('test_exist',$temp_arg) );
  };
  
  # if eval failed
  if ($@ ne '') {
    # if table doesnt exist
    if ($@ =~ m/table .+ exist/imsx) { # mysql error is "table '<TABLENAME>' doesn't exist"
      
      # if indicated NOT to create table if it doesnt exist
      if (! $create_of{ident $new_object} ) {
        # croak with reason
        croak $@;
      }
      
      # create table (in an eval)
      eval {
        $dbh->do( _build_query('ddl',$temp_arg) ) or die $dbh->errstr;
        $dbh->commit;
      };
      # if create fails
      if($@ ne '') {
        # croak with reason
        croak "could not create stats table: $@";
      }
    }
    else {
      # croak with reason
      croak "could not access stats table: $@";
    }
  }
  
  # set stats table as attribute
  $table_of{ident $new_object} = $temp_arg;
  
  # if history doesnt exist or is undefined
  if ( ! exists $args->{'-history'} || ! defined $args->{'-history'} ) {
    # default to zero
    $args->{'-history'} = 0;
  }
  
  # if parsing of timespan returns undefined
  $temp_arg = _timespan_parse( $args->{'-history'} );
  if ( ! defined $temp_arg ) {
    # croak on invalid duration (not zero, not timespan as defined in the docs)
    croak "invalid history attribute, must be zero or valid duration (see docs)";
  }
  
  # set truncate mode as attribute
  $history_of{ident $new_object} = $temp_arg;
  
  # if truncate is not provided or undefined
  if ( ! exists $args->{'-truncate'} || ! defined $args->{'-truncate'}) {
    # default to zero (false)
    $args->{'-truncate'} = 0;
  }
  
  # if not zero (false)
  $temp_arg = $args->{'-truncate'};
  if ( $temp_arg != 0 ) {
    # set to one (true)
    $temp_arg = 1;
  }
  
  # set truncate mode as attribute
  $truncate_of{ident $new_object} = $temp_arg;
  
  return $new_object;
}

# load logfile and build data structure
sub process {
  my ($self) = @_;
  
  # if no logfile was defined
  if ( !defined $logfile_of{ident $self} ) {
    # croak with error
    croak "process method called without supplying a logfile";
  }
  
  # make local copies of relevant attributes to save some expensive hash accesses
  my $logfile = $logfile_of{ident $self};
  my $tempfile = $tempfile_of{ident $self};
  
  # put temp file into binary mode and seek to start of file
  binmode $tempfile;
  seek $tempfile, 0, 0;
  
  # if logfile attribute is a scalar reference
  if(ref $logfile eq 'SCALAR') {
    # assume it's a ref to the file *content*, and write to temp file
    print { $tempfile } $logfile;
  }
  # if logfile attribute is a filehandle reference
  elsif(ref $logfile eq 'GLOB') {
    # put into binary mode and seek to start of filehandle (just in case)
    binmode $logfile;
    seek $logfile, 0, 0;
    
    # copy directly from one filehandle to another
    if ( copy($logfile, $tempfile) != 1 ) {
      # croak if copy fails for any reason
      croak "copy of logfile failed: $!"
    }
  }
  # if logfile attribute is (presumably) scalar value
  else {
    # check that file actually exists in filesystem
    if (! -e $logfile) {
      croak "logfile '$logfile' does not exist"
    }
    
    # copy logfile overwriting temp file
    if ( copy($logfile, $tempfile) != 1 ) {
      # croak if copy fails for any reason
      croak "copy of logfile failed: $!"
    }
  }
  
  # if source log is to be truncated
  if ( $truncate_of{ident $self} == 1 ) {
    # if logfile is scalar reference
    if (ref $logfile eq 'SCALAR') {
      # truncate referenced scalar to an empty string
      ${$logfile} = "";
    }
    # if filehandle reference
    elsif (ref $logfile eq 'GLOB') {
      # truncate filehandle to zero bytes (trapping potential errors)
      my $return_val = 0;
      eval { $return_val = truncate $logfile, 0; };
      
      # if truncate failed on error, croak with eval error
      if ( $@ ne '' ) {
        croak "truncate failed: $@"
      }
      
      # otherwise, if truncate didnt return true, croak with error
      if (! $return_val) {
        croak "truncate failed: $!";
      }
    }
    # if (presumably) scalar value
    else {
      # open for destructive write, and immediately close
      open my $trunc_file, '>', $logfile or carp "couldnt open logfile for truncation: $!";
      close $trunc_file;
    }
  }
  
  # if non-zero history duration...
  my $duration = $history_of{ident $self};
  my $dbh = $dbh_of{ident $self};
  if ( $duration != 0 ) {
    # remove any expired history records
    eval {
      $dbh->do(
        _build_query('remove_expired',$table_of{ident $self}),
        undef,
        $duration
      ) or croak $dbh->errstr;
      $dbh->commit or croak $dbh->errstr;
    };
    
    # if delete failed
    if ( $@ ne '' ) {
      # croak with reason
      croak "deletion of outdated records failed: $@";
    }
  }
  
  # seek to start of file and turn off binary mode
  seek $tempfile, 0, 0;
  binmode $tempfile, ':crlf';
  
  # loop through temp file, line by line
  my(%session, $team);
  while( my $line = <$tempfile> )
  {
    # if start of a new map, reset team variable
    if ( $line =~ m/] \*+? Results for Map/i ) {
      $team = 0;
    }
    
    # if team entry found, set team
    if ( $line =~ m/] Team: Team (\d)/i ) {
      $team = $1;
    }
    
    # if player entry found, set timestamp, player, and uid
    if ( $line =~ m/\[(.+?)] Player: ([^ ]+) \(uid: (.+?)\)/i ) {
      $session{'timestamp'} = $1;
      $session{'player'} = $2;
      $session{'uid'} = $3;
      
      # adapt timestamp to a SQL-compatible date/time string
      $session{'timestamp'} =~ s/\A\w+ (\w+) (\d+) ([\d:]+) (\d+)\z/$4-$Games::FEAR::Log::_MONTHS{$1}-$2 $3/;
    }
    
    # for every stat found, set corresponding stat
    foreach my $stat ( 'score', 'kills', 'deaths', 'suicides', 'team kills' ) {
      if ( $line =~ m/] $stat: (\d+)/i ) {
        $session{$stat} = $1;
        last;
      }
    }
    
    # if final stat of an entry found...
    if( $line =~ m/] objective: (\d+)/i ) {
      # finalize session stats hash
      $session{'objective'} = $1;
      $session{'team'} = $team;
      
      # select to see if this record already exists
      my $count = 0;
      eval {
        ($count) = $dbh->selectrow_array(
          _build_query('test_dml', $table_of{ident $self}),
          $session{'timestamp'},
          $session{'uid'},
        ) or croak $dbh->errstr;
      };
      
      # if select indicates record doesnt exist
      if($count < 1) {
      
        # insert into database, trapping in an eval
        eval {
          $dbh->do(
            _build_query('dml', $table_of{ident $self}),
            $session{'timestamp'},
            $session{'uid'},
            $session{'player'},
            $session{'team'},
            $session{'score'},
            $session{'kills'},
            $session{'deaths'},
            $session{'teamkills'},
            $session{'suicides'},
            $session{'objective'}
          ) or croak $dbh->errstr;
        };
        
        # if error during insert
        if ($@ ne '') {
          # croak with reason
          croak "an error occurred inserting records: $@";
        }
      
      }

      # clear session hash
      %session = ();
    }
  }
  
  # commit changes made, trapping in an eval
  eval {
    $dbh->commit or croak $dbh->errstr;
  };
  
  # if error during commit
  if ($@ ne '') {
    # croak with reason
    croak "an error occurred committing database changes: $@";
  }
  
  # return true on success
  return 1;
}

sub get_uids {
  my $self = @_;
  
  # store dbh to save hash accesses
  my $dbh = $dbh_of{ident $self};
  
  # build uid column from SELECT into an array reference, trapping in an eval
  my $array_ref;
  eval {
    $array_ref = $dbh->selectcol_arrayref(
      _build_query('get_uids', $table_of{ident $self})
    );
  };
  
  # if error occurred during select
  if ( $@ ne '' ) {
    # croak with reason
    croak "listing of uids failed: $@";
  }
  
  # if nonfatal error indicated
  if ( defined $dbh->err ) {
    croak "listing of uids failed:  ", $dbh->errstr;
  }
  
  # return dereferenced array
  return @{$array_ref};
}

sub get_playernames {
  my $self = shift;
  my $uid = shift;
  
  # store dbh to save hash accesses
  my $dbh = $dbh_of{ident $self};
  
  # build player names for the given uid into an array reference, in order of commonality
  my $array_ref;
  eval {
    $array_ref = $dbh->selectcol_arrayref(
      _build_query('get_players', $table_of{ident $self}),
      undef,
      $uid
    );
  };
  
  # if error occurred during select
  if ( $@ ne '' ) {
    # croak with reason
    croak "listing of playernames failed: $@";
  }
  
  # if nonfatal error indicated
  if ( defined $dbh->err ) {
    croak "listing of playernames failed:  ", $dbh->errstr;
  }
  
  # return dereferenced array
  return @{$array_ref};
}

sub get_stats {
  my $self = shift;
  my $uid = shift;
  
  # store dbh to save hash accesses
  my $dbh = $dbh_of{ident $self};
  
  # build anonymous hash of averaged and totalled statistics
  my $hash_ref;
  eval {
    $hash_ref = $dbh->selectrow_hashref(
      _build_query('get_stats', $table_of{ident $self}),
      undef,
      $uid
    );
  };
  
  # if error occurred during select
  if ( $@ ne '' ) {
    # croak with reason
    croak "listing of stats failed: $@";
  }
  
  # if nonfatal error indicated
  if ( defined $dbh->err ) {
    croak "listing of stats failed:  ", $dbh->errstr;
  }
  
  # return hash reference
  return $hash_ref;
}

sub get_history {
  my $self = shift;
  my $uid = shift;
  
  # store dbh to save hash accesses
  my $dbh = $dbh_of{ident $self};
  
  # build anonymous hash of hashrefs of game records
  my $hash_ref;
  eval {
    $hash_ref = $dbh->selectall_hashref(
      _build_query('get_history', $table_of{ident $self}),
      'timestamp',
      undef,
      $uid
    );
  };
  
  # if error occurred during select
  if ( $@ ne '' ) {
    # croak with reason
    croak "listing of history failed: $@";
  }
  
  # if nonfatal error indicated
  if ( defined $dbh->err ) {
    croak "listing of history failed:  ", $dbh->errstr;
  }
  
  # return hash reference
  return $hash_ref;
}

sub get_game {
  my $self = shift;
  my $timestamp = shift;
  
  # store dbh to save hash accesses
  my $dbh = $dbh_of{ident $self};
  
  # build anonymous hash of hashrefs of game records
  my $hash_ref;
  eval {
    $hash_ref = $dbh->selectall_hashref(
      _build_query('get_game', $table_of{ident $self}),
      'uid',
      undef,
      $timestamp
    );
  };
  
  # if error occurred during select
  if ( $@ ne '' ) {
    # croak with reason
    croak "listing of games failed: $@";
  }
  
  # if nonfatal error indicated
  if ( defined $dbh->err ) {
    croak "listing of games failed:  ", $dbh->errstr;
  }
  
  # return hash reference
  return $hash_ref;
}

sub build_scoreboard {
  my $self = shift;
  
  my($offset,$length) = @_;
  
  # for each argument, use default if no value provided, or croak if invalid
  
  # offset to start resultset at
  $offset = 0 if ! defined $offset;
  croak "invalid offset, not a positive integer: '$offset'" if $offset !~ m/^[0-9]+$/;
  
  # number of records in resultset
  $length = 0 if ! defined $length;
  croak "invalid length, not a positive integer: '$length'" if $offset !~ m/^[0-9]+$/;
  
  # get local reference to db handle
  my $dbh = $dbh_of{ident $self};
  
  my $sth;
  if($length) {
    # limit
    $sth = $dbh->prepare(
      _build_query('build_scoreboard_limit', $table_of{ident $self}),
      undef,
      $length, $offset
    );
  }
  else {
    # no limit
    $sth = $dbh->prepare(
      _build_query('build_scoreboard', $table_of{ident $self})
    );
  }
  
  # retrieve resultset, trapping any errors in an eval
  my @rowset;
  eval {
    # execute prepared statement
    $sth->execute();
    
    # fetch rows as hashrefs, push to array
    my $row_ref;
    while( $row_ref = $sth->fetchrow_hashref ) {
      push @rowset, $row_ref;
    }
  };
  
  # get playernames for all, duplicating entries if multiple playernames found
  my @results;
  foreach my $row_ref (@rowset) {
    # 
    my @players = $self->get_playernames( $row_ref->{'uid'} );
    
    foreach my $player (@players) {
      $row_ref->{'player'} = $player;
      push(@results, $row_ref);
    }
    $row_ref = undef;
  }
  undef @rowset;
  
  return @results;
}

# class destructor
sub DESTROY {
  my $self = shift;
  
  # close created db handle
  $dbh_of{ident $self}->disconnect;
  
  # deallocate inside-out object attributes
  delete $dbh_of{ident $self};
  delete $create_of{ident $self};
  delete $logfile_of{ident $self};
  delete $history_of{ident $self};
  delete $table_of{ident $self};
  delete $tempfile_of{ident $self};
  delete $truncate_of{ident $self};
  
  return;
}

## Public subroutines ##

sub supported_dbds {
  # return database driver names with explicit support
  return keys(%Games::FEAR::Log::_QUERIES);
}

## Utility Subroutines ##

# takes a string representing a timespan (ex: "1M" is 1 month) and returns
# a representative number of seconds
sub _timespan_parse {
  my $span = shift;
  
  my $span_types = join '|', keys(%Games::FEAR::Log::_SPANS);
  if ($span =~ m/\A  \+? (\d+) ($span_types)  \z/xms) {
    return $1 * $Games::FEAR::Log::_SPANS{$2};
  }
  elsif ($span eq '0') {
    return 0;
  }
  else {
    return;
  }
  
}

sub _build_query {
  my $queryname = shift;
  my $tablename = shift;
  
  #if(exists $_QUERIES{ $dbd_of{ident $self} }->{$queryname}) {
    #return join $tablename, @{ $_QUERIES{ $dbd_of{ident $self} }->{$queryname} };
  if( exists $Games::FEAR::Log::_QUERIES{ 'mysql' }->{$queryname} ) {
    return join $tablename, @{ $Games::FEAR::Log::_QUERIES{ 'mysql' }->{$queryname} };
  }
}

## Utility Variables ##

# serial month to numeric month conversion table
my %_MONTH = (
  'jan' => '01',  'feb' => '02',  'mar' => '03',  'apr' => '04',
  'may' => '05',  'jun' => '06',  'jul' => '07',  'aug' => '08',
  'sep' => '09',  'oct' => '10',  'nov' => '11',  'dec' => '12',
);

# timespan format to second format conversion table
my %_SPANS = (
  's' =>  1,           # seconds
  'm' =>  60,          # minutes
  'h' =>  60*60,       # hours
  'd' =>  60*60*24,    # days
  'M' =>  60*60*24*30, # months (roughly, 30 days specifically)
  'y' =>  60*60*24*365 # years (roughly, 365 days specifically)
);

# declare hash to store SQL queries (for definitions, see near end of file)
my %_QUERIES;

# for DBD::mysql (MySQL)
$_QUERIES{'mysql'} = {
  'ddl' => [
    'CREATE TABLE `',
    '` (
  `gametime` bigint NOT NULL,
  `uid` varchar(255) NOT NULL,
  `player` varchar(255) NOT NULL,
  `team` int(11) UNSIGNED NOT NULL,
  `score` int(11) NOT NULL,
  `kills` int(11) UNSIGNED NOT NULL,
  `deaths` int(11) UNSIGNED NOT NULL,
  `teamkills` int(11) UNSIGNED NOT NULL,
  `suicides` int(11) UNSIGNED NOT NULL,
  `objective` int(11) UNSIGNED NOT NULL,
  PRIMARY KEY(`gametime`, `uid`)
)'
  ],
  'dml' => [
    'INSERT INTO `',
    '`
  (`gametime`, `uid`, `player`, `team`, `score`, `kills`, `deaths`, `teamkills`, `suicides`, `objective`)
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ],
  'test_dml' => [
    'SELECT COUNT(*) FROM `',
    '` WHERE `gametime` = ? AND `uid` = ?'
  ],
  'test_exist' => [
    'SELECT * FROM `',
    '` WHERE 1=0'
  ],
  'remove_expired' => [
    'DELETE FROM `',
    '` WHERE `gametime` < (UNIX_TIMESTAMP() - ?)'
  ],
  'get_uids' => [
    'SELECT DISTINCT `uid` FROM `',
    '` WHERE 1'
  ],
  'get_players' => [
    'SELECT `player`, COUNT(`player`) as `occurances` FROM `',
    '` WHERE `uid` = ? GROUP BY `player` ORDER BY `occurances` DESC'
  ],
  'get_stats' => [
    'SELECT COUNT(`gametime`) as `game_count`,
AVG(`score`) as `avg_score`, AVG(`kills`) as `avg_kills`,
AVG(`deaths`) as `avg_deaths`, AVG(`suicides`) as `avg_suicides`,
AVG(`teamkills`) as `avg_teamkills`, AVG(`objective`) as `avg_objective`,
SUM(`score`) as `tot_score`, SUM(`kills`) as `tot_kills`,
SUM(`deaths`) as `tot_deaths`, SUM(`suicides`) as `tot_suicides`,
SUM(`teamkills`) as `tot_teamkills`, SUM(`objective`) as `tot_objective`
FROM `',
    '` WHERE `uid` = ? LIMIT 1'
  ],
  'get_history' => [
    'SELECT `gametime`, `team`, `player`, `score`, `kills`, `deaths`, `teamkills`, `suicides`, `objective` FROM `',
    '` WHERE `uid` = ?'
  ],
  'get_game' => [
    'SELECT `uid`, `team`, `player`, `score`, `kills`, `deaths`, `teamkills`, `suicides`, `objective` FROM `',
    '` WHERE `gametime` = ?'
  ],
  'build_scoreboard' => [
    'SELECT `uid`,
ROUND(AVG(`score`)) as `avg_score`, ROUND(AVG(`kills`)) as `avg_kills`,
ROUND(AVG(`deaths`)) as `avg_deaths`, ROUND(AVG(`suicides`)) as `avg_suicides`,
ROUND(AVG(`teamkills`)) as `avg_teamkills`, ROUND(AVG(`objective`)) as `avg_objective`,
SUM(`score`) as `tot_score`, SUM(`kills`) as `tot_kills`,
SUM(`deaths`) as `tot_deaths`, SUM(`suicides`) as `tot_suicides`,
SUM(`teamkills`) as `tot_teamkills`, SUM(`objective`) as `tot_objective`
FROM `',
    '` GROUP BY `uid`'
  ],
  'build_scoreboard_limit' => [
    'SELECT `uid`,
ROUND(AVG(`score`)) as `avg_score`, ROUND(AVG(`kills`)) as `avg_kills`,
ROUND(AVG(`deaths`)) as `avg_deaths`, ROUND(AVG(`suicides`)) as `avg_suicides`,
ROUND(AVG(`teamkills`)) as `avg_teamkills`, ROUND(AVG(`objective`)) as `avg_objective`,
SUM(`score`) as `tot_score`, SUM(`kills`) as `tot_kills`,
SUM(`deaths`) as `tot_deaths`, SUM(`suicides`) as `tot_suicides`,
SUM(`teamkills`) as `tot_teamkills`, SUM(`objective`) as `tot_objective`
FROM `',
    '` GROUP BY `uid` LIMIT ? OFFSET ?'
  ],
};

# for DBD::pg (PostgreSQL)
$_QUERIES{'pg'} = {
  'ddl' => [
    'CREATE TABLE "',
    '"
(
   "gametime" integer NOT NULL, 
   "uid" varchar NOT NULL, 
   "player" varchar NOT NULL, 
   "team" integer NOT NULL, 
   "score" integer NOT NULL, 
   "kills" integer NOT NULL, 
   "deaths" integer NOT NULL, 
   "teamkills" integer NOT NULL, 
   "suicides" integer NOT NULL, 
   "objective" integer NOT NULL, 
   CONSTRAINT "PRIMARY" PRIMARY KEY ("gametime", "uid")
) WITHOUT OIDS'
  ],
  'dml' => [
    'INSERT INTO "',
    '"
  ("gametime", "uid", "player", "team", "score", "kills", "deaths", "teamkills", "suicides", "objective")
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ],
  'test_dml' => [
    'SELECT COUNT(*) FROM `',
    '` WHERE `gametime` = ? AND `uid` = ?'
  ],
  'test_exist' => [
    'SELECT * FROM "',
    '" WHERE 1=0'
  ],
  'remove_expired' => [
    'DELETE FROM "',
    '" WHERE "gametime" < (EXTRACT(EPOCH FROM TIMESTAMP WITH TIME ZONE NOW()) - ?)'
  ],
  'get_uids' => [
    'SELECT DISTINCT "uid" FROM "',
    '" WHERE 1'
  ],
  'get_players' => [
    'SELECT "player", COUNT("player") as "occurances" FROM "',
    '" WHERE "uid" = ? GROUP BY "player" ORDER BY "occurances" DESC'
  ],
  'get_stats' => [
    'SELECT COUNT("gametime") as "game_count",
AVG("score") as "avg_score", AVG("kills") as "avg_kills",
AVG("deaths") as "avg_deaths", AVG("suicides") as "avg_suicides",
AVG("teamkills") as "avg_teamkills", AVG("objective") as "avg_objective",
SUM("score") as "tot_score", SUM("kills") as "tot_kills",
SUM("deaths") as "tot_deaths", SUM("suicides") as "tot_suicides",
SUM("teamkills") as "tot_teamkills", SUM("objective") as "tot_objective"
FROM "',
    '" WHERE "uid" = ? LIMIT 1'
  ],
  'get_history' => [
    'SELECT "gametime", "team", "player", "score", "kills", "deaths", "teamkills", "suicides", "objective" FROM "',
    '" WHERE "uid" = ?'
  ],
  'get_game' => [
    'SELECT "uid", "team", "player", "score", "kills", "deaths", "teamkills", "suicides", "objective" FROM "',
    '" WHERE "gametime" = ?'
  ],
  'build_scoreboard' => [
    'SELECT "uid",
ROUND(AVG("score")) as "avg_score", ROUND(AVG("kills")) as "avg_kills",
ROUND(AVG("deaths")) as "avg_deaths", ROUND(AVG("suicides")) as "avg_suicides",
ROUND(AVG("teamkills")) as "avg_teamkills", ROUND(AVG("objective")) as "avg_objective",
SUM("score") as "tot_score", SUM("kills") as "tot_kills",
SUM("deaths") as "tot_deaths", SUM("suicides") as "tot_suicides",
SUM("teamkills") as "tot_teamkills", SUM("objective") as "tot_objective"
FROM "',
    '" GROUP BY "uid"'
  ],
  'build_scoreboard_limit' => [
    'SELECT "uid",
ROUND(AVG("score"),0) as "avg_score", ROUND(AVG("kills"),0) as "avg_kills",
ROUND(AVG("deaths"),0) as "avg_deaths", ROUND(AVG("suicides"),0) as "avg_suicides",
ROUND(AVG("teamkills"),0) as "avg_teamkills", ROUND(AVG("objective"),0) as "avg_objective",
SUM("score") as "tot_score", SUM("kills") as "tot_kills",
SUM("deaths") as "tot_deaths", SUM("suicides") as "tot_suicides",
SUM("teamkills") as "tot_teamkills", SUM("objective") as "tot_objective"
FROM "',
    '" GROUP BY "uid" LIMIT ? OFFSET ?'
  ],
};

=head1 NAME

Games::FEAR::Log - Log analysis tool for F.E.A.R. dedicated servers

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Games::FEAR::Log;
    
    # instantiate new object, passing a hash reference of options
    my $log_obj = Games::FEAR::Log->new( {
      # database information: a dsn, username, and password
      -dbi => [ 
                'DBI:mysql:database=scoreboard;host=localhost;port=3306',
                'scoreboard_admin',
                'scoreboard_password'
              ],
      # table to store info
      -table => 'deathmatch1',
      # create table if it doesnt exist
      -create => ,
      # full path to logfile
      -logfile => '/var/log/FEAR/mp_scores.log',
      # empty the source logfile after reading it
      -truncate => 1,
      # delete any records older than 30 days
      -history => '30d'
    } );
    
    # process log file, importing new entries
    $log_obj->process() or die 'processing failed';
    
    # get ID of first user
    my @uids = $log_obj->get_uids();
    
    # get playernames this user goes by
    my @names = $log_obj->get_playernames( $uid[0] );
    
    # get stats for this user
    my $stats = $log_obj->get_stats( $uid[0] );
    
    # get history for this user
    my $history = $log_obj->get_history( $uid[0] );
    my @gametimes = keys %{$history};
    
    # get information for a game played by said user
    my $game = $log_obj->get_game( $gametimes[0] );
    
    # get scoreboard-structured informatuon
    my @scores = build_scoreboard('player', 'asc');

=head1 DESCRIPTION

This module allows the parsing of a F.E.A.R. multiplayer server log into a
manageable database format, and provides an easy to use object-oriented
interface to access that information.  This information could then be used
to create a CGI scoreboard application, such as the one included in the
C</examples> directory.

The underlying system uses a SQL relational database to store and retrieve
game information.  Initially, this implimentation is built to use a MySQL or
PostgreSQL database, but I can add support for other database systems if
there is a demand.

Ideally, there could be two different 'pieces' to an application using this
module, an administrative interface to import new log entries into the
database, and a public interface to display and/or cross-reference already
imported information.

If performance is not a concern, however, it could be a one-piece
application where new entries are checked for and added every time the
interface is viewed.

=head1 METHODS

=head2 new()

Creates and returns a new object.  Takes a single argument, a hash reference
containing configuration options.  The available options are as follows:

=over

=item * C<-dbi>

An anonymous array of a DSN (data source name), username, and password for
connecting to the database. See the L<DBI|DBI> docs for an explanation and
syntax of a DSN.  An error will be thrown if this option is not found or
invalid.

    [ 'DBI:mysql:database=test;host=localhost', 'devuser', 'devpass' ]

=item * C<-table>

Name of the database table to use for this set of statistics.  If stats are
being kept for multiple game servers, each one should have its own seperate
table.  An error will be thrown if this option is not found or invalid.

=item * C<-create>

Indicate whether the given table should be created if it does not already
exist.  A true value creates the table if necessary, while a false value
throws an error if the table doesnt exist.  The default is to create the
table.

=item * C<-logfile>

Source of the log entries.  This is not a required parameter unless you
plan on calling the C<process> method.  If a scalar value is passed, it is
assumed to be a filename.  If a scalar reference is passed, it is assumed
to be the contents of the log, and will be dereferenced and processed.  If
a glob reference is passed, it is assumed to be an open filehandle to the
logfile (note that it should be opened for read I<and> write operations).

=item * C<-history>

Length of time to keep records, specified in a format similar to that used
by the L<CGI|CGI> module, with a numeric quantity followed by  a one-letter
unit indicator:

    86400s  # 1 day specified in seconds
    1440m   # 1 day specified in minutes
    24h     # 1 day specified in hours
    90d     # 3 months specified in days
    12M     # 1 year specified in months
    2y      # 2 years specified in years

The default is to keep them forever, and this can be specified by passing an empty or undefined scalar, or a value of zero.

=item * C<-truncate>

Indicate whether the source log should be truncated to zero bytes (and in
effect emptied).  This is useful if you are reading from a live log file
and don't want to waste resources reprocessing old log entries.  Note, of
course, that if a logfile is already locked by the server process, any
attempted writes to it will fail.  A non-zero value turns on log truncating,
and a zero value turns it off.  The default is off.

=back

=head2 process()

Truncates log file if the C<truncate> option is set to true, deletes expired
records if C<history> option is specified, and processes any new entries.
Returns 1 on success.  If a C<logfile> option is not specified, an error will
be thrown.

    $log_obj->process();

=head2 get_uids()

Returns an array of all unique UIDs found in the current database table.
See the L<JARGON|/JARGON> section for an explanation of UIDs in the FEAR
server logs.

    @uids = $log_obj->get_uids();

=head2 get_playernames(UID)

Returns an array of all unique playernames found for the given UID.  They
are ordered by frequency of use.

    @names = $log_obj->get_playernames($uid);

=head2 get_stats(UID)

Returns a hash reference containing averaged and totalled stats for the
given UID.  The data structure returned is as follows:

    {
      game_count    => $game_count,
      tot_score     => $tot_score,
      avg_score     => $avg_score,
      tot_kills     => $tot_kills,
      avg_kills     => $avg_kills,
      tot_deaths    => $tot_deaths,
      avg_deaths    => $avg_deaths,
      tot_suicides  => $tot_suicides,
      avg_suicides  => $avg_suicides,
      tot_teamkills => $tot_teamkills,
      avg_teamkills => $avg_teamkills,
      tot_objective => $tot_objective,
      avg_objective => $avg_objective,
    }

=head2 get_history(UID)

Returns a hashref of hashrefs of games played by the given UID, each
keyed to the game time.  Note that C<gametime> is a unix timestamp as
would be returned by the C<time()> builtin.  The data structure returned
is as follows:

    {
      $gametime => {
        gametime  => $gametime,
        team      => $team,
        player    => $player,
        score     => $score,
        kills     => $kills,
        deaths    => $deaths,
        teamkills => $teamkills,
        suicides  => $suicides,
        objective => $objective,
      },
    }

=head2 get_game(GAMETIME)

Returns a hashref of hashrefs of players in the game at the given game
time, each keyed to a UID.  Note that C<gametime> is a unix timestamp as
would be returned by the C<time()> builtin.  The data structure returned
is as follows:

    {
      $uid => {
        uid       => $uid,
        team      => $team,
        player    => $player,
        score     => $score,
        kills     => $kills,
        deaths    => $deaths,
        teamkills => $teamkills,
        suicides  => $suicides,
        objective => $objective,
      }
    }

=head2 build_scoreboard(OFFSET,LENGTH)

Returns an array of hashrefs ideal for displaying a summary scoreboard.
Takes two optional arguments:

=over

=item * OFFSET

How many records into the start of a resultset to begin retrieving results,
akin to a SQL I<OFFSET> clause.  The default is C<0>.

=item * LENGTH

How many records to retrieve from a resultset, akin to a SQL I<LIMIT> clause.
The default is C<0> which is interpreted as 'no limit'.

=back

The data structure returned is as follows:

    (
      {
        uid           => $uid,
        player        => $player,
        avg_score     => $avg_score,
        avg_kills     => $avg_kills,
        avg_deaths    => $avg_deaths,
        avg_suicides  => $avg_suicides,
        avg_teamkills => $avg_teamkills,
        avg_objective => $avg_objective,
        tot_score     => $tot_score,
        tot_kills     => $tot_kills,
        tot_deaths    => $tot_deaths,
        tot_suicides  => $tot_suicides,
        tot_teamkills => $tot_teamkills,
        tot_objective => $tot_objective,
      }
    )

=head2 DESTROY()

The class destructor that, when called, closes the database connection
and any open filehandles, and destroys the object.

=head1 FUNCTIONS

=head2 supported_dbds()

Returns a list of the currently supported DBI drivers.  This function
can be called from an instantiated object, or directly.

    # called from an object
    @drivers = $log_object->supported_dbds();
    
    # called directly from the module namespace
    @drivers = Games::FEAR::Log::supported_dbds();

=head1 JARGON

Here, a few of the terms used throughout this documentation are briefly
defined.

=head2 UID

The UID found in the FEAR multiplayer log is used to uniquely identify a
user.  It is calculated as a hexadecimal
MD5 hash of their CD key.  For example, the UID for a CD key of
C<ABCD-EFGH-IJKL-MNOP-QRST> would be C<f00eeddcb4a079de173b673a3d45fcfc>.

=head2 Player Name

The player name is, as it suggests, a name picked by the user and is how
they appear in-game.  It is not suitable for tracking statistics since it
can be changed at the user's discretion, so we use the UID for that purpose.

=head2 Game Time

The game time is a timestamp of precisely when a specific game ended.  By
matching up different players with the same game times, you can determine
the participants of any specific game.

=head1 DEPENDANCIES

L<Test::More|Test::More> - Used by the test suite during C<make test>

L<DBI|DBI> - Used for database connectivity

L<File::Copy|File::Copy> - Used to copy log during processing

L<File::Temp|File::Temp> - Used to create temp file during processing

=head1 AUTHOR

Evan Kaufman, C<< <evank at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-fear-log at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-FEAR-Log>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The fine folks at PerlMonks.org, always willing to lend a helping hand to a
struggling programmer.

=head1 COPYRIGHT

Copyright 2007 Evan Kaufman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

}
1; # End of Games::FEAR::Log

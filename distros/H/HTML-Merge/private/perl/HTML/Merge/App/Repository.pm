#####################################
package HTML::Merge::App::Repository;
#####################################

# Modules ########################### 

use strict;
use vars;

# My Modules ########################

# Functions #########################
#####################################
# Constructor
sub new 
{
	my ($class) = @_;

	my $self = {};

	bless $self, $class;
}
#####################################
# Init Repository DB
sub InitDatabase 
{	
	my ($self) = @_;

	# just a way to give also a non OO fill to it
	$self ||= __PACKAGE__->new();

	my $engine = HTML::Merge::Engine->CreateObject();
	my $dbh = $engine->SYS_DBH();
	
	$self->CreateTables($dbh);
}
#####################################
sub CreateTables
{
	my ($self,$dbh) = @_;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.
":'';	
	my $table="repository_t";
	# create the repository table
        my $ddl = <<DDL;	
CREATE TABLE ${db}$table (
  rid INTEGER PRIMARY KEY NOT NULL,
  template_id INTEGER ,
  field_parent_repository_id INTEGER default '0',
  field_name VARCHAR(50),
  fldtyp_code VARCHAR(6) default '1',
  note varchar(255),
  src VARCHAR(80),
  value VARCHAR(80),
  size INTEGER,
  maxlength INTEGER,
  width INTEGER,
  height INTEGER,
  class VARCHAR(25),
  fldsts_code VARCHAR(6) default '1',
  realm_id INTEGER default '0',
  arrangement INTEGER,
  onBlur VARCHAR(255),
  onClick VARCHAR(255),
  onDblClick VARCHAR(255),
  onChange VARCHAR(255),
  onMouseOver VARCHAR(255),
  onMouseMove VARCHAR(255),
  onMouseOut VARCHAR(255),
  field_data VARCHAR(255),
  pos_x INTEGER default '0',
  pos_y INTEGER default '0',
  background VARCHAR(10),
  border VARCHAR(25),
  pos_delta INTEGER default '50',
  status_code VARCHAR(6) default '2'
)
DDL
	print "Creating $table table...\n";
  	$dbh->do($ddl);

        $ddl = "CREATE INDEX x_${table}_fldsts ON ${db}${table} (fldsts_code)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_arrangment ON ${db}${table} (arrangement)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_status ON ${db}${table} (status_code)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_realm_id ON ${db}${table} (realm_id)";
  	$dbh->do($ddl);
        $ddl = "CREATE UNIQUE INDEX ux_${table}_template_id ON ${db}${table} (template_id,arrangement)";
  	$dbh->do($ddl);

	# create the language_matrix table
	$table="repository_language_matrix";
	print "Creating $table table...\n";
        $ddl = <<DDL;
CREATE TABLE ${db}$table (
  rid INTEGER PRIMARY KEY NOT NULL,
  repository_id INTEGER NOT NULL default '0',
  langug_code VARCHAR(6),
  caption VARCHAR(80)
)
DDL
  	$dbh->do($ddl);

        $ddl = "CREATE UNIQUE INDEX ux_${table} ON ${db}${table} (repository_id,langug_code)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_repos ON ${db}${table} (repository_id)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_language ON ${db}${table} (langug_code)";
  	$dbh->do($ddl);
        $ddl = "CREATE INDEX x_${table}_caption ON ${db}${table} (caption)";
  	$dbh->do($ddl);
}
#####################################
1;
#####################################

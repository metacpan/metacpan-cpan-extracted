package HPC::Runner::Command::Plugin::Logger::Sqlite::Deploy;

use Moose::Role;

has 'clean_db' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

sub deploy_schema {
    my $self = shift;

    if ( $self->clean_db ) {
        $self->deploy_schema_drop_tables;
    }
    $self->deploy_schema_create_tables;
}

sub deploy_schema_create_tables {
    my $self = shift;

    my $dbh = $self->schema->storage->dbh;
    ###Create Tables

    my $sql = <<EOF;

CREATE TABLE IF NOT EXISTS submission (
  submission_pi INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  project text,
  submission_meta text,
  total_processes integer NOT NULL,
  total_batches integet NOT NULL,
  submission_time text NOT NULL
);

EOF

    $dbh->do($sql);

    $sql = <<EOF;
CREATE TABLE IF NOT EXISTS jobs (
  job_pi INTEGER PRIMARY KEY NOT NULL,
  submission_fk integer NOT NULL,
  job_scheduler_id text,
  start_time text NOT NULL,
  exit_time text NOT NULL,
  duration text,
  jobs_meta text,
  job_name text,
  FOREIGN KEY (submission_fk) REFERENCES submission(submission_pi) ON DELETE NO ACTION ON UPDATE NO ACTION
);
EOF

    $dbh->do($sql);

    $sql = <<EOF;
CREATE INDEX IF NOT EXISTS jobs_idx_submission_id ON jobs (submission_fk);
EOF
    $dbh->do($sql);

    $sql = <<EOF;

CREATE TABLE IF NOT EXISTS tasks (
  task_pi INTEGER PRIMARY KEY NOT NULL,
  job_fk integer NOT NULL,
  pid integer NOT NULL,
  start_time text NOT NULL,
  exit_time text,
  duration text,
  exit_code integer,
  tasks_meta text,
  task_tags text,
  FOREIGN KEY (job_fk) REFERENCES jobs(job_pi) ON DELETE NO ACTION ON UPDATE NO ACTION
);
EOF

    $dbh->do($sql);

    $sql = <<EOF;
CREATE INDEX IF NOT EXISTS tasks_idx_job_pi ON tasks (job_fk);
EOF

    $dbh->do($sql);
}

sub deploy_schema_drop_tables {
    my $self = shift;

    my $dbh      = $self->schema->storage->dbh;

    print "We are cleaning the db!\n" if $self->clean_db;

### Drop Tables
    my $sql = <<'EOF';
--
-- Table: submission
--
DROP TABLE IF EXISTS submission;
EOF

    $dbh->do($sql) if $self->clean_db;

    $sql = <<EOF;
--
-- Table: jobs
--
DROP TABLE IF EXISTS jobs;
EOF

    $dbh->do($sql) if $self->clean_db;

    $sql = <<EOF;
--
-- Table: tasks
--
DROP TABLE IF EXISTS tasks;
EOF

    $dbh->do($sql) if $self->clean_db;
}

1;

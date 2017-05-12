package Jonk::Worker;
use strict;
use warnings;
use Carp ();
use Try::Tiny;

sub new {
    my ($class, $dbh, $opts) = @_;

    unless ($dbh) {
        Carp::croak('missing job queue database handle.');
    }

    my $table_name = ($opts->{table_name}||'job');
    bless {
        dbh              => $dbh,
        lookup_job_query => sprintf('SELECT * FROM %s WHERE id = ?', $table_name),
        find_job_query   => sprintf('SELECT * FROM %s WHERE func IN (%s) ORDER BY id LIMIT %s',
                             $table_name,
                             join(', ', map { "'$_'" } @{$opts->{functions}}),
                             ($opts->{job_find_size}||50),
                         ),
        dequeue_query    => sprintf('DELETE FROM %s WHERE id = ?', ($opts->{table_name}||'job')),
        _errstr          => undef,
    }, $class;
}

sub errstr {$_[0]->{_errstr}}

sub dequeue {
    my ($self, $job_id) = @_;

    my $job;
    try {
        $self->{_errstr} = undef;
        local $self->{dbh}->{RaiseError} = 1;
        local $self->{dbh}->{PrintError} = 0;

        my $sth;
        if ($job_id) {
            $sth = $self->{dbh}->prepare_cached($self->{lookup_job_query});
            $sth->execute($job_id);
        } else {
            $sth = $self->{dbh}->prepare_cached($self->{find_job_query});
            $sth->execute();
        }

        while (my $row = $sth->fetchrow_hashref) {
            my $del_sth = $self->{dbh}->prepare_cached($self->{dequeue_query});
            $del_sth->execute($row->{id});
            $del_sth->finish;

            if ($del_sth->rows) {
                $job = $row;
                last;
            }
        }

        $sth->finish;
    } catch {
        $self->{_errstr} = "can't get job from job queue database: $_";
    };

    $job;
}

1;
__END__

=head1 NAME

Jonk::Worker - get a job data class.

=head1 SYNOPSIS

    use DBI; 
    use Jonk::Worker;
    
    my $dbh = DBI->connect(...);
    my $jonk = Jonk::Worker->new($dbh, {functions => ['MyWorker']});
    my $job = $jonk->dequeue;
    print $job->{func}; # MyWorker
    print $job->{arg};  # arg

=head1 METHODS

=head2 my $jonk = Jonk::Worker->new($dbh, $options);

Creates a new Jonk object, and returns the object.

$options is an optional settings.

=over 4

=item * $dbh

$dbh is database handle.

=item * $options->{functions}

Key word of job which this Jonk instance looks for.

=item * $options->{table_name}

specific job table name.

Default job table name is `job`.

=item * $options->{job_find_size}

specific lookup job record size.

Default 50.

=back

=head2 my $job_hash_ref = $jonk->dequeue($job_id);

dequeue a job from a database.

returns job hashref data.

Please do deserialize if it is necessary. 

=over 4

=item * $job_id (optional)

lookup specific $job_id's job.

=back

=head2 $jonk->errstr;

get most recent error infomation.

=head1 ERROR HANDLING

  my $job = $jonk->dequeue;
  if ($jonk->errstr) {
      die $jonk->errstr;
  }

=cut


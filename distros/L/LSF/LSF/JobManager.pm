package LSF::Manager; $VERSION = 0.11;

use LSF::Job;
use LSF::JobInfo;

sub import{
    # nothing here yet.
}

# create a new manager object. Store default parameters that will
# be used each time submit is called
sub new{
    my($type,@params) = @_;
    my $class = ref($type) || $type || "LSF::JobManager";
    return bless {-params => \@params}, $class;
}

# submit the command line to LSF. Any new parameters are used in 
# addition to those parameters passed to new and override them.
sub submit{
    my $this = shift;
    my($cmd,@params);
    if( @_ == 1 ){
        $cmd = shift;
    }else{
        $cmd = pop;
        @params = @_;
    }
    my @new_params = new_flags( [ $this->params ], \@params );
    my $job = LSF::Job->submit(@new_params, $cmd);
    $this->{-jobs}->{"$job"} = $job if $job;
    return $job;
}

# wait for all the submitted LSF jobs in a blocking manner
# achieved by submitting a job with the -I flag (stay connected to 
# the terminal) and a dependancy expression that tests that all
# the previously submitted LSF jobs have ended (any exit status)
sub wait_all_children{
    my ($this) = @_;
    my @jobs = $this->jobs;
    unless(@jobs){
        warn "No LSF::Job's in this LSF::Manager";
        return;
    }
    for(@jobs){
        $dependancy .= "ended($_)&&";
        $jobs .= "$_ ";
    }
    $dependancy =~ s/\&\&$//;
    $jobs =~ s/ $//;
    my $job = $this->submit('-I',-w=>$dependancy,"echo waiting for $jobs");
    delete $this->{-jobs}->{"$job"} if $job;
    return;
}

# return an array of the parameters submitted to new
sub params{
    my $this = shift;
    return @{ $this->{-params } };
}

# return an array of the lsf jobs submitted to this point.
sub jobs{
    my $this = shift;
    return values %{ $this->{-jobs} };
}

# poll LSF to find the status of the submitted jobs. It accepts an
# array of LSF status flags (eg. DONE, EXIT, PEND etc. )
# It would be inefficient to wait for all children with this method
# but it can be used to determine which children exited with a non 
# zero value
sub jobs_with_status{
    my ($this,@status) = @_;
    $status[0] = 'EXIT' unless @status;
    my @jobs = $this->jobs;
    my @returned_jobs;
    for my $job (@jobs){
        my $info = $job->info;
        if( grep { $info->{Status} eq $_ } @status ){
            push(@returned_jobs,$job);
        }
    }
    return @returned_jobs;
}

# internal sub to parse a facile command line of flags 
# for name=value pairs
sub parse_flags{
    my @defaults = @_;
    my %hash;
    while(local $_ = shift @defaults){
        if(/^(-\w)(.*)/){
            my($flag,$value) = ($1,$2);
            if($value ne ''){
                $hash{$flag} = $value;
            }elsif($defaults[0] !~ /^-\w/){
                $hash{$flag} = shift @defaults;
            }else{
                $hash{$flag} = undef;
            }
        }
    }
    return ( %hash );
}

# internal routine to allow new flags to override old ones
sub new_flags{
    my @defaults = @{ $_[0] };
    my @new = @{ $_[1] };
    my %defaults = parse_flags(@defaults);
    my %new = parse_flags(@new);
    my %hash = ( %defaults, %new );
    my @returned;
    while( my($key,$val) = each %hash ){
        push @returned, $key;
        push @returned, $val if defined $val;
    }
    return @returned;
}

1;

__END__


=head1 NAME

LSF::JobManager - submit and wait for a set of LSF Jobs

=head1 SYNOPSIS

    use LSF PRINT => 1;
    use LSF::JobManager;

    my $m = LSF::JobManager->new(-q=>'small');

    my $job = $m->submit("echo hello");
    $m->submit("echo world");
    
    for my $job ($m->jobs){
        $job->top;
    }
    
    $m->wait_all_children;
    print "All children have completed!\n";

    for ($m->jobs_with_status('EXIT') ){
        print "Job with id $_ exited non zero\n";
    }

=head1 DESCRIPTION

C<LSF::JobManager> provides a simple mechanism to submit a set of command lines
to the LSF Batch system and then wait for them all to finish in a blocking
(efficient) manner. Additionally, the LSF Batch system can be polled for jobs of
particular status and those jobs are returned as LSF::Job objects; This is an 
inefficient way to wait for all jobs to complete but can be used to determine 
which jobs have a particular status.

=head1 CONSTRUCTOR

=over 4

=item new ( [ ARGS ] )

$manager = LSF::JobManager->new(-q=>'small'
                               ,-m=>'mymachine');

Creates a new C<LSF::JobManager> object.

Any parameters are used as defaults passed to the submit method.

=back

=head1 METHODS

=over

=item $manager->submit( [ [ ARGS ] ], [CMD] )

Submits a command line to LSF. This is a wrapper around the LSF::Job->submit
call. The required argument is the command line to submit. Optional arguments
override the defaults given to C<new>. The submitted LSF::Job object is returned
on success, otherwise undef is returned, $? and $@ set. See C<LSF::Job>

=item $manager->wait_all_children()

Waits for all previously submitted LSF Jobs to complete in a blocking manner

=item $manager->jobs_with_status( [ [ STATUS_FLAGS ] ] )

Returns an array of jobs matching the given status flags (see LSF documentation)
The default flag is 'EXIT', returning an array of LSF::Job objects representing
command lines that exited non zero.

=item $manager->params()

Returns an array of the parameters that were passed to new

=item $manager->jobs()

Returns an array of the submitted LSF::Job objects.

=head1 HISTORY

The LSF::Batch module on cpan didn't compile easily on all platforms i wanted.
The LSF API didn't seem very perlish either. As a quick fix I knocked these
modules together which wrap the LSF command line interface. It was enough for
my simple usage. Hopefully they work in a much more perly manner.

=head1 AUTHOR

Mark Southern (mark_southern@merck.com)

=head1 COPYRIGHT

Copyright (c) 2002, Merck & Co. Inc. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut

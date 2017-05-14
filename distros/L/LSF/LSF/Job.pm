package LSF::Job; $VERSION = "0.1";

use Carp;
# sugar so that we can use job id's in strings
use overload '""' => sub{ $_[0]->{-id} };
use System2;
use LSF::JobInfo;

our @ISA = qw( LSF );
our $PRINT = 0;

sub import{
    my $self = shift;
    my %params = @_;
    $PRINT = $params{PRINT} if exists $params{PRINT};
}

sub new{
    my($type, $id) = @_;
    my $class = ref($type) || $type || "LSF::Job";
    unless( $id =~ /^\d+$/ ){
        carp "Invalid Job <$id>\n";
        return undef;
    }
    return bless {-id => $id}, $class;
}

sub id{ $_[0]->{-id} }

sub submit{
    my ($self,@params) = @_;
    my($ERR,$OUT) = system2('bsub',@params); # bsub swaps stdout/stderr
    if($?){
        $@ = $ERR;
        carp $@ if $self->print;
        return undef;
    }
    print $OUT if $self->print;
    $OUT =~ /Job <(\d+)>/;
    if( ref($self) ){
        $self->{-id} = $1;
        return $self;
    }
    else{
        my $new = $self->new($1);
        return $new;
    }
}

sub switch{ my $self = shift; $self->do_it('bswitch',@_, $self->id()) }

sub delete{ my $self = shift; $self->do_it('bdel',   @_, $self->id()) }

sub kill  { my $self = shift; $self->do_it('bkill',  @_, $self->id()) }

sub stop  { my $self = shift; $self->do_it('bstop',  @_, $self->id()) }

sub modify{ my $self = shift; $self->do_it('bmod',   @_, $self->id()) }

sub top   { my $self = shift; $self->do_it('btop',   @_, $self->id()) }

sub bottom{ my $self = shift; $self->do_it('bbot',   @_, $self->id()) }

sub info  { my @arr = LSF::JobInfo->new($_[0]->id()); $arr[0] }

1;

__END__

=head1 NAME

LSF::Job - create and manipulate LSF jobs

=head1 SYNOPSIS

use LSF::Job;

use LSF::Job PRINT => 1;

$job = LSF::Job->new(123456);

...

$job = LSF::Job->submit(-q => 'default'
                       ,-o => '/dev/null'
                       ,"echo hello");

$job2 = LSF::Job->submit(-q => 'default'
                        ,-o => '/home/logs/output.txt'
                        ,"echo world!");

$job2->modify(-w => "done($job)" );

$job2->del(-n => 1);

...

$job->top();

$job->bottom();

... etc ...

=head1 DESCRIPTION

C<LSF::Job> is a wrapper arround the LSF b* commands used to submit and
manipulate jobs. for a description of how the LSF commands work see the 
man pages of:

    bsub bswitch bdel bkill bstop bmod btop bbot

=head1 CONSTRUCTOR

=over 4

=item new ( [NUM] )

$job = LSF::Job->new(123456);

Creates a new C<LSF::Job> object.

Required argument is a LSF jobid. This does not *have* to exist in the system
but would probably be a good idea!

=item submit ( [ [ARGS] ], [COMMAND_STRING] )

$job = LSF::Job->submit(-q => 'default'
                       ,-o => '/dev/null'
                       ,"echo hello");

Creates a new C<LSF::Job> object.

Arguments are the LSF parameters normally passed to 'bsub'.

Required parameter is the command line (as a string) that you want to execute.

=back

=head1 CLASS METHODS

=over

=item LSF::Job->print( [ [ TRUE or FALSE ] ] )

Controls whether or not the LSF command line output is printed. The default is
OFF. When called with no arguments returns the current print status.

=back

=head1 METHODS

=over

=item $job->id

C<id> returns the jobid of the LSF Job. The object used in string context also
gives the same result leading to some interesting possibilities when building
up job interdependencies

=item $job->switch( [ARGS] )

Switches the LSF job between LSF queues. See the bswitch man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->delete( [ARGS] )

Deletes the LSF job from the system. See the bdel man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->kill

Kills the LSF job. See the bkill man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->stop

Stops the LSF job. See the bstop man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->modify( [ARGS] )

Modifies the LSF job. See the bmod man page.
Since the objects are overloaded to return the job id when used in string 
context this allows easy build up of job dependancies e.g.
Returns 1 on success, 0 on failure. Sets $? and $@;

$job3->modify(-w => "done($job1) && done($job2)" );

=item $job->top

Moves the LSF job to the top of its queue. See the btop man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->bottom

Moves the LSF job to the bottom of its queue. See the bbot man page.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->info

Returns a LSF::JobInfo object with information about the LSF job. 
See the LSF::JobInfo perldoc page.

=back

=head1 SEE ALSO

L<LSF>,
L<LSF::JobInfo>,
L<bsub>,
L<bswitch>,
L<bdel>,
L<bkill>,
L<bstop>,
L<bmod>,
L<btop>,
L<bbot>

=head1 BUGS

Please report them.

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
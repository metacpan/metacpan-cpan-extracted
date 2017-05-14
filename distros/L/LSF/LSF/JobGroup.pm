package LSF::JobGroup; $VERSION = "0.1";

use Carp;
use LSF;
use LSF::Job;
use System2;
use overload '""' => sub{ $_[0]->{-name} };

our @ISA = qw( LSF );
our $PRINT = 0;

sub import{
    my $self = shift;
    my %params = @_;
    $PRINT = $params{PRINT} if exists $params{PRINT};
}

sub new{
    my($type,$name) = @_;
    my $class = ref($type) || $type || "LSF::JobGroup";
    unless( $name ){
        carp "Invalid group name <$name>\n";
        return undef;
    }
    return bless { -name => $name }, $class;
}

sub exists{
    my($self) = @_;
    return 1 if( ! $self->add() && $@ =~ /Group exists/i );
    $self->delete();
    return 0;
}

sub delete  { my $self = shift; $self->do_it('bgdel', @_,$self->{-name}) }

sub add     { my $self = shift; $self->do_it('bgadd', @_,$self->{-name}) }

sub hold    { my $self = shift; $self->do_it('bghold',@_,$self->{-name}) }

sub release { my $self = shift; $self->do_it('bgrel', @_,$self->{-name}) }

sub modify{
    my($self) = shift;
    my $newname;
    my $flag;
    for(my $i = 0; $i < @_; $i++){
        if( $_[$i] =~ /^-G(.*)/ ){
            if($1){
                $newname = $1;
            }else{
                $newname = $_[$i+1];
            }
        }
    }
    my $retval = $self->do_it('bgmod',@_,$self->{-name});
    $self->{-name} = $newname if $newname && not $?;
    return $retval;
}

sub jobs{
    my($self,@params) = @_;
    my($OUT,$ERR) = system2('bjobs','-J',$self->{-name}, @params);
    $@ = $ERR if $?;
    if( $ERR =~ /No unfinished job found/i ){
        return wantarray ? () : 0;
    }elsif( $ERR =~ /is not found/i ){
        return wantarray ? () : 0;
    }
    my @rows = split(/\n/,$OUT);
    if( wantarray ){
        my @return;
        for (@rows){
            /^(\d+)/ && push( @return, LSF::Job->new($1) );
        }
        return @return;
    }else{
        return ( scalar @rows - 1);
    }
}

1;

__END__

=head1 NAME

LSF::JobGroup - manipulate LSF job groups

=head1 SYNOPSIS

use LSF::JobGroup;

use LSF::JobGroup PRINT => 1;

$jobgroup = LSF::JobGroup->new( [GROUP_NAME] );

...

$jobgroup->add( [ARGS] ) unless $jobgroup->exists;

$jobgroup->delete;

$jobgroup->hold;

$jobgroup->release;
...
$jobgroup->modify(-w => 'exited(/mygroup/,==0)' );
...
@jobs = $jobgroup->jobs('-r');
... etc ...

=head1 DESCRIPTION

C<LSF::JobGroup> is a wrapper arround the LSF b* commands used to manipulate job
groups. for a description of how the LSF commands work see the man pages of:

    bgadd bgdel bghold bgrel bgmod bjobs

=head1 CONSTRUCTOR

=over 4

=item new ( [NUM] )

$jobgroup = LSF::JobGroup->new('/MyGroup');

Creates a new C<LSF::JobGroup> object.

Required argument is a job group name. This can be a single group name or a
path, much like a filesystem path. This does not *have* to exist in the system
as new job groups can be created. Names should only contain alphanumeric 
characters plus '_' and '-'. Not only my code but also LSF job dependancy
expressions will fail if you attempt otherwise.

=back

=head1 METHODS

=over

=item $jobgroup->exists

C<id> returns 1 if the job group exists, 0 otherwise. The method attempts to
create the group and if it fails it examines the LSF output to see if the group
existed. I couldn't find a better test to use. Answers on a postcard...

=item $jobgroup->add

Adds a job group, or group path.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $jobgroup->delete

Deletes a job group.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $jobgroup->hold

Holds a LSF job group. All pending jobs will wait until the group is released.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $jobgroup->release

Releases a LSF job group. Pending jobs are free to run.
Returns 1 on success, 0 on failure. Sets $? and $@;

=item $job->modify([ARGS])

Modifies the LSF job group. For example, changing its name or its dependancy
expression. See the bgmod man page.

$jobgroup->modify(-w => "done($job1) && finished($job2)" );
$jobgroup->modify(-w => "done($job1) && finished($job2)" );

=item $jobgroup->jobs

Returns an list of LSF::Job objects of jobs contained within this job group.
Remember to use the '-r' flag if you want to include jobs in sub groups.

=back

=head1 SEE ALSO

L<LSF>,
L<LSF::Job>,
L<bgadd>,
L<bgrel>,
L<bghold>,
L<bgrel>,
L<bgmod>,
L<bjobs>

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

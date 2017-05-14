package LSF::JobInfo; $VERSION = "0.1";

use Carp;
use System2;
use Date::Manip;

our @ISA = qw( LSF );
our $PRINT = 0;

sub import{
    my $self = shift;
    my %params = @_;
    $PRINT = $params{PRINT} if exists $params{PRINT};
}

sub new{
    my($self,@params) = @_;
    my $class = ref($self) || $self || "LSF::JobInfo";

    @params = grep { $_ ne '-l' } @params;
    my($OUT,$ERR) = system2('bjobs','-l',@params);
    if($?){
        $@ = $ERR;
        carp $@ if $self->print;
        return ();
    }else{
        print $OUT if $self->print;

        my @jobinfo;
        for my $job (split(/^-+$/m,$OUT)){
            my ($result) = split(/;\n\s/,$job);
            $result =~ s/\n\s+//g;
            my @lines = split(/\n/,$result);
            shift @lines unless $lines[0];
            my $return = get_params($lines[0]);

            if( $job =~ /^(.+): Started on/m ){
                $return->{Started} = UnixDate( $1, "%d-%b-%y %T" );
            }

            if( $job =~ /(.+): (Done|Exited)/ ){
                $return->{Ended} = UnixDate( $1, "%d-%b-%y %T" );
            }

            bless $return, $class;
            push @jobinfo,$return;
        }
        return @jobinfo;
    }
    sub get_params{
        my $line = "$_[0],";
        my $return;
        for(split(/>, ?/,$line)){
            if( /^(.+) <(.+)/ ){
                $return->{$1} = $2;
            }
        }
        return $return;
    }
}

1;

__END__

=head1 NAME

LSF::JobInfo - get information about LSF jobs.

=head1 SYNOPSIS

use LSF::JobInfo;

use LSF::JobInfo PRINT => 1;

( $jobinfo ) = LSF::JobInfo->new( [ARGS] );

( $jobinfo ) = LSF::JobInfo->new( $job );

( $jobinfo ) = LSF::JobInfo->new( [JOBID] );

@jobinfo = LSF::JobInfo->new( -J => '/MyJobGroup/*');

( $jobinfo ) = LSF::JobInfo->new($job);

$jobinfo = $job->info;

... etc ...

=head1 DESCRIPTION

C<LSF::JobInfo> is a wrapper arround the LSF 'bjobs' command used to obtain
information about jobs. The hash keys of the object are LSF submission and 
control parameters. See the 'bjobs' man page for more information.

=head1 CONSTRUCTOR

=over 4

=item new( [ARGS] || [JOBID] || $job );

($jobinfo) = LSF::JobInfo->new(  [ARGS]
                              || [JOBID]
                              || $job );

Creates a new C<LSF::JobInfo> object.

Arguments are the LSF parameters normally passed to 'bjobs' or
a valid LSF jobid or LSF::Job object.
Returns an array of LSF::JobInfo objects. Of course if your argument to new is
a single jobid then you will get an array with one item. If you query for a 
number of jobs with the same name or path then you will get a list.
In scalar context returns the number of jobs that match that criteria.

=head1 SEE ALSO

L<LSF>,
L<LSF::Job>,
L<bjobs>

=head1 BUGS

Please report them.
Otherwise... the parsing of the LSF output can fail if the job names have 
non-alphanumeric characters in them. You probably shouldn't do this anyway.

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

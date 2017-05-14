package LSF::Queue; $VERSION = "0.1";

use Carp;
use LSF;
use System2;

our @ISA = qw( LSF );
our $PRINT = 0;

sub import{
    my $self = shift;
    my %params = @_;
    $PRINT = $params{PRINT} if exists $params{PRINT};
}

sub new{
    my($class,@params) = @_;
    my($OUT,$ERR) = system2('bqueues','-l',@params);
    if($?){
        $@ = $ERR;
        carp $@ if $class->print;
        return ();
    }else{
        print $OUT if $class->print;

        my @queue;
        for my $text (split(/^-+$/m,$OUT)){
            my $queue;
            for ('QUEUE','USERS','HOSTS','RES_REQ','PREEMPTION',
                 'CHKPNTDIR','CHKPNTPERIOD','CHUNK_JOB_SIZE'){
                if( $text =~ /^($_):\s+(.+)$/m ){
                    $queue->{$1} = $2;
                }
            }
            $text =~ /^  -- (.+)$/m;
            $queue->{DESC} = $1;
            for ('MEMLIMIT','PROCLIMIT','CPULIMIT'){
                if( $text =~ /\n ($_)\n ([^\n]+)/ ){
                    $queue->{$1} = $2;
                }
            }
            $text =~ /PARAMETERS\/STATISTICS\n([^\n]+)\n\s*([^\n]+)/;
            my @keys = split(/\s+/,$1);
            my @vals = split(/\s+/,$2);
            for( my $i = 0; $i < @keys; $i++ ){
                $queue->{$keys[$i]} = $vals[$i];
            }
            bless $queue, $class;
            push @queue,$queue;
        }
        return @queue;
    }
}

1;

__END__

=head1 NAME

LSF::Queue - get information about LSF queues.

=head1 SYNOPSIS

use LSF::Queue;

use LSF::Queue PRINT => 1;

$qinfo = LSF::Queue->new( [QUEUE_NAME] );

@qinfo = LSF::Queue->new();

=head1 DESCRIPTION

C<LSF::Queue> is a wrapper arround the LSF 'bqueues' command used to obtain
information about job queues. The hash keys of the object are LSF submission
and control parameters. See the 'bqueues' man page for more information.

=head1 CONSTRUCTOR

=over 4

=item new( [ [QUEUE_NAME] ] );

With a valid queue name, reates a new C<LSF::JobInfo> object. Without a queue 
name returns a list of LSF::Queue objects for all the queues in the system.
Arguments are the LSF parameters normally passed to 'bqueues'

=head1 BUGS

Please report them. 
The parsing of LSF output is particularly unsafe if job and group names with 
non-alphanumeric characters are used. You probably shouldn't be doing this
anyway.

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

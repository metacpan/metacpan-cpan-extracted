package MYDan::Deploy::Jobs;
use strict;
use warnings;
use Carp;

use MYDan::Node;

our %CONF = ( redo => 0, retry => 0, timeout => 0, goon => '100%' );

sub new
{
    my ( $class, %self ) = splice @_;

    map{ confess "no $_" unless defined $self{$_} }qw( name step conf ctrl code cache );
    
    bless \%self, ref $class || $class;
}

sub run
{
    my ( $this, @node ) = @_;

    @node = map{ @$_ }@node if ref $node[0] eq 'ARRAY';
    my %node = map{ $_ => 1 }@node;

    my ( $name, $step, $conf, $ctrl, $code, $cache  )
        = @$this{qw( name step conf ctrl code cache )};

    map { $conf->{$_} = $CONF{$_} unless defined $conf->{$_} }keys %CONF;
    my ( $redo, $retry, $title, $delay, $sleep, $repeat, $timeout, $grep, $fix, $goon ) 
        = @$conf{qw( redo retry title delay sleep repeat timeout grep fix goon )};

    $goon = ( $goon * scalar @node ) / 100 if $goon =~ s/%$//;

    print "\n\n", "=" x 75,"\n";
    printf "title: $title | step: %s| node:%d\n", $step, scalar @node;
    print "=" x 75,"\n";

    my ( $range, %succ, %tryfix ) = MYDan::Node->new();

    for my $i ( 0 .. $redo )
    {
        print '#' x 75 ,"\n";
        printf "%s ...\n", $tryfix{$i} ? 'tryfix' : $i ? "redo #$i" : 'do';
 
        my ( $try, $error ) = $tryfix{$i} ? $tryfix{$i} -1 : $retry;
        for my $j ( 0 .. $try )
        {
            print '-' x 75 ,"\n";
            if( $tryfix{$i} )
            {
                last unless $ctrl->stuck( $title, $step );
                printf "try fix %s\n", $j +1;
            }
            else
            {
                print "retry $j\n" if $j;
                sleep 3 while $ctrl->stuck( $title, $step );
            }

            %succ = () if $repeat;
            my %excluded = map{ $_ => 1 }@{$ctrl->excluded()};
            @node = grep{ ! $succ{$_} }grep{ ! $excluded{$_} }@node;
            @node = grep{ $cache->{succ}{$grep}{$_} }@node if $grep;

#            last if ! @node && $tryfix{$i};
           

            printf "time: %s\nnode[%s]: %s\n",
                POSIX::strftime( "%F_%T", localtime ),
                scalar $range->load( \@node )->list(),
                $range->load( \@node )->dump();
        
            sleep $delay if $delay && print "delay $delay sec ...\n";
    
    
            my %s;
            eval{
                alarm $timeout;
                %s = &$code
                (
                    name => $name,
                    step => $step,
                    title => $title,
                    param => $conf->{param},
                    batch => \@node,
                    cache => $cache,
                );
               alarm 0;
            };
            alarm 0;
            $error = $@ || '';

            map{ $succ{$_} = $s{$_} }grep{ $node{$_} }keys %s;

            $error = sprintf "goon: $goon succ: %s err:$error", scalar keys %succ
                if keys %succ < $goon;


            sleep $sleep if $sleep && print "sleep $sleep sec ...\n";
            last unless $error;
            print "[error]: $error\n";
 
        }

        $ctrl->resume( $title, $step ) if $tryfix{$i} && !$error;

        last unless $error;
        $ctrl->pause( 'error', $title, $step, $error ) unless $tryfix{$i};

        redo if ! $tryfix{$i} && ( $tryfix{$i} = $fix );
        sleep 3 while $ctrl->stuck( $title, $step );
    }

    return %succ;
}

1;

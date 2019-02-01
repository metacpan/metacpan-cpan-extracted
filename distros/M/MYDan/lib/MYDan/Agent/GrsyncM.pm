package MYDan::Agent::GrsyncM;

=head1 NAME

MYDan::Util::GrsyncM - Replicate data via phased agent

=head1 SYNOPSIS

 use MYDan::Util::GrsyncM;
 my $grsyncm = MYDan::Util::GrsyncM->new
 (
     opt => +{
          '3' => 1,
          'dp' => '/tmp/path1',
          'sp' => '/tmp/path2',
          'retry' => 2,
          'timeout' => 300,
          'user' => 'root',
          'gave' => 3
     },
     sync => +{
        src => [],
        dst => [],
        agent => +{},
     },
     task => [ +{ sp => '', dp => '' }, +{ sp => '', dp => '' } ] #make by opt
 );
 $grsyncm->run();

=cut

use strict;
use warnings;

use Carp;
use File::Basename;

use MYDan::Agent::Client;

use MYDan::Agent::Grsync::V12;
use MYDan::Agent::Grsync::V3;
use MYDan::Agent::Grsync::V4;

sub new
{
    my ( $class, %self ) = ( @_, 'usetime' => 0 );

	my $chars = [ "A" .. "Z", "a" .. "z", 0 .. 9 ];
	$self{uuid} ||= join("", @$chars[ map { rand @$chars } ( 1 .. 8 ) ]);

    unless( defined $self{task} )
    {
        map{ die "$_ undef" unless $self{$_} }qw( opt sync );
        map{ die "opt.$_ undef" unless $self{opt}{$_} }qw( sp dp );

        my @file;
        if( scalar @{$self{sync}{src}} && ( $self{opt}{sp} =~ /\/$/ || $self{opt}{sp} =~ /\*/ ) )
        {
                $self{spIsDir} = 1;
                my $time = time;

                my %query = ( 
                    code => 'zipdir', argv => +{ uuid => $self{uuid}, path => [ $self{opt}{sp} ], 
                        makelist => $self{opt}{delete} ? 1 : 0, dirdetail => $self{opt}{cc} ? 1 : 0 }, 
                    map{ $_ => $self{opt}{$_} }qw( user sudo ) );
                my %result = MYDan::Agent::Client->new( $self{sync}{src}[0] )
                             ->run( %{$self{opt}}, %{$self{sync}{agent}}, query => \%query );

                my $result = $result{$self{sync}{src}[0]} || '';
                unless( $result =~ s/--- 0\n$// )
                {
                    warn $self{error} = "[ERROR]get zipdir from $self{sync}{src}[0] failed\n";
                }
                elsif( $result =~ /The content was truncated/ )
                {
                    warn $self{error} = "[ERROR]zipdir on $self{sync}{src}[0] too long.\n$result\n";
                }
                else
                {
                    @file = split /\n/,$result;
                }

                $self{usetime} = time - $time;
        }

        if( $self{opt}{sp} =~ /;/  )
        {
            warn $self{error} = "[ERROR]dp is not a directory format\n" unless $self{opt}{dp} =~ /\/$/;
            $self{task} = [ map{ +{ sp => $_, dp => $self{opt}{dp}.basename $_ } }split /;/, $self{opt}{sp} ];
        }
        elsif( $self{opt}{sp} =~ /\/$/ )
        {
            warn $self{error} = "[ERROR]dp is not a directory format\n" unless $self{opt}{dp} =~ /\/$/;
            if( scalar @{$self{sync}{src}} )
            {
                map{ $_ =~ s/^\.\///  }@file;
            }
            else
            {
                @file = `cd '$self{opt}{sp}' && find . -type f`;
                chomp @file;
                map{ $_ =~ s/^\.\///  }@file;
            }
            $self{task} = [ map{ +{ sp => "$self{opt}{sp}$_", dp => "$self{opt}{dp}$_" }  }@file ];
        }

        elsif( $self{opt}{sp} =~ /\*/ )
        {
            warn $self{error} = "[ERROR]dp is not a directory format\n" unless $self{opt}{dp} =~ /\/$/;
            @file = grep{ -f $_ }glob $self{opt}{sp} unless scalar @{$self{sync}{src}};
            $self{task} = [ map{ +{ sp => $_, dp => $self{opt}{dp}.basename $_ }  }@file ];
        }
        else
        {
            $self{task} = [ +{ 
                sp => $self{opt}{sp}, dp => ( $self{opt}{dp} =~ /\/$/ ) 
                    ? $self{opt}{dp}.basename $self{opt}{sp}: $self{opt}{dp} 
            } ];
        }
    }

    bless \%self, ref $class || $class;
}

sub run
{
    my $this = shift;

    my ( $opt, $sync, %failed ) = @$this{qw( opt sync )};

    if( $this->{error} )
    {
        return wantarray ? @{$sync->{dst}} : $sync->{dst};
    }

    for my $task ( @{$this->{task}} )
    {
        print '-' x 60, "\n";

        my $timeout = $opt->{timeout} - $this->{usetime};
        print "sp:$task->{sp} => dp:$task->{dp}\n";
        my @dst = grep{ ! $failed{$_} }@{$sync->{dst}};
        last unless @dst;
        if( $timeout < 0 )
        {
            map{ $failed{$_} ++ }@dst;
            last;         
        }

        my %sync = ( %$sync, dst => \@dst );

        my $grsync = $opt->{4} ? MYDan::Agent::Grsync::V4->new ( %sync ):
                     $opt->{3} ? MYDan::Agent::Grsync::V3->new ( %sync ):
                                MYDan::Agent::Grsync::V12->new ( %sync );
        
        my $time = time;
        my @failed = $grsync->run( %$opt, %$task, timeout => $timeout )->failed();
        $this->{usetime} += time - $time;
        if( @failed )
        {
            print "failed:\n";
            map{ $failed{$_}++; print "$_\n" }@failed;
        }
    }

    print '=' x 60, "\n";

    if( $this->{spIsDir} )
    {
    	my %query = ( 
    		code => 'unzipdir', argv => +{ uuid => $this->{uuid}, 
                path => [ $this->{opt}{dp} ], map{ $_ => $opt->{$_} }qw( delete chown chmod ) }, 
    		map{ $_ => $opt->{$_} }qw( user sudo ) );
    	my %result = MYDan::Agent::Client->new( @{$sync->{dst}} )
    	    ->run( %$opt, %{$sync->{agent}}, query => \%query );
    
        print "untar.\n";
        for my $node ( keys %result )
        {
            if( $result{$node} =~ s/--- 0\n$// )
            {
                 print "$node: $result{$node}\n" if $result{$node};
            }
            else
            {
                print "$node: $result{$node}\n";
                $failed{$node} = 1;
            }
        }
        
    
        print '=' x 60, "\n";
        print "clean dir.\n";
    
    	%query = ( 
    		code => 'cleandir', argv => +{ uuid => $this->{uuid}, 
                path => [ $this->{opt}{sp}, $this->{opt}{dp} ], expire => 86400 }, 
    		map{ $_ => $this->{opt}{$_} }qw( user sudo ) );
    	%result = MYDan::Agent::Client->new( @{$sync->{src}}, @{$sync->{dst}} )
    	    ->run( %$opt, %{$sync->{agent}}, query => \%query );
    
        for my $node ( keys %result )
        {
            unless( $result{$node} =~ s/--- 0\n$// )
            {
                print "[warn]$node: $result{$node}\n";
            }
        }
    }

    my @failed = keys %failed;

    return wantarray ? @failed : \@failed;
}

1;

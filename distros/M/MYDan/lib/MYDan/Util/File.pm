package MYDan::Util::File;

=head1 NAME

MYDan::Util::File

=head1 SYNOPSIS
 
=cut
use strict;
use warnings;

use Carp;
use Tie::File;
use File::Temp;
use FindBin qw( $Script );

=head1 SYNOPSIS

 my $file = MYDan::Util::File->new( '/etc/passwd' );

 $file->munge( regex => qr/^foo\b/, length => 1, lazy => 1 )->commit();

=cut
sub new
{
    my ( $class, $path, %self ) = splice @_;

    local $/ = $self{RS} ||= "\n";

    confess "failed to open temp" unless my $temp = $self{temp}
        = File::Temp->new( UNLINK => 0, SUFFIX => ".$Script" );

    confess "failed to cp $path $temp" if system "cp $path $temp";
    confess "failed to open file" unless tie my @list, 'Tie::File', $temp;

    @self{ qw( mode uid gid ) } = ( stat $path )[2,4,5];
    @self{ qw( curr path list ) } = ( 0, $path, \@list );

    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 munge( %param )

 seek: 'set' or 'end'
 offset: number of lines from seek position
 length: number of lines to remove
 regex: a regular expression
 lazy: default to end of file if regex match failed
 line: a set of lines

=cut
sub munge
{
    my ( $self, %param ) = splice @_;
    my $list = $self->{list};
    my $match = $param{lazy};
    my $line = $param{line} || [];
    my $seek = lc( $param{seek} || 'curr' );
    my $length = $param{length} || 0;
    my $curr = ( $param{offset} || 0 ) +
        ( $seek eq 'set' ? 0 : $seek eq 'end' ? @$list : $self->{curr} );

    if ( my $regex = $param{regex} )
    {
        $regex = eval $regex unless ref $regex;
        confess 'invalid regex definition' if ref $regex ne 'Regexp';

        while ( $curr < @$list )
        {
            last if $list->[$curr] =~ $regex && ( $match = 1 );
            $curr ++;
        }
    }
    else { $match = 1 }

    if ( $match )
    {
        my @list = splice @$list, $curr, $length, ref $line ? @$line : $line;
        $self->{curr} = @list && $curr ? $curr - @list : $curr;
    }

    return $self;
}

=head3 commit( %param )

 path: alternative path to commit
 backup: back up original file

=cut
sub commit
{
    my ( $self, %param ) = splice @_;
    my $path = $param{path} || $self->{path}; $path = readlink if -l $path;
    my $temp = $self->{temp};
    my $error = "$temp -> $path: failed to";

    confess "$error chown" unless chown @$self{ qw( uid gid ) }, $temp;
    confess "$error chmod" unless chmod $self->{mode}, $temp;

    system "cp $path $path.bk" if $param{backup} && -e $path;
    confess "$error mv" if system "mv $temp $path";
    return $self;
}

sub DESTROY
{
    my $self = shift;
    untie @{ $self->{list} };
    unlink $self->{temp} if -f $self->{temp};
}

1;

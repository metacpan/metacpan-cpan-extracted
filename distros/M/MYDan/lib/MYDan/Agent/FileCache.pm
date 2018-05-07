package MYDan::Agent::FileCache;

=head1 NAME

MYDan::Agent::FileCache

=head1 SYNOPSIS

 use MYDan::Agent::FileCache;

 my $fc = MYDan::Agent::FileCache->new();
 
 $fc->save( '/my/file' );
 $fc->save( '/my/file' => md5 );

 $fc->check( md5 );

 $fc->get( '/my/file' => md5 );

 $fc->clean();

=cut
use strict;
use warnings;

use MYDan;
use Digest::MD5;

sub new
{
    my ( $class, %self ) = @_;
    $self{path} ||= "$MYDan::PATH/var/run/filecache";
    bless \%self, ref $class || $class;
}

sub save
{
    my ( $this, $file ) = @_;

    my $path = $this->{path};
    return 0 unless -e $path && defined $file &&  -f $file;

    $this->_clean();

    my $tempmd5 = Digest::MD5->new()->add( $file.time,$$ )->hexdigest();
    die "save fail: $!" if system "cp '$file' '$path/$tempmd5.tmp'";

    open my $fh, "<$path/$tempmd5.tmp" or die "open fail: $!";
    my $md5 = Digest::MD5->new()->addfile( $fh )->hexdigest();
    close $fh;

    die "save fail: $!" if system "mv '$path/$tempmd5.tmp' '$path/$md5'";
    
    return $md5;
}

sub check
{
    my ( $this, $md5 ) = @_;

    my $path = $this->{path};
    return undef unless -e $path && defined $md5;

    return  -e "$path/$md5" ? "$path/$md5" : undef;
}

sub get
{
    my ( $this, $file, $md5 ) = @_;

    my $path = $this->{path};
    return 0 unless -e $path && defined $file && defined $md5 &&  -e "$path/$md5";

    die "get fail: $!" if system "cp '$path/$md5' '$file'";
    return 1;
}

sub _clean
{
    my $this = shift;

    return unless -e $this->{path};

    for my $f ( grep{ -f } glob "$this->{path}/*" )
    {
        if( $f =~ m/\/[a-zA-Z0-9]{32}\.tmp$/ )
        {
            my $t = ( stat $f )[9];
            unlink $f if $t && $t < time - 3600;
        }
        elsif( $f =~ m/\/[a-zA-Z0-9]{32}$/ )
        {
            my $t = ( stat $f )[9];
            unlink $f if $t && $t < time - 604800;
        }
    }

    return;
}

1;

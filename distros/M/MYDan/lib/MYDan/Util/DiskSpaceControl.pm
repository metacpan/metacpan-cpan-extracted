package MYDan::Util::DiskSpaceControl;
use strict;
use warnings;
use Carp;

$|++;

sub new
{
    my ( $class, %self ) = @_;

    map{ die "$_ undef\n" unless defined $self{$_} } qw( mountedOnPath percent );

    $self{size} = _get_disk_info( $self{mountedOnPath} =>  '1K-blocks' );

    $self{ddbs} = int( $self{size} / 500000 );

    $self{path} = "$self{mountedOnPath}/DiskSpaceControl";

    ( $self{min}, $self{max} ) 
        = map{ int( $self{size} * ( $self{percent} + $_ ) / 100 ) }( -0.03, 0.03 );

    bless \%self, ref $class || $class;
}

sub run
{
    my $this = shift;

    my $used = _get_disk_info( $this->{mountedOnPath} => 'Used' );

    if( $used < $this->{min} )
    {
        $this->add();
    }
    elsif( $used > $this->{max})
    {
        $this->del();
    }
    else
    {
        printf "percent: %0.2f%%\n", $used / $this->{size} * 100;
    }
}

sub add
{
    my $this = shift;

    while( 1 )
    {
        mkdir "$this->{path}" unless -d $this->{path};

        my $file = sprintf "$this->{path}/%s_DiskSpaceControl_tmp", time .'.' .int rand 1000;

        my $used = _get_disk_info( $this->{mountedOnPath} => 'Used' );

        die "dd fail: $!" if system "dd if=/dev/zero of=$file bs=$this->{ddbs}k count=100 2>/dev/null";

        printf "percent: %0.2f%% +\n", $used / $this->{size} * 100;

        return if $used > $this->{min};
    }
}

sub del
{
    my $this = shift;

    my @file = grep{ -f $_ }grep{ $_ =~ /\/\d+\.\d+_DiskSpaceControl_tmp$/ }glob "$this->{path}/*";

    while(1)
    {
        my $file = shift @file;

        unlink $file if $file;

        my $used = _get_disk_info( $this->{mountedOnPath} => 'Used' );

        printf "percent: %0.2f%% %s\n", ( $used / $this->{size} * 100 ) , $file ? '-' : '';

        return if ! $file || $used < $this->{max};
    }
}

sub _get_disk_info
{
    my ( $mountedOn, $name ) = @_;

    map{chomp}my @info = `LANG=en df`;

    die "df fail" unless @info;
    my @title = split /\s+/, shift @info;

    my $index;
    for( 0 .. $#title )
    {
        if( $title[$_] eq $name )
        {
            $index = $_;
            last;
        }
    }

    die "no find $name" unless defined $index;

    for( @info )
    {
        my @n = split /\s+/, $_;
        return $n[$index] if $n[$#n] eq $mountedOn;
    }

    die "no find $mountedOn => $name";
}

1;

__END__

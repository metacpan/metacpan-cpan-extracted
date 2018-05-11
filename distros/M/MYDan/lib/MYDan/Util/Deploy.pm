package MYDan::Util::Deploy;
use strict;
use warnings;
use Cwd;
use File::Basename;

sub new
{
    my ( $class, %self ) = @_;

    map{ die "$_ undef" unless $self{$_} }qw( link path repo version keep );

    map{ 
        die "$_ format error" unless $self{$_} =~ /[a-zA-Z0-9]/ && $self{$_} !~ /'/;
    }qw( link path repo version );

    die "keep format error" unless $self{keep} =~ /^\d+$/;

    die "$self{repo}: No such directory.\n" unless -d $self{repo};

    unless( -d $self{path} )
    {
        die "mkdir path $self{path} fail: $!" if system "mkdir -p '$self{path}'";
    }

    my $linkdir = dirname $self{link};
    unless( -d $linkdir )
    {
        die "mkdir path $linkdir fail: $!" if system "mkdir -p '$linkdir'";
    }

    map{ 
        $self{$_} = Cwd::abs_path( $self{$_} ) unless $self{$_} =~ /^\//;
    }qw( path repo );

    bless \%self, ref $class || $class;
}

sub deploy
{
    my $this = shift;

    my ( $path, $link, $version ) = @$this{qw( path link version )};

    my $temp = "$link.backup";

    if( $version eq 'backup' )
    {
        die "$temp: No such directory.\n" unless -d $temp;
        die "link $link fail.\n" if syscmd( "ln -fsn '$temp' '$link'" );
        return $this;
    }

    $this->_explain();

    if( -d $link && ! -l $link )
    {
        die "$temp already used.\n" if -e $temp;
        die "backup old link fail.\n" if syscmd( "mv '$link' '$temp'" );
    }

    die "link $link fail.\n" if syscmd( "ln -fsn '$path/$version' '$link'" );

    $this->_clean();
    return $this;
}


sub _explain
{
    my $this = shift;

    my ( $repo, $path, $version ) = @$this{qw( repo path version )};
    return if -d "$path/$version";

    die "nofind repo file: $repo/$version\n" unless -f "$repo/$version";

    my $temp = "$path/$version.".time.'.'.$$.'._tmp_explain';
    die "mkdir $temp fail.\n" if syscmd( "mkdir '$temp'" );

    die "untar fail.\n" if syscmd( "tar -zxf '$repo/$version' -C '$temp'" );
    die "rename fail.\n" if syscmd( "rm -rf '$path/$version' && mv '$temp' '$path/$version'" );
}

sub _clean
{
    my $this = shift;
    my ( $repo, $path, $version, $keep ) = @$this{qw( repo path version keep )};

    my $regx = $version;
    $regx =~ s/\d+/\\d+/g;

    my ( %path, @path );
    for( glob "$repo/*" )
    {
        next unless -f $_;
        my $name = basename $_;
        next if $name !~ /^$regx$/ || $name eq $version;
        die "get $_ mtime fail.\n" unless my $mtime = ( stat $_ )[9];
        $path{$name} = $mtime;

    }
    @path = sort{ $path{$a} <=> $path{$b} }keys %path;

    while( @path >= $keep )
    {
        my $name = shift @path;
        die "rmmove fail.\n" if syscmd( "rm -f '$repo/$name'" );
    }

    my $expire = time - 86400;

    for( glob "$path/*" )
    {
        next unless -d $_;
        my $name = basename $_;
        next if $name !~ /^$regx\.\d{10}\.\d+\._tmp_explain$/;
        die "get $_ mtime fail\." unless my $mtime = ( stat $_ )[9];
        next unless $mtime < $expire;
        die "rmmove fail.\n" if syscmd( "rm -f '$_'" );
    }
 
    ( %path, @path ) = ();

    for( glob "$path/*" )
    {
        my $name = basename $_;
        next if $name !~ /^$regx$/ || $name eq $version;
        die "get $_ mtime fail.\n" unless my $mtime = ( stat $_ )[9];
        $path{$name} = $mtime;
    }
    @path = sort{ $path{$a} <=> $path{$b} }keys %path;

    while( @path >= $keep )
    {
        my $p = shift @path;
        die "rmmove fail.\n" if syscmd( "rm -rf '$path/$p'" );
    }
}

sub syscmd
{
    my $cmd = shift;
    print "$cmd\n";
    my $stat = system $cmd;
    warn "ERROR: $!\n" if $stat;
    return $stat;
}

1;
__END__

package MYDan::Util::Deploy;
use strict;
use warnings;
use Cwd;
use Digest::MD5;
use File::Basename;

sub new
{
    my ( $class, %self ) = @_;

    map{ die "$_ undef" unless $self{$_} }qw( link path repo version keep );

    map{ 
        die "$_ format error" unless $self{$_} =~ /[a-zA-Z0-9]/ && $self{$_} !~ /'/;
    }qw( link path repo version );

    die "keep format error" unless $self{keep} =~ /^\d+$/;

    die "$self{repo}: No such directory.\n" if $self{repo} !~ /@/ && ! -d $self{repo};

    unless( -d $self{path} )
    {
        die "mkdir path $self{path} fail: $!" if system "mkdir -p '$self{path}'";
    }

    my $linkdir = dirname $self{link};
    unless( -d $linkdir )
    {
        die "mkdir path $linkdir fail: $!" if system "mkdir -p '$linkdir'";
    }

    $self{cache} = (getpwnam((getpwuid $<)[0]))[7] . "/.mydan/deploy";

    $self{path} = Cwd::abs_path( $self{path} ) unless $self{path} =~ /^\//;
    $self{repo} = Cwd::abs_path( $self{repo} ) if $self{repo} !~ /@/ && $self{repo} !~ /^\//;

    bless \%self, ref $class || $class;
}

sub deploy
{
    my $this = shift;

    my ( $path, $link, $version ) = @$this{qw( path link version )};

	return $this->_recoverlink() if $this->{comeback};

    my $temp = "$link.backup";

    if( $version =~ /^backup\d*$/ )
    {
        $temp = "$link.$version";
        die "$temp: No such directory.\n" unless -d $temp;
        die "link $link fail.\n" if syscmd( "ln -fsn '$temp' '$link'" );
        return $this;
    }

    $this->_explain();

    if( -d $link && ! -e $temp )
    {
        die "backup old link fail.\n" if syscmd( "mv '$link' '$temp'" );
    }

    die "link $link may be a directory.\n" if -d $link && ! -l $link;

	$this->_savelink();

	return $this if $this->{stage};

    die "link $link fail.\n" if syscmd( "ln -fsn '$path/$version' '$link'" );

    $this->_clean();
    return $this;
}

sub _recoverlink
{
    my $this = shift;

    my ( $link, $version, $cache ) = @$this{qw( link version cache )};

    my $md5 = Digest::MD5->new->add( "$link:$version" )->hexdigest;

    die "recover link fail: No such link.\n" unless -l "$cache/$md5";
    my $newlink = readlink "$cache/$md5";
    die "recover link fail: No link to a directory.\n" unless -d $newlink;

    die "recover link fail: ln -fsn.\n" if syscmd("ln -fsn $newlink '$link'");

    return $this;
}

sub _savelink
{
    my $this = shift;

    my ( $link, $version, $cache ) = @$this{qw( link version cache )};

    return $this unless my $oldlink = readlink $link;

    my $md5 = Digest::MD5->new->add( "$link:$version" )->hexdigest;
    return $this if -l "$cache/$md5";

    unless( -d $cache )
    {
        die "mkdir $cache fail.\n" if syscmd( "mkdir -p '$cache'" );
    }

    die "save link fail: ln -fsn.\n" if syscmd("ln -fsn $oldlink '$cache/$md5'");

    my $expire = time - 94608000;

    for( glob "$cache/*" )
    {
        next unless -l $_;
        die "get $_ mtime fail\." unless my $mtime = ( lstat $_ )[9];
        next unless $mtime < $expire;
        die "rmmove fail.\n" if syscmd( "rm -f '$_'" );
    }

    return $this;
}

sub _explain
{
    my $this = shift;

    my ( $repo, $path, $version, $taropt, $rsyncopt, $link ) = @$this{qw( repo path version taropt rsyncopt link )};
    return if -d "$path/$version";

    die "nofind repo file: $repo/$version\n" unless $repo =~ /@/ || -f "$repo/$version" || -d "$repo/$version";

    my $temp = "$path/$version.".time.'.'.$$.'._tmp_explain';
    die "mkdir $temp fail.\n" if syscmd( "mkdir '$temp'" );

    $taropt ||= '';
    $rsyncopt ||= '-rlptoD';

    if( -f "$repo/$version" )
    {
        die "untar fail.\n" if syscmd( "tar $taropt -zxf '$repo/$version' -C '$temp'" );
    }
    elsif( $repo =~ /@/ || -d "$repo/$version" )
    {
        if( -d $link ) { die "rsync fail.\n" if syscmd( "rsync $rsyncopt '$link/' '$temp/'" )};
        die "rsync fail.\n" if syscmd( "rsync $rsyncopt --delete '$repo/$version/' '$temp/'" );
    }
    else
    {
        die "$repo/$version unkown type"
    }
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
        die "rmmove fail.\n" if syscmd( "rm -rf '$_'" );
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
    my $x = $cmd;
    $x =~ s/\.\d+\.\d+\._tmp_explain/.x.x._tmp_explain/g;
    print "$x\n";
    my $stat = system $cmd;
    warn "ERROR: $!\n" if $stat;
    return $stat;
}

1;
__END__

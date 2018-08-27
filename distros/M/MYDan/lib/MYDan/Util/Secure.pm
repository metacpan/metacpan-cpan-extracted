package MYDan::Util::Secure;
use strict;
use warnings;
use Carp;
use Tie::File;
use Digest::MD5;

$|++;

sub new
{
    my ( $class, %self ) = @_;
    die "path undef\n" unless $self{path};
    bless \%self, ref $class || $class;
}

sub pull
{
    my $this = shift;
    my $path = $this->{path};

    if( ! -d "$path/secure" )
    {
        print "Enter a git project address or GitHub user name:";
        my $name = <STDIN>;
        chomp $name;
        die "input error.\n" unless length $name;
        my $git = $name =~ /^[a-zA-Z0-9_\.-]+$/ ? "https://github.com/$name/secure" : $name;
        print "clone $git ...\n";
        die "die\n" if system "cd $path && git clone $git";
    }
    else
    {
        die "clone fail:$!.\n" if system "cd $path/secure && git reset --hard HEAD  && git clean -f -d && git pull";
    }

    return $this unless -f "$path/secure/data";

    my $pass = _password(0);
    die "untar fail:$!\n" if system "cd $path/secure && openssl des3 -d -k '$pass' -salt -in data | tar xzf - -C /";
    return $this;
}

sub add
{
    my ( $this, $file ) = @_;
    die "file format error.\n" unless $file =~ /^\//;

    die "tie list fail: $!!" unless tie my @list, 'Tie::File', "$this->{path}/secure/list";
    unless(grep{$_ eq $file }@list) { push @list, $file; }
    untie @list;

    return $this;
}

sub del
{
    my ( $this, $file ) = @_;

    die "tie list fail: $!!" unless tie my @list, 'Tie::File', "$this->{path}/secure/list";
    @list = grep{ $_ ne $file }@list;
    untie @list;

    return $this;
}

sub show
{
    my $this = shift;

    die "tie list fail: $!!" unless tie my @list, 'Tie::File', "$this->{path}/secure/list";
    map{ printf "$_: %s\n", -f $_ ? "file" : "nofile"; }@list;
    untie @list;

    return $this;
}

sub push
{
    my $this = shift;
    my $path = $this->{path};

    die "nofind $path/secure\n" unless( -d "$path/secure" );

    my $pass = _password(1);
 
    die "tar fail:$!\n" if system "cd $path/secure && tar -czv -T list |openssl des3 -salt -k '$pass' -out data";
    die "push fail:$!\n" if system "cd $path/secure && git add * && git commit -m update && git push";

    return $this;
}

sub _password
{
    my $x = shift;
    while(1)
    {
        my ( $x1, $x2 ) = map{ __password( $_ ) } 0 .. $x;
        return Digest::MD5->new()->add( $x1 )->hexdigest() if ( !$x || ( $x1 eq $x2 ) ) && length $x1;
    }
}

sub __password
{
    my $c = shift;
    printf "%s secure password:", $c ? 'Retype' : 'Enter';
    system "stty -echo";
    my $x =  <STDIN>;
    system "stty echo";
    print "\n";
    return $x;
}

1;
__END__

package MYDan::Util::Check::Proc;
use strict;
use warnings;

$|++;

sub new
{
    my ( $class, $col, $type, $name, @condition ) = @_;

    die "not supported.\n" unless $col && ( $col eq 'num' || $col eq 'time' );
    die "not supported.\n" unless $type && ( $type eq 'name' || $type eq 'cmdline' || $type eq 'exe' );
    die "not supported.\n" unless $name && $name =~ /^[=~].+/;

    $name =~ s/^([=~])//;
    my $grep = $1 eq '~' ? 1 : 0;

    die "format error.\n" unless @condition;
    map{ die "format error.\n" unless $_ =~ /^[><=]\d+$/  }@condition;
    bless +{ grep => $grep, col => $col, type => $type, name => $name, condition => \@condition }, ref $class || $class;
}

sub check
{
    my ( $this, %run, $error ) = @_;
    my ( $col, $type, $name, $condition ) = @$this{qw( col type name condition )};

    my %proc = $type eq 'name' ? $this->procByName() : $type eq 'cmdline' ? $this->procByCmdline() : $this->procByExe();
    %proc = map{ $_ => +{ %{$proc{$_}}, time => time - $proc{$_} } }grep{ defined $proc{$_}{time} }keys %proc if $col eq 'time';

    map{ print "pid:$_ name:$proc{$_}{name} time:$proc{$_}{time}\n"; }keys %proc if $run{debug};

    $error = $col eq 'num' ? $this->checkNum( %proc ) : $this->checkTime( %proc );
}

sub checkNum
{
    my ( $this, %proc, $error ) = @_;
    my ( $condition ) = @$this{qw( condition )};
    my $len = scalar keys %proc;

    for my $cond ( @$condition )
    {
        next unless $cond =~ /^([><=])\d+$/;
        my $x = $1 eq '=' ? '=' : '';

        if( eval "$len$x$cond" )
        {
            print "$len$cond ok\n";
        }
        else
        {
            print "$len$cond err\n";
            $error ++;
        }
    }
    return $error;
}

sub checkTime
{
    my ( $this, %proc, $error ) = @_;
    my ( $condition ) = @$this{qw( condition )};
    my $len = scalar keys %proc;

    for my $cond ( @$condition )
    {
        next unless $cond =~ /^([><=])\d+$/;
        my $x = $1 eq '=' ? '=' : '';

        if( grep{ ! eval "$_->{time}$x$cond" } values %proc )
        {
            print "$cond err\n";
            $error ++;
        }
        else
        {
            print "$cond ok\n";
        }
    }
    return $error;
}

sub procByCmdline
{
     my $this = shift;
     my ( $col, $grep, $name, %proc, @proc ) = @$this{qw( col grep name  )};

     map{ push( @proc, $1 ) if m#^/proc/(\d+)$# }glob "/proc/*";

     for my $proc ( @proc )
     {
        my $x = `cat '/proc/$proc/cmdline' 2>/dev/null`;
        chomp $x;

        $x =~ s/\0//g;
        next unless ( ! $grep && $x eq $name ) || ( $grep && $x =~ /$name/ );

        $proc{$proc}{name} = $x;
        $proc{$proc}{time} = $col eq 'num' ? 1 : ( stat "/proc/$proc" )[10]; 
    }

     return %proc;
}

sub procByName
{
     my $this = shift;
     my ( $col, $grep, $name, %proc, @proc ) = @$this{qw( col grep name )};

     map{ push( @proc, $1 ) if m#^/proc/(\d+)$# }glob "/proc/*";

     for my $proc ( @proc )
     {
        my @x = `cat '/proc/$proc/status' 2>/dev/null`;
        chomp @x;

        for( @x )
        {
            my @xx = split /:/, $_, 2;
            next unless $xx[0] eq 'Name';

            $xx[1] =~ s/^\s*//;
            next unless ( ! $grep && $xx[1] eq $name ) || ( $grep && $xx[1] =~ /$name/  );

            $proc{$proc}{name} = $xx[1];
            $proc{$proc}{time} = $col eq 'num' ? 1 : ( stat "/proc/$proc" )[10];
        }
    }

     return %proc;
}

sub procByExe
{
     my $this = shift;
     my ( $col, $grep, $name, %proc, @proc ) = @$this{qw( col grep name )};

     map{ push( @proc, $1 ) if m#^/proc/(\d+)$# }glob "/proc/*";

     for my $proc ( @proc )
     {
         next unless my $x = readlink "/proc/$proc/exe";

         next unless ( ! $grep && $x eq $name ) || ( $grep && $x =~ /$name/ );

         $proc{$proc}{name} = $x;
         $proc{$proc}{time} = $col eq 'num' ? 1 : ( stat "/proc/$proc" )[10];
     }

     return %proc;
}

1;
__END__

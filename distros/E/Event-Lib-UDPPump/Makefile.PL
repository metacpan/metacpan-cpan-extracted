use 5.006;
use ExtUtils::MakeMaker;
use Config;

my %args = map { split /\s*=\s*/ } @ARGV;

# purge @ARGV of CCFLAGS

@ARGV = grep !/CCFLAGS=/, @ARGV;

sub have_libevent {
    my $CC = join " ", $args{CC} || $Config{cc}, $args{CCFLAGS}, $Config{ccflags};
    my $LIBS = $args{ LIBS } || "-levent";
    my $INC = $args{ INC } || "-I/usr/include";
    if ($^O eq "freebsd") {
      $LIBS = "$LIBS -L/usr/local/lib";
      $INC  = "$INC -I/usr/local/include";
    }
    elsif ($^O eq "darwin") {
      $LIBS = "$LIBS -L/sw/lib";
      $INC  = "$INC -I/sw/include";
    }

    print "Checking existance of libevent...";
    return 1 if system("$CC check.c $INC $LIBS") == 0 and do {
	print "yes\n";
	return 1;
    };
    print "no\n";
    return 0;
}

if (! have_libevent()) {
    die <<EOD;
*******************************************
Couldn't find libevent which is required 
for this module.

To obtain it, go to
    http://www.monkey.org/~provos/libevent/
*******************************************
EOD
}

$args{LIBS} = '-levent -lm -lpthread' if ! exists $args{LIBS};

WriteMakefile(
    NAME            => 'Event::Lib::UDPPump',
    VERSION_FROM    => 'lib/Event/Lib/UDPPump.pm', 
    PREREQ_PM       => { 'Event::Lib' => '1.00'}, 
    ABSTRACT_FROM   => 'lib/Event/Lib/UDPPump.pm', 
    AUTHOR	    => 'Clayton O\'Neill <coneill@oneill.net>',
    LIBS            => [ $args{LIBS} ], 
    INC             => $args{INC} ,
    H		    => [ qw/blocked_read.h/ ],
    XS		    => { 'UDPPump.xs' => 'UDPPump.c' },
    clean	    => { FILES => "a.out config.c" },
    OBJECT          => 'blocked_read.o UDPPump.o',
);


package MY;

# need to override here so that DEFINE=... on commandline works
# along with the DEFINEs internally diddled out by Makefile.PL
sub constants {
    my $self = shift;
    $self->{DEFINE} .= " -DHAVE_CONFIG_H";
    $self->SUPER::constants;
}

sub cflags {
    my $self = shift;
    my $flags = $self->SUPER::cflags;
    $flags =~ s/(CCFLAGS\s=\s.+)$/$1 $args{CCFLAGS}/m;
    return $flags;
    
}

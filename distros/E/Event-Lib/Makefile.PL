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
      $LIBS = "$LIBS -L/sw/lib -L/opt/local/lib";
      $INC  = "$INC -I/sw/include -I/opt/local/include";
    }

    print "Checking existance of libevent...";
    return 1 if system("$CC check.c $INC $LIBS") == 0 and do {
	print "yes\n";
	return 1;
    };
    print "no\n";
    return 0;
}

sub make_source {
    my ($pre, $src) = @_;
    open C, ">config.c" or die "Could not create config.c: $!";
    print C <<EOC;
#include <sys/time.h>
#include <sys/types.h>
#include <event.h>

$pre

int main (int argc, char **argv) {
    event_init();
    $src;
    return 0;
}
EOC
}

sub get_defines {
    # re-invent configure
    my %tests = @_;
    my $CC = $Config{cc}.' '.$Config{ccflags}.' ';
    my $LIBS = $args{ LIBS } || "-levent";
    my $INC = $args{ INC } || "-I/usr/include";
    if ($^O eq "freebsd") {
      $LIBS = "-L/usr/local/lib $LIBS";
      $INC  = "-I/usr/local/include $INC";
    }
    elsif ($^O eq "darwin") {
      $LIBS = "-L/sw/lib -L/opt/local/lib $LIBS";
      $INC  = "-I/sw/include -I/opt/local/include $INC";
    }
  
    my $DEFINE;
    print "Checking capabilities...\n";
    
    TEST: 
    while (my ($name, $val) = each %tests) {
	print "  $name...";
	make_source($val->{code_pre}, $val->{code});
	system("$CC config.c $INC $LIBS 2>/dev/null 1>/dev/null") == 0 and do {
	    print "yes\n";
	    $DEFINE .= "$val->{define} ";
	    next TEST;
	};
	print "no\n";
    }

    print "Additional defines: $args{DEFINE} $DEFINE\n\n";
    return $DEFINE;
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

$args{LIBS} = '-levent -lm' if ! exists $args{LIBS};

my $DEFINES = get_defines(
    event_priority_init =>	{   code_pre	=> '',
				    code	=> 'event_priority_init(10)',
				    define	=> '-DHAVE_PRIORITIES', },
    event_set_log_callback => {	    code_pre	=> 'void callback (int s, const char *m) { }',
				    code	=> 'event_set_log_callback(callback);',
				    define	=> '-DHAVE_LOG_CALLBACKS', },
);

#exit;

WriteMakefile(
    NAME            => 'Event::Lib',
    VERSION_FROM    => 'lib/Event/Lib.pm', 
    PREREQ_PM       => {}, 
    ABSTRACT_FROM   => 'lib/Event/Lib.pm', 
    AUTHOR	    => 'Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>',
    LIBS            => [ $args{LIBS} ], 
    INC             => $args{INC} ,
    H		    => [ qw/event_debug.h dhash.h/ ],
    XS		    => { 'Lib.xs' => 'Lib.c' },
    clean	    => { FILES => "a.out config.c" },
);


if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(EVBUFFER_EOF EVBUFFER_ERROR EVBUFFER_READ EVBUFFER_TIMEOUT
		 EVBUFFER_WRITE EVLIST_ACTIVE EVLIST_ALL EVLIST_INIT
		 EVLIST_INSERTED EVLIST_INTERNAL EVLIST_SIGNAL EVLIST_TIMEOUT
		 EVLOOP_NONBLOCK EVLOOP_ONCE EV_PERSIST EV_READ EV_SIGNAL
		 EV_TIMEOUT EV_WRITE
		 _EVENT_LOG_DEBUG _EVENT_LOG_MSG _EVENT_LOG_WARN _EVENT_LOG_ERR));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Event::Lib',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

package MY;

# need to override here so that DEFINE=... on commandline works
# along with the DEFINEs internally diddled out by Makefile.PL
sub constants {
    my $self = shift;
    $self->{DEFINE} .= " -DHAVE_CONFIG_H $DEFINES";
    $self->SUPER::constants;
}

sub cflags {
    my $self = shift;
    my $flags = $self->SUPER::cflags;
    $flags =~ s/(CCFLAGS\s=\s.+)$/$1 $args{CCFLAGS}/m;
    return $flags;
    
}

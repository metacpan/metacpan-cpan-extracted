# perform various pre-test initializations

# initialise variables describing the driver we'll test with
# and setup CLASSPATH (which needs to be done before 'use JDBC')

use Carp;
use File::Path;

use Cwd;
my $dir = cwd;
$dir =~ s:/t$::;

$::JDBC_DRIVER_CLASS = "org.apache.derby.jdbc.EmbeddedDriver";
$::JDBC_DRIVER_URL   = "jdbc:derby:derbydb;create=true";
$::JDBC_DRIVER_JAR   = "$dir/drivers/db-derby-10.1.1.0.jar";
@::JDBC_DRIVER_DBFILES = qw(derbydb derbydb.log);
die "Driver $::JDBC_DRIVER_JAR not found" unless -s $::JDBC_DRIVER_JAR;
rmtree \@::JDBC_DRIVER_DBFILES, 0;

$ENV{CLASSPATH} = join ":", $::JDBC_DRIVER_JAR, split /:/, $ENV{CLASSPATH}, -1;

# make Carp more verbose

$Carp::Verbose = 1;

# optionally enable Inline::Java verbosity

$ENV{PERL_INLINE_JAVA_DEBUG} = 0; # 0=off, 1,2=useful, 3=noisy

#

$SIG{__DIE__} = sub {
        die $@ unless ref $@;
        my $msg = $@;
        # $@->printStrackTrace; # No public method 'printStrackTrace' defined for class 'main::java::lang::NoClassDefFoundError' at test.pl line 20
        $msg = sprintf "%s (%s)", $@->toString, $msg;
        die $msg;
} if 0;

1;

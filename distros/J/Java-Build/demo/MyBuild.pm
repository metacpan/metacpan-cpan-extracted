package MyBuild;
use lib '/home/phil/Java/Build/blib/lib';
use base 'Java::Build::GenericBuild';
use Java::Build::Tasks;
use Java::Build::JVM;

my @attrs = (
    { PROJECT_DIR   => sub { die "please supply a PROJECT_DIR\n";        } },
    { PROJECTS      => sub { die "please supply a PROJECTS list\n";      } },
    { BUILD_SUCCESS => sub { die "please supply a BUILD_SUCCESS file\n"; } },
);

sub new {
    my $class = shift;
    my $self  = shift;

    $self->{ATTRIBUTES} = (\@attrs);
    Java::Build::GenericBuild::process_attrs($self);
    return bless $self, $class;
}

sub init {
    my $self = shift;
    open LOG, ">>demo.log" or die "couldn't open log\n";
}

sub compile {
    my $self         = shift;
    print LOG "compiling...\n";
    my $compiler     = Java::Build::JVM->getCompiler();

    foreach my $project (@{$self->{PROJECTS}}) {
        my $base_dir = "$self->{PROJECT_DIR}/$project->{NAME}";
        my $sources  = build_file_list(
            BASE_DIR         => $base_dir,
            INCLUDE_PATTERNS => [ qr/.java$/ ],
        );
        print LOG "compiling $base_dir @$sources\n";
        $compiler->destination($base_dir);
        eval { $compiler->compile($sources) };
        if ($@) {
            print LOG "compile failed:\n$@";
            die "compile failed\n$@";
        }
        $compiler->append_to_classpath($base_dir);
    }
}

sub make_jars {
    my $self = shift;
    print LOG "making jars...\n";

    foreach my $project (@{$self->{PROJECTS}}) {
        next if (defined $project->{DONT_JAR} and $project->{DONT_JAR});
        my $base_dir = "$self->{PROJECT_DIR}/$project->{NAME}";
        my $classes  = build_file_list(
            BASE_DIR         => $base_dir,
            EXCLUDE_PATTERNS => [ qr/.java$/ ],
            STRIP_BASE_DIR   => 1,
            QUOTE_DOLLARS    => 1,
        );
        print LOG "making jar for $project->{NAME} with @$classes\n";
        jar(
            JAR_FILE  => "$base_dir.jar",
            BASE_DIR  => $base_dir,
            FILE_LIST => $classes,
        );
    }
}

sub DESTROY {
    print LOG "build complete\n";
    close LOG;
}

package Java::JCR::Build;

use base 'Module::Build';

use File::Path;
use File::Spec;

my $maven_repo = 'http://www.ibiblio.org/maven';
my %jars = (
    'jackrabbit-1.0.jar' 
        => "$maven_repo/org.apache.jackrabbit/jars/jackrabbit-core-1.0.jar",
    'jcr-1.0.jar' 
        => 'http://www.day.com/maven/jsr170/jars/jcr-1.0.jar',
    'slf4j-jdk14-1.0.1.jar' 
        => "$maven_repo/org.slf4j/jars/slf4j-jdk14-1.0.1.jar",
    'commons-collections-3.1.jar' 
        => "$maven_repo/commons-collections/jars/commons-collections-3.1.jar",
    'xercesImpl-2.6.2.jar' 
        => "$maven_repo/xerces/jars/xercesImpl-2.6.2.jar",
    'xmlParserApis-2.0.2.jar' 
        => "$maven_repo/xerces/jars/xmlParserAPIs-2.0.2.jar",
    'derby-10.1.1.10.jar' 
        => "$maven_repo/org.apache.derby/jars/derby-10.1.1.0.jar",
    'concurrent-1.3.4.jar' 
        => "$maven_repo/concurrent/jars/concurrent-1.3.4.jar",
    'lucene-1.4.3.jar' 
        => "$maven_repo/lucene/jars/lucene-1.4.3.jar",
);

sub ACTION_get_jars {
    my $self = shift;

    eval "require LWP::UserAgent"
        or die "Failed to load LWP::UserAgent: $@";

    my $mirror_dir 
        = File::Spec->catdir($self->blib, 'lib', 'Java', 'JCR');
    mkpath( $mirror_dir, 1);

    my $ua = LWP::UserAgent->new;

    print "Checking for needed jar files...\n";
    while (my ($file, $url) = each %jars) {
        my $path = File::Spec->catfile($mirror_dir, $file);
        $self->add_to_cleanup($path);

        next if -f $path;

        my $response = $ua->mirror($url, $path);
        if ($response->is_success) {
            print "Mirroring $url to $file.\n";
        }

        elsif ($response->is_error) {
            die "An error occurred fetching $url to $file: ", 
                $response->status_line, "\n";
        }
    }
}

# my @java_src = qw(
#     src/org/perl/java/jcr/PerlSimpleCredentials.java
# );
# 
# sub ACTION_code_java {
#     my $self = shift;
# 
#     my $class_dir = File::Spec->catdir($self->blib, 'target');
#     my $jar_file = File::Spec->catfile(
#         $self->blib, 'lib', 'Java', 'JCR', 'perl-jcr.jar');
# 
#     $self->do_system('javac', '-cp', $ENV{'CLASSPATH'}, '-d', $class_dir, @java_src)
#         or die "Failed to build Java classes.\n";
#     $self->do_system('jar', 'cf', $jar_file, '-C', $class_dir, '*')
#         or die "Failed to build Jar file.\n";
# }

sub ACTION_code {
    my $self = shift;

    $self->ACTION_get_jars;
#    $self->ACTION_code_java;
    $self->SUPER::ACTION_code;
}

1

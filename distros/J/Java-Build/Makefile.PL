use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $with_complaint = <<EOJ;
You need to put Sun's tools.jar into your classpath environment
variable while installing this distribution.

EOJ
die $with_complaint unless $ENV{CLASSPATH} =~ /tools.jar/;

print <<EOJ;
See the README if the questions here don't make sense.

Do you mind small _Inline directories on your disk? [n]
EOJ
my $inlines_are_bad = <>;
my $starts_with_y   = qr/^y/i;
my $rewrite = 1 if ($inlines_are_bad =~ $starts_with_y);

if ($rewrite) {
    print "Where should I put my compiled Inline class?\n";
    print "Please specify and absolute path. [/etc/Inline]\n";
    chomp(my $dir = <>);
    $dir = "/etc/Inline" unless $dir;
    unless (-d $dir) {
        print "Should I create this directory? [y]\n";
        my $create = <>;
        if ($create =~ $starts_with_y) {
            `mkdir -p $dir`;
        }
    }

    rewrite_JVM($dir);
}

WriteMakefile(
    'NAME'		=> 'Java::Build',
    'VERSION_FROM'	=> 'Build.pm', # finds $VERSION
    'PREREQ_PM'		=> { Inline       => 0.44,
                             Inline::Java => 0.41,
                             Carp         => 0,
                             File::Find   => 0,
                             Cwd          => 0,
                             File::Temp   => 0,
                             Exporter     => 0,
                             Test::More   => 0,
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Build.pm', # retrieve abstract from module
       AUTHOR     => 'Phil Crow <philcrow2000@yahoo.com>') : ()),
);

sub rewrite_JVM() {
    my $dir = shift;

    open JVM, "Build/JVM.pm"
        or die "Couldn't read Build/JVM.pm $!\n";
    open JVM_OUT, ">Build/JVM.tmp.pm"
        or die "Couldn't write Build/JVM.tmp.pm $!\n";

    while (<JVM>) {
        if (/^#(\s+)DIRECTORY(.*)=>/) {
            print JVM_OUT " ${1}DIRECTORY${2}=> '$dir',\n";
        }
        else {
            print JVM_OUT;
        }
    }

    close JVM;
    close JVM_OUT;

    rename "Build/JVM.tmp.pm", "Build/JVM.pm";
}

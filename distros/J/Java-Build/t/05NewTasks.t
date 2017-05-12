use strict;
use warnings;

use Test::More tests => 12;

use Java::Build::Tasks;

#___________________ Read Props ________________
#eval q{
    my $bad_config = read_prop_file('t/missing.config');
    is($bad_config, undef, "attempt to read missing prop file");
#};
#like ($@, qr/Couldn.t read/, "attempt to read missing prop file");

my $config = read_prop_file('t/sample.config');
is($config->{basedir}, "/some/path", "read a config");

open PROPS, ">t/sample.properties"
    or die "Couldn't write t/sample.properties $!\n";

print PROPS <<EOP;
full.name=Java::Build::Tasks
short.name=Tasks
EOP

close PROPS;

#___________________ Update Props ________________

eval q{update_prop_file();};
like($@, qr/supply.*NAME/, "no args to update_prop_file");

update_prop_file(
    NAME      => "t/sample.properties",
    NEW_PROPS => {
        "short.name" => "MyTasks",
        "new.name"   => "Java::Build::MyTasks",
    },
);

my $new_props = read_prop_file("t/sample.properties");
my $correct_props = {
    "full.name"  => "Java::Build::Tasks",
    "short.name" => "MyTasks",
    "new.name"   => "Java::Build::MyTasks",
};

is_deeply($new_props, $correct_props, "existing props updated");

update_prop_file(
    NAME => "t/not_distributed.props",
    NEW_PROPS => {
        discussion => "This file should be created by this call",
    },
);

unless (open NOT_DIST, "t/not_distributed.props") {
    fail('props file created');
}
else {
    my $prop = join "", <NOT_DIST>;
    is (
        $prop,
        "discussion=This file should be created by this call\n",
        'props file created'
    );
}

unlink 't/not_distributed.props';

#___________________ Copy ________________

copy_file('t/file2copy', 't/copiedfile');
open ORIG, 't/file2copy';
open COPY, 't/copiedfile';
my $orig = join "", <ORIG>;
my $copy = join "", <COPY>;
close COPY;
close ORIG;

is($copy, $orig, "file copy");
unlink 't/copiedfile';

eval q{
    copy_file('t/missingfile', 't/copiedfile');
};
like($@, qr/couldn.t cp/, "bad copy");

copy_file("t/bad dir/Hello.java", "t/bad dir/manifest dir/Hello.java");
my $copy_test_text = "copy with space in source and destination";
if (-f 't/bad dir/manifest dir/Hello.java') {
    pass($copy_test_text);
    unlink 't/bad dir/manifest dir/Hello.java';
}
else {
    fail($copy_test_text);
}

#___________________ Jar Class Path ________________

my $jar_path = make_jar_classpath(DIRS => [ 't/jars/lib1', 't/jars/lib2' ]);
my @generated = sort(split(/:/, $jar_path));
my @actual   = sort qw(
    t/jars/lib1/dummy.jar
    t/jars/lib1/dummy2.jar
    t/jars/lib1/dummy3.jar
    t/jars/lib2/smarty.jar
    t/jars/lib2/smarty2.jar
    t/jars/lib2/smarty3.jar
);
is("@generated", "@actual", "make_jar_classpath");

#___________________ Purging ________________

SKIP: {
    my $make_status = mkdir 't/doomed';
    `touch t/doomed/file`;
    skip "couldn't make directory under t", 1, if ($?);

    purge_dirs('t', qw(doomed) );
    if (open DECEASED, 't/doomed/file') {
        fail("purge directory");
        close DECEASED;
    }
    else {
        pass("purge directory");
    }
}

# Insert new tests immediately above this line, mess not with logging.

#___________________ Logging ________________
my $logger = Logger->new();
Java::Build::Tasks::set_logger($logger);
eval q{update_prop_file();};

package Logger;
use Test::More;

sub new { my $class = shift; my $self = {}; bless $self, $class }
sub log {
    my $self     = shift;
    my $message  = shift;
    my $severity = shift;

    like($message, qr/didn.t supply/, "logged message");
    is($severity,  100, "log severity");
}


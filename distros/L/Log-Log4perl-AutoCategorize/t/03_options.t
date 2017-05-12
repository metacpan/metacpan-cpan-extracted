# -*- perl -*-

# tests various options that can be passed into Logger
BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.03*>, <out.options*>, <out.dflt_stdout*>;
}

use Test::More (tests => 10);
local $" = "\n\t";

my ($stdfile, $errfile) = qw( out.options.std out.options.err );

#################
diag "test options to print to stdout for; i-autoload invoke, b-build, c-category, a-caller-activity";
system "perl dflt_stdout.pl -d iabc > $stdfile 2> $errfile";

ok (!$@, 'no $@ errors');
ok (!$!, 'no $! errors');
ok (!$?, 'exited with 0');

diag "now examine output";

my ($stdout,$stderr);
{
    local $/ = undef;
    my $fh;
    open ($fh, "$stdfile");
    $stdout = <$fh>;
    open ($fh, "$errfile");
    $stderr = <$fh>;
}

ok ($stdout, "got something on stdout");

like ($stdout, qr/in Foo->bar\(\)/ms, 'found Foo->bar() unmunged');
like ($stdout, qr/in Foo->bar\(1\)/ms, 'found Foo->bar(1) unmunged');

my @munged;
while ($stdout =~ m/meth: (\w+(?:_000\d{2})?)/msg) {
    push @munged, $1;
}
@munged = sort @munged;
diag "munged names reported: \n\t@munged\n";
#printf "found %d munges\n", scalar @munged;
ok (@munged == 17, '17 munged names');

diag " for some reason, one method called from END block is un-munged\n";

my @cats;
while ($stdout =~ m/cat: (\w+(?:\.\w+)+)\n/msg) {
    push @cats, $1;
}
@cats = sort @cats;
diag "categories reported: \n\t@cats\n";
#printf "found %d categories\n", scalar @cats;
ok (@cats == 17, '17 categories');


my @builds;
while ($stdout =~ m/building.*?: (\w+(?:\.\w+)+)\n/msg) {
    push @builds, $1;
}
@builds = sort @builds;
diag "methods built: \n\t@builds\n";
#printf "found %d built methods\n", scalar @builds;
ok (@builds == 17, '17 methods built');


ok ($stderr, "got something on stderr");

#################

__END__
##########
diag "\ntest options to print to stdout for; v-verbose, f-found-opchain, m-matched-opchain, j-junk-opchain";

($stdfile, $errfile) = qw( out.options.std.1 out.options.err.1 );
system "perl dflt_stdout.pl -d vfmj > $stdfile 2> $errfile";
{
    local $/ = undef;
    my $fh;
    open ($fh, "$stdfile");
    $stdout = <$fh>;
    open ($fh, "$errfile");
    $stderr = <$fh>;
}

my @output;
while ($stdout =~ m/found op-chain: (Logger => .*?)\n/ms) {
    push @output, $1;
}
diag "found-opchains: @output\n";
#printf "found %d munges\n", scalar @munged;
ok (@output == 18, 'found 18 munged names');


__END__


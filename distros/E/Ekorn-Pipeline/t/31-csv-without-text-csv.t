use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::CSV without Text::CSV, which it only recommends
# (roadmap 2026-0049, D1): the module and Tooling load, and from_csv and
# to_csv croak when called, whether Text::CSV is missing or won't load.
# A hook at the front of @INC stands in for it, as the source given
# makes it, or missing when that's undef.

my($file, $source);


BEGIN {
    $file = 'Text/CSV.pm';    # here, as the hook runs as modules compile
    unshift @INC, sub ($, $wanted) {
        return                                      unless $wanted eq $file;
        die "Can't locate $file in \@INC (faked)\n" unless defined $source;
        return \$source;
    };
}

use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling qw(:all);

my $class = 'Ekorn::Pipeline';
my $here  = __FILE__;

subtest 'The module and Tooling load without it' => sub {
    ok !$INC{$file}, 'Text::CSV not loaded';
    is [$class->new(take(2))->(1 .. 5)], [1, 2], 'and the rest works';
};

subtest 'Missing, each function croaks when called' => sub {
    for my $function (qw(from_csv to_csv)) {
        like dies { __PACKAGE__->can($function)->(file => 'x.csv') },
            qr( \ACan't\ find\ Text::CSV,\ which\ $function\ needs;\ install\ it\ from\ CPAN\ at\ \Q$here\E\ line )x,
            $function;
    }
};

subtest 'There, but failing to load, each croaks with why' => sub {
    $source = "package Text::CSV; die qq(It's broken\\n);";
    for my $function (qw(from_csv to_csv)) {
        like dies { __PACKAGE__->can($function)->() },
            qr( \ACan't\ load\ Text::CSV,\ which\ $function\ needs:\ \S.*\ at\ \Q$here\E\ line )x,
            $function;
    }
};

done_testing;

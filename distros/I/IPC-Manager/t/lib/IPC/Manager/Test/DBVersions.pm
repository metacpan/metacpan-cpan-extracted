package IPC::Manager::Test::DBVersions;
use strict;
use warnings;

our $VERSION = '0.000037';

use Importer Importer => 'import';
our @EXPORT_OK = qw/discover_db_versions for_each_db_version/;

sub discover_db_versions {
    my @prefixes = @_;
    my $home = $ENV{HOME};
    return () unless defined $home && -d "$home/dbs";

    my @found;
    for my $prefix (@prefixes) {
        opendir(my $dh, "$home/dbs") or next;
        my @hits;
        while (my $entry = readdir($dh)) {
            next if $entry =~ /^\./;
            next unless $entry =~ /\A\Q$prefix\E-/;
            my $bin = "$home/dbs/$entry/bin";
            next unless -d $bin;
            push @hits, [$entry, $bin, $prefix];
        }
        closedir $dh;
        push @found, sort { $a->[0] cmp $b->[0] } @hits;
    }
    return @found;
}

# for_each_db_version(\@prefixes, $body)
#
# Discovers ~/dbs/<prefix>-* installations and runs $body inside a forked
# Test2::AsyncSubtest per version with $ENV{PATH} prepended with that
# version's bin dir.  Forking is required because DBIx::QuickDB driver
# packages cache resolved binary paths at module load time, which would
# otherwise pin the first-found version for the rest of the process.
#
# When ~/dbs is missing or no version directories match the prefixes,
# $body runs once at top level with name 'system' so the test falls back
# to whatever PATH already has.  The body is responsible for calling
# plan skip_all (or otherwise skipping) when no usable installation is
# available.
sub for_each_db_version {
    my ($prefixes, $body) = @_;
    my @versions = discover_db_versions(@$prefixes);

    if (!@versions) {
        $body->('system', undef, undef);
        return;
    }

    require Test2::IPC;
    require Test2::AsyncSubtest;
    for my $v (@versions) {
        my ($name, $bin, $prefix) = @$v;
        my $st = Test2::AsyncSubtest->new(name => $name);
        $st->run_fork(sub {
            local $ENV{PATH} = "$bin:$ENV{PATH}";
            $body->($name, $bin, $prefix);
        });
        $st->finish;
    }
    return;
}

1;

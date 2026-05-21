#!/usr/bin/env perl
# Object Store CLI: put / get / ls / rm / stat / mkbucket / rmbucket
#
#   perl object_cli.pl mkbucket <bucket>
#   perl object_cli.pl put      <bucket> <name> <file>
#   perl object_cli.pl get      <bucket> <name> [<file>]   # default: stdout
#   perl object_cli.pl ls       <bucket>
#   perl object_cli.pl rm       <bucket> <name>
#   perl object_cli.pl stat     <bucket>
#   perl object_cli.pl rmbucket <bucket>
#
# Connect via NATS_HOST / NATS_PORT (defaults 127.0.0.1:4222). Server
# must have JetStream enabled (nats-server --jetstream).

use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::ObjectStore;

my $cmd    = shift @ARGV // usage();
my $bucket = shift @ARGV // usage();

my $nats = EV::Nats->new(
    host       => $ENV{NATS_HOST} // '127.0.0.1',
    port       => $ENV{NATS_PORT} // 4222,
    on_error   => sub { die "nats: $_[0]\n" },
);
my $js = EV::Nats::JetStream->new(nats => $nats);
my $os = EV::Nats::ObjectStore->new(js => $js, bucket => $bucket);

my $exit = 0;
my %dispatch = (
    mkbucket => \&do_mkbucket,
    rmbucket => \&do_rmbucket,
    put      => \&do_put,
    get      => \&do_get,
    ls       => \&do_ls,
    rm       => \&do_rm,
    stat     => \&do_stat,
);
my $fn = $dispatch{$cmd} or usage();
$fn->();
EV::run;
exit $exit;

sub finish {
    my ($err) = @_;
    if ($err) { warn "error: $err\n"; $exit = 1 }
    $nats->disconnect;
    EV::break;
}

sub do_mkbucket {
    $os->create_bucket({}, sub { finish($_[1]) });
}

sub do_rmbucket {
    $os->delete_bucket(sub { finish($_[1]) });
}

sub do_put {
    my $name = shift @ARGV // usage();
    my $file = shift @ARGV // usage();
    open my $fh, '<', $file or die "open $file: $!";
    binmode $fh;
    local $/; my $data = <$fh>;
    close $fh;
    $os->put($name, $data, sub {
        my ($info, $err) = @_;
        finish($err) if $err;
        return if $err;
        print STDERR "stored $info->{size} bytes in $info->{chunks} chunks\n";
        finish();
    });
}

sub do_get {
    my $name = shift @ARGV // usage();
    my $file = shift @ARGV;  # optional; default stdout
    $os->get($name, sub {
        my ($data, $err) = @_;
        return finish($err) if $err;
        return finish('object not found') unless defined $data;
        if ($file) {
            open my $fh, '>', $file or die "open $file: $!";
            binmode $fh;
            print $fh $data;
            close $fh;
            print STDERR "wrote ", length($data), " bytes to $file\n";
        } else {
            binmode STDOUT;
            print $data;
        }
        finish();
    });
}

sub do_ls {
    $os->list(sub {
        my ($names, $err) = @_;
        return finish($err) if $err;
        print "$_\n" for sort @$names;
        finish();
    });
}

sub do_rm {
    my $name = shift @ARGV // usage();
    $os->delete($name, sub { finish($_[1]) });
}

sub do_stat {
    $os->status(sub {
        my ($s, $err) = @_;
        return finish($err) if $err;
        printf "bucket: %s\nbytes:  %s\nsealed: %s\n",
               $s->{bucket}, $s->{bytes}, $s->{sealed} ? 'yes' : 'no';
        finish();
    });
}

sub usage {
    print STDERR <<'USAGE';
usage:
  object_cli.pl mkbucket <bucket>
  object_cli.pl put      <bucket> <name> <file>
  object_cli.pl get      <bucket> <name> [<file>]
  object_cli.pl ls       <bucket>
  object_cli.pl rm       <bucket> <name>
  object_cli.pl stat     <bucket>
  object_cli.pl rmbucket <bucket>
USAGE
    exit 2;
}

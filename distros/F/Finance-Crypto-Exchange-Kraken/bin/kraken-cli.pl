#!perl
use warnings;
use strict;

# ABSTRACT: Kraken API via the CLI
# PODNAME: kraken-cli

use Getopt::Long;
use Pod::Usage;
use Finance::Crypto::Exchange::Kraken;
use File::Spec::Functions qw(catfile);
use File::Basename;
use YAML::Tiny;
use Data::Dumper;
use JSON;

my @opts = qw(
    help
    create-config
    list
    command=s@
);
my %opts = (
    config => catfile($ENV{HOME}, qw( .config kraken-exchange cli.conf))
);

{
    local $SIG{__WARN__};
    my $ok = eval { GetOptions(\%opts, @opts); };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});

if ($opts{list}) {
    my @methods = Finance::Crypto::Exchange::Kraken->supported_methods;
    foreach (@methods) {
        print $_, $/;
    }
    exit 0;
}

if ($opts{'create-config'}) {

    if (-f $opts{config}) {
        die "File $opts{config} already exists!\n";
    }

    my $dir = dirname($opts{config});
    if (!-d $dir) {
        mkdir $dir;
    }
    open my $fh, '>', $opts{config};
    my @contents = qq{---
key: XXXXX
secret: XXXXX
};
    foreach(@contents) {
        print $fh "$_ $/";
    }
    close($fh);
    chmod 0400, $opts{config};

}

if (-f $opts{config}) {
    my $contents = YAML::Tiny->read($opts{config})->[0];

    foreach (keys %$contents) {
        $opts{$_} = $contents->{$_};
    }
}

my $command = delete $opts{command} // 'get_server_time';

my $kraken = Finance::Crypto::Exchange::Kraken->new(%opts);

sub _exec_kraken {
    my $command = shift;

    if ($kraken->can($command)) {
        print JSON::encode_json($kraken->$command), $/;
        return;
    }
    die sprintf(
        "Unable to execute command %s!\nPlease use one of the following: %s\n",
        $command, join(", ", $kraken->supported_methods)
    );
}


if (ref $command) {
    foreach (@$command) {
        _exec_kraken $_;
    }
}
else {
    _exec_kraken $command;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

kraken-cli - Kraken API via the CLI

=head1 VERSION

version 0.004

=head1 SYNOPSIS

kraken-cli.pl --help [ OPTIONS ]

=head1 OPTIONS

=over

=item * --help (this help)

=item * --command <command>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

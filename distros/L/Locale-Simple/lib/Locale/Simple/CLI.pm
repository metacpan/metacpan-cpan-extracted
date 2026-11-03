package Locale::Simple::CLI;
# ABSTRACT: Command line interface behind the locale-simple command
our $VERSION = '0.200';

use strict;
use warnings;

use Getopt::Long ();
use File::Basename ();
use Locale::Simple ();
use Locale::Simple::PO2JSON ();
use Locale::Simple::Scraper ();

my $USAGE = <<'END';
Usage: locale-simple COMMAND [ARGS]

Commands:
  scrape [OPTIONS]                 find translation calls in the sources below the
                                   current directory (locale-simple scrape --help)
  po2json [--domain NAME] [--pretty] FILE.po
                                   convert a PO file to JSON for the browser
  help                             show this text
  --version                        show the version
END

sub run {
    my (@argv) = @_;

    my $cmd = @argv ? shift @argv : '';
    if ( $cmd eq 'help' or $cmd eq '--help' or $cmd eq '-h' ) {
        print STDOUT $USAGE;
        return 0;
    }
    if ( $cmd eq '--version' ) {
        print STDOUT "locale-simple $Locale::Simple::VERSION\n";
        return 0;
    }
    return _scrape(@argv) if $cmd eq 'scrape';
    return _po2json(@argv) if $cmd eq 'po2json';

    print STDERR $cmd eq '' ? "Missing command\n" : "Unknown command: $cmd\n";
    print STDERR $USAGE;
    return 2;
}

sub _scrape {
    my (@argv) = @_;
    eval { Locale::Simple::Scraper::scrape(@argv); 1 } or do {
        my $err = $@;
        if ( ref $err and ref $err eq 'Locale::Simple::Scraper::BadCall' ) {
            print STDERR $err->{message}, Locale::Simple::Scraper::usage();
            return 2;
        }
        $err .= "\n" unless $err =~ /\n\z/;
        print STDERR $err;
        return 1;
    };
    return 0;
}

sub _po2json {
    my (@argv) = @_;
    my ( $domain, $pretty );
    my $parser = Getopt::Long::Parser->new( config => ['no_ignore_case'] );
    my $ok = do {
        local $SIG{__WARN__} = sub { print STDERR @_ };
        $parser->getoptionsfromarray( \@argv, 'domain=s' => \$domain, 'pretty' => \$pretty );
    };
    if ( !$ok or @argv != 1 ) {
        print STDERR "po2json needs exactly one PO file\n" if $ok;
        print STDERR $USAGE;
        return 2;
    }
    my ($file) = @argv;
    $domain = File::Basename::basename( $file, '.po', '.pot' ) unless defined $domain;
    my $json = eval {
        Locale::Simple::PO2JSON::data2json(
            Locale::Simple::PO2JSON::po2data( $file, domain => $domain ),
            pretty => $pretty ? 1 : 0,
        );
    };
    if ( !defined $json ) {
        my $err = $@;
        $err .= "\n" unless $err =~ /\n\z/;
        print STDERR $err;
        return 1;
    }
    print STDOUT $json, "\n";
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple::CLI - Command line interface behind the locale-simple command

=head1 VERSION

version 0.200

=head1 SYNOPSIS

  use Locale::Simple::CLI;
  exit Locale::Simple::CLI::run(@ARGV);

=head1 DESCRIPTION

Implements the commands of C<bin/locale-simple>. C<run> returns the exit code
and never calls C<exit>, so tests and packed binaries behave the same way.

=head1 FUNCTIONS

=head2 run(@argv)

Runs the command named by the first argument and returns the exit code:
C<0> on success, C<1> when the command fails (message on STDERR), C<2> for a
bad call: a missing or unknown command, bad options or arguments (usage
on STDERR).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/locale-simple/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software, licensed under:

  The MIT (X11) License

=cut

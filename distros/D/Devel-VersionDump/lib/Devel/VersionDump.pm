package Devel::VersionDump;

use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Devel::VersionDump - Dump loaded module versions to the console

=head1 VERSION

0.02

=head1 SYNOPSIS

  perl -MDevel::VersionDump your-script.pl

  use Devel::VersionDump;

  use Devel::VersionDump '-stderr';

  use Devel::VersionDump qw(dump_versions);
  # later...
  dump_versions;

=head1 DESCRIPTION

This module prints a sorted list of modules used by
your program to stdout.  It does this by walking C<%INC>
in Perl's C<INIT> phase.

=head1 IMPORT OPTIONS

=over

=item -stderr

Tells the dumper to print to stderr instead of stdout.

=item dump_versions

Exports the C<dump_versions> function into the caller's namespace,
and turns off the automatic printing in the C<INIT> phase.  Dumping
versions is then achieved by calling C<dump_versions>.

=back

=head1 FUNCTIONS

=cut

my $stderr = 0;
my $automatic = 1;

=head2 dump_versions

Dumps versions to STDOUT or STDERR, depending on if '-stderr' was
specified in import.

=cut

sub dump_versions {
    my $oldfh;

    $oldfh = select(STDERR) if $stderr;

    print "Perl version: $^V on $^O ($^X)\n";
    my @modules;
    my ($max_mod_len, $max_vers_len) = (0, 0);
    foreach my $module (sort keys %INC) {
        $module =~ s/\//::/g;
        $module =~ s/\.pm$//;

        my $version = eval "\$${module}::VERSION";
        $version = 'Unknown' unless defined $version;
        push @modules, [$module, $version];

        if(length($module) > $max_mod_len) {
            $max_mod_len = length($module);
        }
        if(length($version) > $max_vers_len) {
            $max_vers_len = length($version);
        }
    }
    my $format = "%-${max_mod_len}s - %${max_vers_len}s\n";
    foreach my $pair (@modules) {
        my ($module, $version) = @$pair;
        printf $format, $module, $version;
    }

    select($oldfh) if $stderr;
}

sub import {
    shift;
    foreach (@_) {
        if($_ eq '-stderr') {
            $stderr = 1;
        } elsif($_ eq 'dump_versions') {
            $automatic = 0;
            my $pkg = caller;
            no strict 'refs';
            *{$pkg . '::dump_versions'} = \&dump_versions;
        }
    }
}

INIT {
    dump_versions if $automatic;
}

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Devel-VersionDump at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-VersionDump>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

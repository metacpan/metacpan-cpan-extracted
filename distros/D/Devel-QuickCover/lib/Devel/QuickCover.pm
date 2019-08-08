package Devel::QuickCover;

use strict;
use warnings;
use Carp 'croak';
use XSLoader;

our $VERSION = '0.900012';

XSLoader::load( 'Devel::QuickCover', $VERSION );

my %DEFAULT_CONFIG = (
    noatexit         => 0,      # Don't register an atexit handler to dump and cleanup
    nostart          => 0,      # Don't start gathering coverage information on import
    nodump           => 0,      # Don't dump the coverage report at the END of the program
    output_directory => '/tmp', # Write report to that directory
    metadata         => {}    , # Additional context information
);
our %CONFIG;

sub import {
    my ($class, @opts) = @_;

    croak('Invalid argument to import, it takes key-value pairs. FOO => BAR')
        if 1 == @opts % 2;
    my %options = @opts;

    %CONFIG = %DEFAULT_CONFIG;
    for (keys %options) {
        if (exists $DEFAULT_CONFIG{$_}) {
            $CONFIG{$_} = delete $options{$_};
        }
    }

    if (keys %options > 0) {
        croak('Invalid import option(s): ' . join ',', keys %options);
    }

    if (!$CONFIG{'nostart'}) {
        Devel::QuickCover::start();
    }
}

sub set_output_directory {
    my ($dir) = @_;
    return unless $dir;

    $CONFIG{output_directory} = $dir;
}

sub set_metadata {
    my ($data) = @_;
    return unless $data;

    $CONFIG{metadata} = $data;
}

END {
    Devel::QuickCover::end($CONFIG{'nodump'});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Devel::QuickCover - Quick & dirty code coverage for Perl

=head1 VERSION

Version 0.900012

=head1 SYNOPSIS

    use Devel::QuickCover;
    my $x = 1;
    my $z = 1 + $x;

=head1 DESCRIPTION

The following program sets up the coverage hook on C<use> and dumps
a report (to C</tmp> by default) at the end of execution.

    use Devel::QuickCover;
    my $x = 1;
    my $z = 1 + $x;

The following program sets up the coverage hook on C<start()> and
dumps a report to C<some_dir> on C<end()>, at which point
the coverage hook gets uninstalled. So in this case, we only get
coverage information for C<bar()>. We also get the specified metadata
in the coverage information. We also ask not to register an atexit()
handler to dump cover data / cleanup; it will be done from C<end()>.

    use Devel::QuickCover (
      nostart => 1,
      nodump => 1,
      noatexit => 1,
      output_directory => "some_dir/",
      metadata => { git_tag = "deadbeef" });

    foo();
    Devel::QuickCover::start();
    bar();
    Devel::QuickCover::end();
    baz();

For now, we support calling C<start()> only once.

When you call C<end()>, you can optionally pass a C<nodump>
boolean argument, to indicate whether you wish to skip generating
the cover files.

=head1 Use with Devel::Cover

Devel::QuickCover is distributed with the scripts qc-aggregate.pl and
qc-html.pl that can be used to convert its output into a format that
Devel::Cover understands. Once you have generated your coverage reports,
aggregate them by running

    qc-aggregate.pl

and convert them into the Devel::Cover database format by running

    qc-html.pl

Then you can view the reports with the standard Devel::Cover tools.

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Andreas Guðmundsson C<< andreasg AT nasarde DOT org >>

=item * Andrei Vereha C<< avereha AT cpan DOT org >>

=item * Mattia Barbon

=back

=head1 THANKS

=over 4

=item * p5pclub

=back

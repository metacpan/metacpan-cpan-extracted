#!/usr/bin/perl
use strict;
use warnings;
use Devel::Memalyzer;
use Devel::Memalyzer::Runner;
use Devel::Memalyzer::Combine qw/combine/;

if ( grep { m/^-+h(elp)?$/ } @ARGV ) {
    print <<EOT;
Usage: $0 output.file thing_to_run [args_for_thing ...]

    - Will refuse to override existing output file.
    - Simply joins everything after the output file and uses it as the argument
      for exec.

    This program will fork and run the specified program. While the child is
    running the parent will collect memory usage information about it at an
    interval. Headers and data will be written into 2 different file to be
    combined later.

    Data is written incrementally to your output file with .raw appended to it.
    When the script finishes it will use Devel::Memalyzer::Combine to properly
    format the data and write it to your output file. If needed you can
    manually run memalyzer-combine.pl to merge your .raw and .head files.

    There are 2 environment variables you can use to control the run:

    MEMALYZER_PLUGINS - A comma seperated list of plugins to use, you must
        exclude the 'Devel::Memalizer::Plugin::' portion and include only the
        remaining portion of the namespace.
        Example:
        MEMALYZER_PLUGINS='ProcStatus' loads Devel::Memalizer::Plugin::ProcStatus

    MEMALYZER_INTERVAL - Specify the interval between data collections, default
        is 1. Values are in seconds, decimal values are supported through
        Time::HiRes;

EOT
exit;
}

my $output = shift( @ARGV );
my $command = join( ' ', @ARGV );

my @plugins = $ENV{ MEMALYZER_PLUGINS }
    ? ( split( /\s*,\s*/, $ENV{ MEMALYZER_PLUGINS }))
    : -e '/proc' ? ('ProcStatus')
                 : die( "No Plugins" );

#init the singleton
Devel::Memalyzer->init(
    output   => $output,
    plugins  => [ map { 'Devel::Memalyzer::Plugin::' . $_ } @plugins ],
);

#run the program
Devel::Memalyzer::Runner->new(
    command => $command,
    interval => $ENV{ MEMALYZER_INTERVAL } || 1,
)->run;

Devel::Memalyzer->singleton->finish;

combine( $output );

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation


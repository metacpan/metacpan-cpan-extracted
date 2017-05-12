# Copyright 2009-2012, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::App::ProveCover;

use strict;
use warnings;

our $VERSION = "0.05";

use Devel::CoverReport 0.05;

use App::Prove 3.11;
use Carp;
use Cwd;
use File::Path qw( rmtree );
use Getopt::Long 2.36 qw( GetOptionsFromArray );

=encoding UTF-8

=head1 NAME

Devel::CoverReport::App::ProveCover - Implementation of the C<prove_cover> command

=head1 SYNOPSIS

This module is a base for L<prove_cover> - You can use it to make Your own derivatives of this command, that will suit Your purpose better.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item main

Main entry point. Executed by C<prove_cover>

=cut
sub main { # {{{
    my @cmd_params = @_;

    # Strip 'our' parameters.
    my %cover_report_options = (
        'no_report' => q{},
        'cover_db'  => q{},
    );

    Getopt::Long::Configure(qw( pass_through no_auto_help ));
    GetOptionsFromArray(
        \@cmd_params,
        \%cover_report_options,
        qw(
            cover_db=s
            no_report
        )
    );

    my $db_path = ( $cover_report_options{'cover_db'} or getcwd() . '/cover_db/' );
    mkdir $db_path;

    # Step 1: Prepare 'prove'
    my $app = App::Prove->new;
    $app->process_args(@cmd_params);
    $app->{'exec'} = q{/usr/bin/perl -MDevel::Cover=-db,} . $db_path;

    # Step 2: Cleanup.
    if (not $app->{'dry'} and not $app->{'help'} and -d $db_path . q{/runs}) {
        rmtree('cover_db', { keep_root => 1, });
    }

    # Step 3: Run 'prove'
    $app->run;

    # Step 4: run 'cover_report'
    if ($cover_report_options{'no_report'}) {
        print "Coverage report was not generated, use cover_report command to do that.\n";
    }
    elsif (not $app->{'dry'} and not $app->{'help'}) {
        if (-d $db_path . q{/runs}) {
            my $cover_report = Devel::CoverReport->new(
                cover_db  => $db_path,
                output    => $db_path,
                formatter => 'Html',

                criterion => { 'statement' => 1, 'branch' => 1, 'condition' => 1, 'path' => 1, 'subroutine' => 1, 'pod' => 1, 'time' => 1, 'runs' => 1 },
                report    => { 'summary'   => 1, 'index'  => 1, 'coverage'  => 1, 'runs' => 1, 'run-details' => 1, vcs => 1,},

                exclude     => [],
                exclude_dir => [],
                exclude_re => [],
                include => [],
                include_dir => [],
                include_re => [ q{.} ],
                mention => [],
                mention_dir => [ @INC ],
                mention_re => [],

                jobs => ( $app->{'jobs'} or 1 ),

                quiet   => 0,
                summary => 1,
                verbose => 0,
            );

            $cover_report->make_report();
        }
        else {
            print "Directory 'cover_db' was not created, coverage report skipped.\n";
        }
    }

    return 0; # Temporarly hard-coded :(
} # }}}

1;

__END__

=back

=head1 LICENCE

Copyright 2009-2012, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker


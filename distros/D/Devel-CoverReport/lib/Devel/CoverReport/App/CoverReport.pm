# Copyright 2009-2012, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::App::CoverReport;

use strict;
use warnings;

our $VERSION = "0.05";

use Devel::CoverReport 0.05;

use Carp;
use Getopt::Long 2.36 qw( GetOptionsFromArray );
use Pod::Usage;

=head1 NAME

Devel::CoverReport::App::CoverReport - implement the C<cover_report> command line utility.

See: L<cover_report|cover_report> manual.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item main

Main entry point.

Parameters: command line options.

=cut
sub main { # {{{
    my @cmd_params = @_;

    my %raw_options = (
        'cover_db'  => q{},
        'formatter' => q{},

        'help'    => undef,
        'version' => undef,
        'verbose' => undef,
        'quiet'   => undef,
        'summary' => undef,

        'jobs' => 1,

        'cover_db'  => q{},
        'formatter' => q{},
        'output'    => q{},

        'criterion' => [],
        'report'    => [],

        'exclude'     => [],
        'exclude_dir' => [],
        'exclude_re'  => [],
        'include'     => [],
        'include_dir' => [],
        'include_re'  => [],
        'mention'     => [],
        'mention_dir' => [],
        'mention_re'  => [],
    );

    Getopt::Long::Configure ("bundling");
    GetOptionsFromArray(
        \@cmd_params,
        \%raw_options,
        qw(
            help|h
            verbose|v
            version|V
            quiet|q
            summary|s

            jobs|j=i

            cover_db|d=s
            formatter|f=s
            output|o=s
            criterion|c=s
            report|r=s

            exclude=s
            exclude_dir=s
            exclude_re=s
            include=s
            include_dir=s
            include_re=s
            mention=s
            mention_dir=s
            mention_re=s
        )
    );

    # Help/Version - simplest command line options, that cause the script to abort it's work.
    if ($raw_options{'help'}) {
        pod2usage( { -verbose => 1 } );
    }
    if ($raw_options{'version'} or $raw_options{'V'}) {
        print "cover_report V$VERSION Copyright 2009-2011 Bartłomiej Syguła (perl\@bs502.pl)\n";
        exit;
    }

    # Handle more advanced options.
    my %run_options = cover_run_options(%raw_options);

    my $cover_report = Devel::CoverReport->new(%run_options);

    return $cover_report->make_report();
} # }}}

=item cover_run_options

Process command-line options known by Devel::Cover.

=cut
sub cover_run_options { # {{{
    my %raw_options = @_;

    if (not $raw_options{'cover_db'}) {
        $raw_options{'cover_db'} = 'cover_db';
    }

    if (not $raw_options{'output'}) {
        $raw_options{'output'} = $raw_options{'cover_db'};
    }

    if (not $raw_options{'formatter'}) {
        $raw_options{'formatter'} = 'Html';
    }

    my %run_options = (
        'cover_db'  => $raw_options{'cover_db'},
        'formatter' => $raw_options{'formatter'},
        'output'    => $raw_options{'output'},
        'jobs'      => $raw_options{'jobs'},
    );

    # Work out trigger options:
    foreach my $option (qw( verbose quiet summary )) {
        if ($raw_options{$option}) {
            $run_options{$option} = 1;
        }
        else {
            $run_options{$option} = 0;
        }
    }

    # Handle 'all/none/selected'-type of options.
    my %allowed_selections = (
        criterion => {
            'statement'  => 1,
            'branch'     => 1,
            'condition'  => 1,
            'path'       => 1,
            'subroutine' => 1,
            'pod'        => 1,
            'time'       => 1,
        },
        report => {
            'summary'     => 1,
            'index'       => 1,
            'coverage'    => 1,
            'runs'        => 1,
            'run-details' => 1,
            'vcs'         => 1,
        },
    );
    foreach my $option (qw( report criterion )) {
        # If not specified, we assume: gimme all You got ;)
        if (not scalar @{ $raw_options{$option} } ) {
            $raw_options{$option} = [ 'all' ];
        }

        my @strings;
        foreach my $string (@{ $raw_options{$option} }) {
            push @strings, ( split m{\,[\s]*}s, $string );
        }

        foreach my $string (@strings) {
            if ($string eq 'all') {
                foreach my $_string (keys %{ $allowed_selections{$option} }) {
                    $run_options{$option}->{ $_string } = 2;
                }

                # There is no much sense in checking other strings...
                last;
            }

            if ($allowed_selections{$option}->{$string}) {
                $run_options{$option}->{ $string } = 1;
                next;
            }

            pod2usage("Unsupported value for $option: " . $string);
        }
    }

    # Handle option lists...
    my %item_used;
    foreach my $option (qw( exclude exclude_dir exclude_re include include_dir include_re mention mention_dir mention_re )) {
        if (scalar @{ $raw_options{$option} }) {
            $item_used{$option} = 1;
        }

        $run_options{$option} = $raw_options{$option}
    }

    # If no selection-related options ware used, set sane defaults.
    if (not scalar %item_used) {
        # Passing a copy of the array should be safer, right? ;)
        $run_options{'mention_dir'} = [ @INC ];
    }
    # If some options ware used, but 'include' was not defined - we MUST provide some sane default.
    # If we do not do it, no file will be selected, which probably is not user expects.
    if (not $item_used{'include'} and not $item_used{'include_dir'} and not $item_used{'include_re'}) {
        $run_options{'include_re'} = [ '.' ]; # Something, that always matches.
    }
    
    return %run_options;
} # }}}

1;

=back

=head1 LICENCE

Copyright 2009-2012, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker


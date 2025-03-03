package Games::Solitaire::BlackHole::Test;

use strict;
use warnings;

use Test::More;

use Dir::Manifest::Slurp qw/ as_lf /;
use Test::Differences    qw/ eq_or_diff /;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw( _test_multiple_verdict_lines )] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
require Exporter;

# We intend this test subroutine to be used by more than one
# subproject.
sub _test_multiple_verdict_lines
{
    my %is_verdict_line = map { $_ => 1, }
        ( "Solved!", "Unsolved!", "Exceeded max_iters_limit !" );
    my ($args) = @_;
    my ( $name, $expected_files_checks, $want, $input_lines ) =
        @{$args}{qw/ name expected_files_checks expected_results input_lines/};
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return subtest $name => sub {
        plan tests => 2;
        $input_lines =
            [ map { my $l = as_lf($_); chomp $l; $l } @$input_lines ];
        my @matches;
        my $deal_idx = 0;
        while (@$input_lines)
        {
            my $dealstart = shift @$input_lines;
            my ($fn) = $dealstart =~ /^\[\= Starting file (\S+) \=\]$/ms
                or die "cannot match";
            if ( not $expected_files_checks->( $deal_idx, $fn ) )
            {
                die "filename check";
            }
            my $dealverdict = shift @$input_lines;
            if ( $is_verdict_line{$dealverdict} )
            {
                push @matches, $dealverdict;
            }
            else
            {
                die "mismatch";
            }
            my $at_most_num_cards__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
                /^At most (?:(?:0)|(?:[1-9][0-9]*)) cards could be played\.\z/ms
                )
            {
                $at_most_num_cards__line = 1;
                shift @$input_lines;
            }
            my $traversed_states_count__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
/^Total number of states checked is (?:(?:0)|(?:[1-9][0-9]*))\.\z/ms,
                )
            {
                $traversed_states_count__line = 1;
                shift @$input_lines;
            }
            my $generated_states_count__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
                /^This scan generated (?:(?:0)|(?:[1-9][0-9]*)) states\.\z/ms )
            {
                $generated_states_count__line = 1;
                shift @$input_lines;
            }
            if (0)
            {
                while ( @$input_lines and $input_lines->[0] !~ /^\[\= /ms )
                {
                    diag( "unrecognised: '" . $input_lines->[0] . "'" );
                    shift @$input_lines;
                }
            }
            my $dealend = shift @$input_lines;
            if ( $dealend ne "[= END of file $fn =]" )
            {
                die "dealend mismatch";
            }
            if ( not $at_most_num_cards__line )
            {
                die "At most cards played line is absent";
            }
            if ( not $traversed_states_count__line )
            {
                die "'checked states' line is absent";
            }
            if ( not $generated_states_count__line )
            {
                die "'This scan generated' line is absent";
            }
        }
        continue
        {
            ++$deal_idx;
        }

        is( scalar(@matches), scalar(@$want), "lines count." );

        eq_or_diff( [@matches], [@$want], "expected results.", );
    };
}

1;

__END__

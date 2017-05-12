#!/usr/local/perl -w

# Test what is displayed for help usage.

use strict;
use vars qw($true_syntax);

use Getopt::Yagow;
use Test::More tests => 18;

my( $opt, $cmd,$verbose,$help_text);

$opt = Getopt::Yagow->new->load_options;

local %SIG;

# Test what is displayed for help usage.
#
# Format:
#   ( [ command_line_args => -verbose value ], ... )
#
# Expected:
# -verbose => 0   -- ^Usage:
# -verbose => 1   -- ^Usage & ^Options and Arguments:
# -verbose => 2   -- ^NAME  & ^SYNOPSIS
#
foreach 
( 
          ['--help' => 0], ['--help' =>1], ['--help' =>2],
          ['--h' => 0],    ['--h' =>1],    ['--h' =>2],
          ['--?' => 0],    ['--?' =>1],    ['--?' =>2]
)
{
    ($cmd,$verbose) = @$_; 
    $help_text = $opt->test_syntax( $cmd, $verbose );

    SWITCH:
    {
        $cmd =~ /h(elp)?|\?$/ && $verbose == 0 && do
        {
            ok( $true_syntax,"Test syntax: '$cmd'");
            ok(length($help_text) && $help_text =~ /Usage:/ && $help_text !~ /Options and Arguments:/, 
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };

        $cmd =~ /h(elp)?|\?$/ && $verbose == 1 && do
        {
            ok( $true_syntax,"Test syntax: '$cmd'");
            ok(length($help_text) && $help_text =~ /Usage:/ && $help_text =~ /Options and Arguments:/,
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };

        $cmd =~ /h(elp)?|\?$/ && $verbose == 2 && do
        {
            ok( $true_syntax,"Test syntax: '$cmd'");
            ok(length($help_text) && $help_text =~ /NAME/ && $help_text =~ /SYNOPSIS/,
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };
    }
}

#----------------------------------------------------------------------------------------
# FUNCTIONS.

sub Getopt::Yagow::test_syntax
{
    my $opt = shift;

    my ($cmd,$verbose) = @_; #($_->[0],$_->[1]);

    #print "# '$cmd' $verbose\n";

    open( OUT_TEXT, '>options.out') || die "Can't open options.out: $!\n";

    my $msg = 'simple2.t is a test file for Getopt::Yagow module. By Enrique Castilla. Dic-2002';
    my $usage_opts = {-msg => $msg,-exitval => 'noexit',-output => \*OUT_TEXT,-verbose => $verbose};
    @ARGV = ( $cmd );

    # For trapp incorrect syntax in command line.
    $true_syntax = 1;
    %SIG = ( __WARN__ => sub { $true_syntax = 0; } );

    $opt->parse_cmd_line($usage_opts,$usage_opts);

    # Restore handler.
    %SIG = ( __WARN__ => 'DEFAULT' );

    close OUT_TEXT;
    
    local $/ = undef;
    open( OUT_TEXT, '<options.out') || die "Can't open options.out: $!\n";
    my $help_text = <OUT_TEXT>;
    close OUT_TEXT;

    return $help_text;
}

__END__

=head1 NAME

simple2.t - Test file for Getopt::Yagow module. Test what is displayed for help usage.

=head1 SYNOPSIS

    % perl simple2.t

=head1 DESCRIPTION

Test file for Getopt::Yagow module. Test what is displayed for help usage.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item there is no options

=back

#!/usr/local/perl -w

# Test wrong syntaxes (with args) and what is displayed for them.

use strict;
use vars qw($opt $true_syntax);

use Getopt::Yagow;
use Test::More tests => 16;

my( %opts_spec,@cmd,@cmd_lines,$cmd,$verbose,$usage_text);

%opts_spec = (
                    'option0|opt0|0=s'  => undef,   # Mandatory 
                    'option1|opt1|1=s'  => 'one'    # Optional, but if specified needs argument string
             );

&show_options_spec;

$opt = Getopt::Yagow->new;
$opt->load_options( \%opts_spec );

local %SIG;

# Test for wrong syntaxes.
#

@cmd = ( '' );
&test_syntax( @cmd, 0);
ok( $true_syntax==0,'Wrong syntax (one argument is mandatory): \''.join(' ',@cmd)."'");

@cmd = ( '--unknown_arg' );
&test_syntax( @cmd, 0);
ok( $true_syntax==0,'Wrong syntax (unknown argument): \''.join(' ',@cmd)."'");

@cmd = ( '--option0' );
&test_syntax( @cmd, 0);
ok( $true_syntax==0,'Wrong syntax (--option0 requires a val): \''.join(' ',@cmd)."'");

@cmd = ( '--option0=string', '--option1' );
&test_syntax( @cmd, 0);
ok( $true_syntax==0,'Wrong syntax (--option1 requires a val): \''.join(' ',@cmd)."'");

# Format:
# ( [ cmd_line_arg => -verbose value ], ... )
#
@cmd_lines = (

          ['' => 0], ['' => 1], ['' => 2],
          ['--unknown_arg' => 0], ['--unknown_arg' => 1], ['--unknown_arg' => 2],
          ['--option0' => 0],     ['--option0' => 1],     ['--option0' => 2],      

          ['--option0=string --option1' => 0], 
          ['--option0=string --option1' => 1], 
          ['--option0=string --option1' => 2]
);

# Test what is displayed for wrong syntax.
#
foreach ( @cmd_lines )
{
    ($cmd,$verbose) = @$_;

    if( $cmd )
    {
        @cmd = split(/\s+/,$cmd);
        $usage_text = &test_syntax( @cmd, $verbose);
    }
    else
    {
        $usage_text = &test_syntax( $verbose);
    }

    SWITCH:
    {
        $verbose == 0 && do
        {
            ok(length($usage_text) && $usage_text =~ /Usage:/ && $usage_text !~ /Options and Arguments:/, 
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };

        $verbose == 1 && do
        {
            ok(length($usage_text) && $usage_text =~ /Usage:/ && $usage_text =~ /Options and Arguments:/,
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };

        $verbose == 2 && do
        {
            ok(length($usage_text) && $usage_text =~ /NAME/ && $usage_text =~ /SYNOPSIS/,
               "'$cmd' with -verbose => $verbose displays what expected");
            last SWITCH;
        };
    }
}


#----------------------------------------------------------------------------------------
# FUNCTIONS.


sub test_syntax
{
    my $verbose = pop @_;

    open( OUT_TEXT, '>options.out') || die "Can't open options.out: $!\n";

    my $msg = 'simple2.t is a test file for Getopt::Yagow module. By Enrique Castilla. Dic-2002';
    my $usage_opts = {-msg => $msg,-exitval => 'noexit',-output => \*OUT_TEXT,-verbose => $verbose};

    # For trapp incorrect syntax in command line.
    $true_syntax = 1;
    %SIG = ( __WARN__ => sub { $true_syntax = 0; } );

    @ARGV = @_ if @_;
    $opt->parse_cmd_line($usage_opts,$usage_opts);

    # Restore handler.
    %SIG = ( __WARN__ => 'DEFAULT' );

    close OUT_TEXT;
    
    local $/ = undef;
    open( OUT_TEXT, '<options.out') || die "Can't open options.out: $!\n";
    my $usage_text = <OUT_TEXT>;
    close OUT_TEXT;

    return $usage_text;
}

sub show_options_spec
{
    while( my($opt_spec,$default) = each %opts_spec )
    {
        print "# $opt_spec => ";
        print '[', join(',',@$default), ']' if ref $default eq 'ARRAY';
        if( ref $default eq 'HASH' )
        {
            print '{'; while( my($k,$v)=each %$default ) { print "$k => $v,"}  print '}';
        }
        print $default if defined $default && ! ref $default;
        print "\n";
    }
}

__END__

=head1 NAME

simple3.t - Test wrong syntaxes (with args) and what is displayed for them.

=head1 SYNOPSIS

    % perl simple3.t

=head1 DESCRIPTION

Test wrong syntaxes (with args) and what is displayed for them.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item there is no options

=back

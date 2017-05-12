#!/usr/local/perl -w

# Test empty arguments in command line.

use strict;
use vars qw($opt $true_syntax);

use Getopt::Yagow;
use Test::More tests => 4;

my( %opts_spec,@cmd,$cmd,$usage_text);

%opts_spec = (
                 'option0|opt0|0=s'  => undef,   # Mandatory 
                 'option1|opt1|1=s'  => 'one'    # Optional, but if specified needs argument string
             );

&show_options_spec;

$opt = Getopt::Yagow->new;
$opt->load_options( \%opts_spec );

local %SIG;

@cmd = ( '' );

$usage_text = &test_syntax( @cmd, 0);
ok( $true_syntax==0,'Wrong syntax (there is a mandatory arg): \''.join(' ',@cmd)."'"); # Test for wrong syntax.
ok(length($usage_text) && $usage_text =~ /Usage:/ && $usage_text !~ /Options and Arguments:/, 
          "Wrong syntax with -verbose => 0 displays what expected");

$usage_text = &test_syntax( @cmd, 1);
ok(length($usage_text) && $usage_text =~ /Usage:/ && $usage_text =~ /Options and Arguments:/,
          "Wrong syntax with -verbose => 1 displays what expected");

$usage_text = &test_syntax( @cmd, 2);
ok(length($usage_text) && $usage_text =~ /NAME/ && $usage_text =~ /SYNOPSIS/,
          "Wrong syntax with -verbose => 2 displays what expected");


#----------------------------------------------------------------------------------------
# FUNCTIONS.


sub test_syntax
{
    my $verbose = pop @_;

    open( OUT_TEXT, '>options.out') || die "Can't open options.out: $!\n";

    my $msg = 'simple4.t is a test file for Getopt::Yagow module. By Enrique Castilla. Dic-2002';
    my $usage_opts = {-msg => $msg,-exitval => 'noexit',-output => \*OUT_TEXT,-verbose => $verbose};

    # For trapp incorrect syntax in command line.
    $true_syntax = 1;
    %SIG = ( __WARN__ => sub { $true_syntax = 0; } );

    @ARGV = @_;
    # Debug:
    #print 'Debug: ',join(',',@ARGV),"\n";    
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

simple4.t - Test file for Getopt::Yagow module.

=head1 SYNOPSIS

    % perl simple4.t

=head1 DESCRIPTION

Test file for Getopt::Yagow module.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item there is no options

=back

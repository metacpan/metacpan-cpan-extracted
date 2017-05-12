#! /usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromString);
use JSON;
use Jmespath;
use Pod::Usage;
use File::Slurp qw(slurp);
use Data::Dumper;
use Try::Tiny;
use v5.14;

my $ast = 0;
my $help = 0;
my $file = '';
my $expression = '';
my $opts = {};
my $data = '';
my $verbose = 0;

GetOptions ( 'ast' => \$ast,
             'h'   => \$help,
             'f=s' => \$file,
             'v'   => \$verbose,
             ''    => \$expression
           ) or pod2usage(2);
pod2usage(1) if scalar @ARGV == 0;
pod2usage(1) if $help;
$Jmespath::VERBOSE = 1 if $verbose;

$expression = pop @ARGV;


#exit(0);
if ($ast) {
  try {
    my $result = Jmespath->compile($expression)->stringify;
    print Dumper $result;
    exit(0);
  } catch {
    print "caught exception2\n";
    print $_->to_string;
    exit(1)
  };
}

#$data = slurp ( $file );
if ($file) { $data = slurp( $file ) } else { $data = slurp(\*STDIN); }
$data =~ s/(?<!\r)\n/\r\n/g;

try {
  say Jmespath->search($expression, $data);
  exit(0);
} catch {
  say $_->to_string;
  exit(1)
};


__END__

=head1 NAME

jp.pl : JMESPath command line processor

=head1 DESCRIPTION

=head1 OPTIONS

jp.pl [OPTIONS] <expression>

 -a   Pretty print the AST
 -f   Data input file
 -h   print brief help on options. For extended help, view the pod file.


=head1 ENVIRONMENT

JP_UNQUOTED Print the result without bounding quotes.


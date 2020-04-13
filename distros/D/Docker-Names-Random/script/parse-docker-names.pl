#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny qw( path );
use YAML::PP;
use Getopt::Long;
use Pod::Usage;
use Data::Dump;

my $man = 0;
my $help = 0;
my $verbose = 0;
my $outfile = 'docker-names.yml';
GetOptions('help|?' => \$help, 'man!' => \$man, 'verbose!' => \$verbose, 'out=s' => \$outfile) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $code = path('names-generator.go')->slurp_utf8;
my ($left, $right) = $code =~ m/var \s{1,} \( \s{0,1} \n
    \s{0,} left \s{1,} = \s{1,} \[\.\.\.\]string \s{0,} \{ \s{0,} \n
    (?<adjectives> (?: \s{0,} \" [^"]{1,} \" \s{0,} , \s{0,} \n )+ )
    \s{0,} } \n
    \s{0,} \n
    \s{0,} \/\/.*\n
    \s{0,} \/\/.*\n
    \s{0,} right \s{1,} = \s{1,} \[\.\.\.\]string \s{0,} \{ \s{0,} \n
    (?<names> (?:
        (?: \s{0,} \/\/.*\n){1,}
        \s{0,} \" [^"]{1,} \" \s{0,} , \s{0,} \n
        (?: \s{0,} \n){0,1}
    )+ )
    \s{0,} \} \n
    \s{0,} \)
    /x;

my @adjectives;
while( $left =~ m/ " (?<adjective> [^"]{1,} ) " /gx ) {
    dd($1) if( $verbose );
    push @adjectives, $1;
}

my @names;
while ( $right =~ m/
    (?<comments>
        \s{0,} \/{2} \s{1} [^\n]{1,}
        (?: \n \s{0,} \/{2} \s{1} [^\n]{1,} ){0,}
    )
    \n
    \s{0,} " (?<surname> [^"]{1,} ) " \s{0,} ,
    /gx ) {
    my $surname = $+{surname};
    dd($1) if ( $verbose );
    my ($info, $link) = $1 =~ m/
        (?<info>
            \s{0,} \/{2} \s{1} [^\n]{1,}
            (?: \n \s{0,} \/{2} \s{1} [^\n]{1,} ){0,}
        )
        (?<url> http [s]{0,1} :\/\/ .* ) $
        /x;
    if( ! defined $info) {
        ($info, $link) = ($1, '');
    }
    $info =~ s/(\n*)//msx;
    $info =~ s/(\t*)//msx;
    $info =~ s/(\/*)//msx;
    ($info) = $info =~ m/^ \s* (.*?) \s* $/msx; # Attn. non-greedy qualifier in (.*?)
    push @names, { 'surname' => $surname, 'explanation' => $info, 'link' => $link, };
}

my %serialize_me = (
    'adjectives' => [ map { { 'word' => $_ } } @adjectives ],
    'names' => [ @names ],
);
my $ypp = YAML::PP->new;
$ypp->dump_file( path($outfile), \%serialize_me );

exit 0;

__END__

=head1 NAME

parse_docker_names.pl - Parse file `names-generator.go` to a YAML

=head1 SYNOPSIS

parse_docker_names.pl [options]

 Options:
   --help            brief help message
   --man             full documentation
   --verbose         print out information as you go
   --out             file name to write

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--verbose>

Explain what you are doing when progressing.

=item B<--out>

Write to this file.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something

useful with the contents thereof.

=cut


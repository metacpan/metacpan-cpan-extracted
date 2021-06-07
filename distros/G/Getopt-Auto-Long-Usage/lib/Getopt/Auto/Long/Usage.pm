#!/usr/bin/env -S perl -CSDA

# Copyright 2021 Alin Mr. <almr.oss@outlook.com>. Licensed under the MIT license (https://opensource.org/licenses/MIT).

package Getopt::Auto::Long::Usage;
use v5.28.0;
use strict; use warnings;

use Data::Dumper;

=head1 NAME

C<Getopt::Auto::Long::Usage> - generate usage strings from Getopt::Long specs

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This is a pure perl module that generates simple usage / help messages by parsing L<Getopt::Long> argument specs (and optionally using provided descriptions).

    print getoptlong2usage( Getopt_Long => \@conf [, ...] )

=head1 DESCRIPTION

C<Getopt::Auto::Long::Usage> strives to be compatible with L<Getopt::LongUsage>. In particular, it does not require supplementing existing arglist specs with additional data (e.g. descriptions are optional). However, the goal is to provide maximum maintainability with the least amount of code, not to achieve complete L<Getopt::Long> coverage. So, there are some differences:

=over 4

=item * the generated usage clearly distinguishes boolean flags from arguments requiring an option, and prints type information for the latter. For negatable boolean options (C<longopt|s!>), it will print the corresponding C<--no-longopt> flag (but not C<--no-s>).

=item * there are no dependencies; the main function can be copied directly into your source code, if necessary

=item * it does not attempt to parse C<GetOptions()> abbreviated / case-insensitive options, and in fact recommends that you disable those when using C<Getopt::Long> for maintainability and predictability. One shortopt + one (or several) longopts, explicitly specified, will avoid nasty surprises (plus, suppose you decide to rewrite the code in some other language...)

=back

The following example should print the generated help message either to stdout, if requested (C<--help>) or to stderr, if argument parsing fails.

    use Getopt::Auto::Long::Usage;
    use Getopt::Long;
    my @getoptargs = qw{ help
                         delim:s
                         eval|e!
                       };
    my %_O_; my @getoptconf = (\%_O_, @getoptargs);

    sub usage {
      my ($rc) = @_;
      my @dsc = ( delim => 'instead of newline' );
      print getoptlong2usage(
        Getopt_Long => \@getoptconf, # all others optional
        cli_use => "Arguments: [OPTION]...\nOptions:";
        footer => "No other arguments may be supplied"
        descriptions => \@dsc
      );
      exit $rc if defined( $rc );
    }

    Getopt::Long::Configure( qw(
      no_ignore_case no_auto_abbrev no_getopt_compat
      gnu_compat bundling
    ));
    unless( GetOptions( @getoptconf ) ) {
      local *STDOUT = *STDERR; usage 1;
    }
    usage 0 if( $_O_{ help } );

=head1 EXPORT

=over 4

=item * C<getoptlong2usage>

=item * C<opts2bash> (import explicitly)

=item * C<bashgetopt> (import explicitly; experimental -- see code)

=back

=cut

use Exporter qw( import );
our @EXPORT = qw( getoptlong2usage );
our @EXPORT_OK = qw( opts2bash bashgetopt );

=head1 FUNCTIONS

=head2 getoptlong2usage

  $usage = getoptlong2usage( Getopt_Long => \@getoptconf [,
    descriptions => \@dsc,  # this & all others: optional
    cli_use => '',
    footer => '',
    colon => ': ',
    indent => undef,
    pfx => '' ] )

C<@getoptconf> is an arrayref containing all the arguments you would supply to C<GetOptions()>, including the initial hashref in which C<GetOptions()> stores results (and which is ignored). It's easiest to define C<@getoptconf> separately and reuse it for both calls. See L</"DESCRIPTION"> for an example.

All other arguments are optional and shown with their defaults. I<colon> separates flags from descriptions. I<pfx> is an arbitrary string (like C<'* '>). I<indent> sets I<pfx> to a number of spaces (don't use both). I<cli_use> goes at the top, I<footer> at the bottom, and both will have a newline appended if they don't end with one.

=cut

sub getoptlong2usage {
  my %_O_ = @_; $_O_{ descriptions } //= [];
  $_O_{ $_ } //= '' for qw{ pfx cli_use footer };
  $_O_{ colon } //= ': ';
  my ($conf, $pfx ) = @_O_{ qw{ Getopt_Long pfx }};
  my %dsc = @{ $_O_{ descriptions } };

  my $opt2dash = sub { length $_ == 1 ? "-$_" : "--$_"; };
  my $finalnl = sub { my ($s) = @_; $s .= "\n" unless $s =~ /(^|\n)$/; $s; };
  # my $uniq = sub { my %cn; return grep { ! $cn{ $_ }++ } @_; };  # for auto_abbrev

  my $out = &$finalnl( $_O_{ cli_use } );
  $pfx = (' ' x $_O_{ indent }) if defined( $_O_{ indent } );

  my %t2p = (s => 'STR', i => 'INT', f => 'REAL', o => '[0[x|b]]INT', '+' => 'repeated...');  # TODO: :number, = t [desttype] [repeat]

  for( @{ $conf }[ 1..$#$conf ] ) {
    my $a = $_; my $isneg = 0; my $t = ''; my $isopt = 0;
    if    (/(.*)!$/)    { $a = $1; $isneg = 1; }
    if    (/(.*)\+$/)   { $a = $1; $t = '+'; $isopt = 1; }
    elsif (/(.*):(.*)/) { $a = $1; $t = $2; $isopt = 1; }
    elsif (/(.*)=(.*)/) { $a = $1; $t = $2; }

    $a =~ qr{ (^|\|) ( (?<long> [^|]{2,}) ($|\|) ) }x; my $along = $+{long};
    my @aa = split( /\|/, $a );
    # @aa = &$uniq( @aa, substr( $along, 0, 1 ) ) if length $along;  # handle auto_abbrev
    $out .= $pfx . join( ' | ', map( &$opt2dash, @aa ) );
    my $d = ''; $d =  (length $along and $dsc{ $along }) ? "$_O_{ colon }$dsc{ $along }" : '';
    if( length $t ) {
      $t = $t2p{ $t } // "ARG:$t"; $t = "[$t]" if $isopt;
      $out .= " $t$d";
    } else {
      $out .= $d;
      if( $isneg ) { $out .= "\n$pfx--no-" . $along if length $along; }
    }
    $out .= "\n";
  }
  return $out . &$finalnl( $_O_{ footer } );
}

=head2 opts2bash

  opts2bash( opts => {}, ARGV => [],
    assoc => 0,
    name => q(_O_),
    bash => q/bash/,
    underline => q/_/,
    uc => 0
  )

Outputs a string that can be eval'd in bash to set bash variables to the corresponding values in perl. Bash variables are either prefixed by I<name>, or I<name> can be an associative array (I<assoc> = 1). Calls C<system('bash' ...)> underneath to quote perl values (I<bash> can override the interpreter and can contain flags, e.g. 'C<bash44 -x>').

This function can export, in Bash format, parameters (including positional ones: I<ARGV>) parsed by perl. In fact, C<bashgetopt()> uses it just for that.

=cut

sub opts2bash {
  my %_O_ = @_;
  $_O_{ name } //= '_O_'; $_O_{ underline } //= '_'; $_O_{ opts } //= {}; $_O_{ ARGV } //= []; $_O_{ bash } //= '/bin/bash';
  my @bash = split / /, $_O_{ bash };
  my %opts = %{ $_O_{ opts } };
  my $xlatek = sub {
    my ($k) = @_;
    $k =~ s/-/$_O_{underline}/g unless $_O_{ assoc };
    $k = uc $k if $_O_{ uc };
    $k
  };
  my @kvkv = map { (&$xlatek( $_ ), $opts{ $_ }) } keys %opts;
  my $cmd=q{$1};
  $cmd = "[$cmd]" if $_O_{ assoc };
  $cmd = q{
v=$1; shift
while test $# -gt 0; do
  test "$1" != -- || { shift; break; }
  printf '%s%s=%s\n' "$v" "} . qq{$cmd} . q{" "${2@Q}"; shift 2
done
printf 'set -- %s\n' "${*@Q}"; echo
};
  system( @bash, '-euc', $cmd, 'bash', $_O_{ name }, @kvkv, '--', @{ $_O_{ ARGV }});
}

=head2 bashgetopt

  bashgetopt( argspec => '',
    descriptions => '',
    cli_use => "Arguments: [OPTION]...\nOptions:\n",
    footer => '',
    assoc => 0
  )

Generates a bash stub script that imports C<Getopt::Long> and this module. The stub script contains a bash function C<__perl_parse_args> (not invoked by default) that call perl to parse its arguments according to the provided argspec. You can use the generated output as scaffolding, or C<eval> it in another bash script. Sample usage:

  perl -wE >x.sh '
    use Getopt::Auto::Long::Usage qw( bashgetopt );
    print bashgetopt( argspec => q(name|n=s help|h) )'
  # edit x.sh, uncomment lines
  chmod +x x.sh; x.sh --help
  x.sh --name 'My name' arg1 arg2

=cut

sub bashgetopt {
  my %_O_ = @_; $_O_{ argspec } //= 'help|h'; $_O_{ footer } //= ''; $_O_{ descriptions } //= [];
  $_O_{ cli_use } //= qq{Arguments: [OPTION]...\nOptions:\n};
  $_O_{ assoc } //= 0;
  $_ = <<'EOSH';
#!/bin/bash
__perl_parse_args() {
local -; set -u
local out rc; IFS= read -r -d '' out <<'EOPL'
use strict; use warnings; use v5.28.0;
use Getopt::Long; use Getopt::Auto::Long::Usage qw( getoptlong2usage opts2bash );
my ($assoc, $argspec, $descriptions, $cli_use, $footer);
!!--parsercfg--
my @getoptargs = split ' ', $argspec;
my %_O_; my @getoptconf = (\%_O_, @getoptargs);
sub usage {
  my ($rc) = @_; $rc //= 0;
  print getoptlong2usage( Getopt_Long => \@getoptconf, cli_use => $cli_use, footer => $footer, descriptions => $descriptions );
  exit $rc if defined( $rc );
}
Getopt::Long::Configure( qw(no_ignore_case no_auto_abbrev no_getopt_compat gnu_compat bundling));
unless( GetOptions( @getoptconf ) ) { usage 2; }
usage 1 if( $_O_{ help } );
opts2bash( opts => \%_O_, ARGV => \@ARGV, assoc => $assoc )
EOPL
out=$(perl 2>&1 -wE "$out" -- "$@"); rc=$?
#declare -p rc out
case $rc in
  0) eval "$out" ;;
  1) printf '%s\n' "$out"; exit 0 ;;
  2) printf '%s\n' "$out" >&2; exit 1 ;;
esac
ARGV=( "$@" )
};
#declare -A _O_  # if $assoc
#__perl_parse_args "$@"
#declare -p ARGV # _O_
EOSH
   my @dumps = qw( argspec cli_use footer descriptions assoc );
   my $cfg = Data::Dumper->Dump( [@_O_{ @dumps }], \@dumps );
   say STDERR Dumper( \$cfg );
   s/!!--parsercfg--/$cfg/;
   $_;
}

1;

__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Getopt::Auto::Long::Usage

=head1 SEE ALSO

=over 4

=item * C<Getopt::Long::Descriptive>

=item * L<bashaaparse|https://gitlab.com/kstr0k/bashaaparse/>, my take on automatic arg parsing / usage generation for Bash scripts

=back

=head1 AUTHOR

Alin Mr., see source code at https://gitlab.com/kstr0k/perl-getopt-auto-long-usage

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Alin Mr.

This is free software, licensed under:

  The MIT (X11) License

=cut

# vi: set ft=perl:

use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF;
use parent qw/MarpaX::ESLIF::Base/;
use MarpaX::ESLIF::String;       # Make sure it is loaded, the XS is using it
use MarpaX::ESLIF::RegexCallout; # Make sure it is loaded, the XS is using it
use XSLoader ();

# ABSTRACT: ESLIF is Extended ScanLess InterFace

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Config;

#
# Base required class methods
#
sub _CLONABLE { return sub { 1 } }
sub _ALLOCATE { return \&MarpaX::ESLIF::allocate }
sub _DISPOSE  { return \&MarpaX::ESLIF::dispose }
sub _EQ {
    return sub {
        my ($class, $args_ref, $loggerInterface) = @_;

        my $definedLoggerInterface = defined($loggerInterface); # It is legal to create an eslif with no logger interface
        my $_definedLoggerInterface = defined($args_ref->[0]);
        return
            (
             (! $definedLoggerInterface && ! $_definedLoggerInterface)
             ||
             ($definedLoggerInterface && $_definedLoggerInterface && ($loggerInterface == $args_ref->[0]))
            )
    }
}

#
# Internal routine used at bootstrap that says is nvtype is a double
#
sub _nvtype_is_long_double {
    return (($Config{nvtype} || '') =~ /^\s*long\s+double\s*$/) ? 1 : 0
}
#
# Internal routine used at bootstrap that says is nvtype is a __float128
#
sub _nvtype_is___float128 {
    return (($Config{nvtype} || '') eq '__float128') ? 1 : 0
}

#
# At bootstrap we cache $true and $false so they must be available before the XS loader
#
our $true;
our $false;
BEGIN {
    use JSON::MaybeXS 1.004000 qw//;
    $true = JSON::MaybeXS::true();
    $false = JSON::MaybeXS::false();
}

#
# Bootstrap
#
BEGIN {
    #
    our $VERSION = '6.0.35.1'; # VERSION
    #
    # Note that $VERSION is always defined when you use a distributed CPAN package.
    # With old versions of perl, only the XSLoader::load(__PACKAGE__, $version) works.
    # E.g. with perl-5.10, doing directly:
    # make test
    # within the repository may yell like this:
    # Error:  XSLoader::load('Your::Module', $Your::Module::VERSION)
    # In this case, you can put the module version in the MARPAX_ESLIF_VERSION
    # environment variable, e.g.:
    # MARPAX_ESLIF_VERSION=999.999.999 make test
    #
    # Modules that we depend on bootstrap
    use Math::BigFloat qw//;
    use Math::BigInt qw//;
    use Encode qw//;
    my $version = eval q{$VERSION} // $ENV{MARPAX_ESLIF_VERSION}; ## no critic
    defined($version) ? XSLoader::load(__PACKAGE__, $version) : XSLoader::load();
}

# Load our explicit sub-modules
use MarpaX::ESLIF::Event::Type;
use MarpaX::ESLIF::Grammar;
use MarpaX::ESLIF::Grammar::Properties;
use MarpaX::ESLIF::Grammar::Rule::Properties;
use MarpaX::ESLIF::Grammar::Symbol::Properties;
use MarpaX::ESLIF::JSON;
use MarpaX::ESLIF::Logger::Level;
use MarpaX::ESLIF::Recognizer;
use MarpaX::ESLIF::Symbol;
use MarpaX::ESLIF::Symbol::PropertyBitSet;
use MarpaX::ESLIF::Symbol::EventBitSet;
use MarpaX::ESLIF::Symbol::Type;
use MarpaX::ESLIF::Value;
use MarpaX::ESLIF::Value::Type;
use MarpaX::ESLIF::Rule::PropertyBitSet;


sub getInstance {
    goto &new
}


*is_bool = \&JSON::MaybeXS::is_bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF - ESLIF is Extended ScanLess InterFace

=head1 VERSION

version 6.0.35.1

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  printf "ESLIF library version: %s\n", $eslif->version;

With a logger, using Log::Any::Adapter::Stderr as an example:

  use MarpaX::ESLIF;
  use Log::Any qw/$log/;
  use Log::Any::Adapter ('Stderr', log_level => 'trace' );

  my $eslif = MarpaX::ESLIF->new($log);
  printf "ESLIF library version: %s\n", $eslif->version;

This class and its derivatives are thread-safe. Although there can be many ESLIF instances, in practice a single instance is enough, unless you want different logging interfaces. This is why the C<new> method is implemented as a I<multiton> v.s. the logger: there is one MarpaX::ESLIF perl logger.

Once created, one may want to create a grammar instance. This is provided by L<MarpaX::ESLIF::Grammar> class. The grammar can then be used to parse some input, using a I<recognizer>, or even to I<valuate> it.

A recognizer is asking for an interface that you will implement that must provide some methods, e.g. on a string:

  package MyRecognizer;
  sub new {
      my ($pkg, $string) = @_;
      open my $fh, "<", \$string;
      bless { data => undef, fh => $fh }, $pkg
  }
  sub read                   { my ($self) = @_; defined($self->{data} = readline($self->{fh})) } # Reader
  sub isEof                  {  eof shift->{fh} } # End of data ?
  sub isCharacterStream      {                1 } # Character stream ?
  sub encoding               {                  } # Encoding ? Let's ESLIF guess.
  sub data                   {    shift->{data} } # data
  sub isWithDisableThreshold {                0 } # Disable threshold warning ?
  sub isWithExhaustion       {                0 } # Exhaustion event ?
  sub isWithNewline          {                1 } # Newline count ?
  sub isWithTrack            {                0 } # Absolute position tracking ?
  1;

Valuation is also asking for an implementation of your own, that must provide some methods, e.g.:

  package MyValue;
  sub new                { bless { result => undef}, shift }
  sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
  sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
  sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
  sub isWithNull         { 0 }  # Allow null parse ?
  sub maxParses          { 0 }  # Maximum number of parse tree values
  sub getResult          { my ($self) = @_; $self->{result} }
  sub setResult          { my ($self, $result) = @_; $self->{result} = $result }
  1;

A full example of a calculator with a I<self-contained grammar>, using the recognizer and valuation implementation above, and actions writen in B<Lua>:

  package MyRecognizer;
  sub new {
      my ($pkg, $string) = @_;
      open my $fh, "<", \$string;
      bless { data => undef, fh => $fh }, $pkg
  }
  sub read                   { my ($self) = @_; defined($self->{data} = readline($self->{fh})) } # Reader
  sub isEof                  {  eof shift->{fh} } # End of data ?
  sub isCharacterStream      {                1 } # Character stream ?
  sub encoding               {                  } # Encoding ? Let's ESLIF guess.
  sub data                   {    shift->{data} } # data
  sub isWithDisableThreshold {                0 } # Disable threshold warning ?
  sub isWithExhaustion       {                0 } # Exhaustion event ?
  sub isWithNewline          {                1 } # Newline count ?
  sub isWithTrack            {                0 } # Absolute position tracking ?
  1;

  package MyValue;
  sub new                { bless { result => undef}, shift }
  sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
  sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
  sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
  sub isWithNull         { 0 }  # Allow null parse ?
  sub maxParses          { 0 }  # Maximum number of parse tree values
  sub getResult          { my ($self) = @_; $self->{result} }
  sub setResult          { my ($self, $result) = @_; $self->{result} = $result }
  1;
  
  package main;
  use Log::Any qw/$log/, default_adapter => qw/Stdout/;
  use MarpaX::ESLIF;
  use Test::More;
  
  my %tests = (
      1 => [ '1',               1            ],
      2 => [ '1/2',             0.5          ],
      3 => [ 'x',               undef        ],
      4 => [ '(1*(2+3)/4**5)',  0.0048828125 ]
      );
  
  my $eslif = MarpaX::ESLIF->new($log);
  my $g = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });
  foreach (sort { $a <=> $b} keys %tests) {
      my ($input, $value) = @{$tests{$_}};
      my $r = MyRecognizer->new($input);
      my $v = MyValue->new();
      if (defined($value)) {
          ok($g->parse($r, $v), "'$input' parse is ok");
          ok($v->getResult == $value, "'$input' value is $value");
      } else {
          ok(!$g->parse($r, $v), "'$input' parse is ko");
      }
  }
  
  done_testing();

  __DATA__
  :discard ::= /[\s]+/
  :default ::= event-action => ::luac->function()
                                         print('In event-action')
                                         return true
                                       end
  event ^exp = predicted exp
  exp ::=
      /[\d]+/                             action => ::luac->function(input) return tonumber(input) end
      |    "("  exp ")"    assoc => group action => ::luac->function(l,e,r) return e               end
     || exp (- '**' -) exp assoc => right action => ::luac->function(x,y)   return x^y             end
     || exp (-  '*' -) exp                action => ::luac->function(x,y)   return x*y             end
      | exp (-  '/' -) exp                action => ::luac->function(x,y)   return x/y             end
     || exp (-  '+' -) exp                action => ::luac->function(x,y)   return x+y             end
      | exp (-  '-' -) exp                action => ::luac->function(x,y)   return x-y             end

The same but with actions writen in B<Perl>:

  package MyRecognizer;
  sub new {
      my ($pkg, $string) = @_;
      open my $fh, "<", \$string;
      bless { data => undef, fh => $fh }, $pkg
  }
  sub read                   { my ($self) = @_; defined($self->{data} = readline($self->{fh})) } # Reader
  sub isEof                  {  eof shift->{fh} } # End of data ?
  sub isCharacterStream      {                1 } # Character stream ?
  sub encoding               {                  } # Encoding ? Let's ESLIF guess.
  sub data                   {    shift->{data} } # data
  sub isWithDisableThreshold {                0 } # Disable threshold warning ?
  sub isWithExhaustion       {                0 } # Exhaustion event ?
  sub isWithNewline          {                1 } # Newline count ?
  sub isWithTrack            {                0 } # Absolute position tracking ?
  1;

  package MyValue::Perl;
  sub new                { bless { result => undef}, shift }
  sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
  sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
  sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
  sub isWithNull         { 0 }  # Allow null parse ?
  sub maxParses          { 0 }  # Maximum number of parse tree values
  sub getResult          { my ($self) = @_; $self->{result} }
  sub setResult          { my ($self, $result) = @_; $self->{result} = $result }
  #
  # Here the actions are writen in Perl, they all belong to the valuator namespace 'MyValue'
  #
  sub tonumber           { shift; $_[0] }
  sub e                  { shift; $_[1] }
  sub power              { shift; $_[0] ** $_[1] }
  sub mul                { shift; $_[0]  * $_[1] }
  sub div                { shift; $_[0]  / $_[1] }
  sub plus               { shift; $_[0]  + $_[1] }
  sub minus              { shift; $_[0]  - $_[1] }
  1;
  
  package main;
  use Log::Any qw/$log/, default_adapter => qw/Stdout/;
  use MarpaX::ESLIF;
  use Test::More;
  
  my %tests = (
      1 => [ '1',               1            ],
      2 => [ '1/2',             0.5          ],
      3 => [ 'x',               undef        ],
      4 => [ '(1*(2+3)/4**5)',  0.0048828125 ]
      );
  
  my $eslif = MarpaX::ESLIF->new($log);
  my $g = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });
  foreach (sort { $a <=> $b} keys %tests) {
      my ($input, $value) = @{$tests{$_}};
      my $r = MyRecognizer->new($input);
      my $v = MyValue::Perl->new();
      if (defined($value)) {
          ok($g->parse($r, $v), "'$input' parse is ok");
          ok($v->getResult == $value, "'$input' value is $value");
      } else {
          ok(!$g->parse($r, $v), "'$input' parse is ko");
      }
  }
  
  done_testing();

=head1 DESCRIPTION

ESLIF is derived from perl's L<Marpa::R2>, and has its own BNF, documented in L<MarpaX::ESLIF::BNF>.

The main features of this BNF are:

=over

=item Embedded Lua language

Actions can be writen directly in the grammar.

=item Regular expressions

Matching supports natively regular expression using the L<PCRE2|http://www.pcre.org/> library.

=item Streaming

Native support of streaming input.

=item Sub-grammars

The number of sub grammars is unlimited.

=back

Beginners might want to look at L<MarpaX::ESLIF::Introduction>.

=for test_synopsis BEGIN { die "SKIP: skip this pod, this is output from previous code\n"; }

In both cases, the output will be:

  ok 1 - '1' parse is ok
  ok 2 - '1' value is 1
  ok 3 - '1/2' parse is ok
  ok 4 - '1/2' value is 0.5
  --------------------------------------------
  Recognizer progress (grammar level 0 (Grammar level 0)):
  [P1@0..0] exp ::= . exp[0]
  [P2@0..0] exp[0] ::= . exp[1]
  [P3@0..0] exp[1] ::= . exp[2]
  [P4@0..0] exp[2] ::= . exp[3]
  [P10@0..0] exp[3] ::= . /[\d]+/
  [P11@0..0] exp[3] ::= . "("
  [P11@0..0]            exp[0]
  [P11@0..0]            ")"
  [P13@0..0] exp[2] ::= . exp[3]
  [P13@0..0]            Internal[5]
  [P13@0..0]            exp[2]
  [P15@0..0] exp[1] ::= . exp[1]
  [P15@0..0]            Internal[6]
  [P15@0..0]            exp[2]
  [P17@0..0] exp[1] ::= . exp[1]
  [P17@0..0]            Internal[7]
  [P17@0..0]            exp[2]
  [P19@0..0] exp[0] ::= . exp[0]
  [P19@0..0]            Internal[8]
  [P19@0..0]            exp[1]
  [P21@0..0] exp[0] ::= . exp[0]
  [P21@0..0]            Internal[9]
  [P21@0..0]            exp[1]
  Expected symbol: /[\d]+/ (symbol No 7)
  Expected symbol: "(" (symbol No 8)
  <<<<<< FAILURE AT LINE No 1 COLUMN No 1, HERE: >>>>>>
  UTF-8 converted data after the failure (1 bytes) at 1:1:
  0x000000: 78                                              x
  --------------------------------------------
  ok 5 - 'x' parse is ko
  ok 6 - '(1*(2+3)/4**5)' parse is ok
  ok 7 - '(1*(2+3)/4**5)' value is 0.0048828125
  1..7

MarpaX::ESLIF also provide native JSON encoder/decoder:

  use Log::Any qw/$log/, default_adapter => qw/Stdout/;
  use MarpaX::ESLIF;
  
  my $eslif = MarpaX::ESLIF->new($log);
  my $json = MarpaX::ESLIF::JSON->new($eslif);
  
  my $perl_hash = $json->encode({data => { 1 => [ 2, "3" ] } });
  $log->infof('JSON Encoder: %s', $perl_hash);
  
  my $json_string = $json->decode($perl_hash);
  $log->infof('JSON decoder: %s', $json_string);

  # Output: 
  # JSON Encoder: {"data":{"1":[2,"3"]}}
  # JSON decoder: {data => {1 => [2,3]}}

=head1 METHODS

=head2 MarpaX::ESLIF->new($loggerInterface)

  my $loggerInterface = My::Logger::Interface->new();
  my $eslif = MarpaX::ESLIF->new();

Returns an instance of MarpaX::ESLIF, noted C<$eslif> below.

C<$loggerInterface> is an optional parameter that, when its exists, must be an object instance that can do the methods documented in L<MarpaX::ESLIF::Logger::Interface>, or C<undef>.

An example of logging implementation can be a L<Log::Any> adapter.

=head2 MarpaX::ESLIF->getInstance($loggerInterface)

Alias to C<new>.

=head2 $eslif->version()

  printf "ESLIF library version: %s\n", $eslif->version;

Returns a string containing the current underlying ESLIF library version.

=head1 NOTES

=head2 BOOLEAN TYPE

ESLIF has a boolean type, perl has not. In order to not reinvent the wheel, the widely JSON's Perl's boolean utilities via L<JSON::MaybeXS> wrapper are used, i.e.:

=over

=item true

A I<true> value. You may localize C<$MarpaX::ESLIF::true> before using ESLIF to change it.

Defaults to C<JSON::MaybeXS::true()>.

=item false

A I<false> value. You may localize C<$MarpaX::ESLIF::false> before using ESLIF to change it.

Defaults to C<JSON::MaybeXS::false()>.

=item is_bool($value)

Returns a true value if C<$value> is a boolean. You may localize C<MarpaX::ESLIF::is_bool()> function before using ESLIF to change it. ESLIF always requires at least that C<$value> is an object, object nature then defaults to C<JSON::MaybeXS::is_bool($value)>

=back

=head2 INTEGER TYPE

ESLIF consider scalars that have only the internal IV flag.

=head2 FLOAT TYPE

ESLIF consider scalars that have only the internal NV flag.

=head2 STRING TYPE

ESLIF consider scalars that have only the internal PV flag.

=head1 SEE ALSO

L<MarpaX::ESLIF::Introduction>, L<PCRE2|http://www.pcre.org/>, L<MarpaX::ESLIF::BNF>, L<MarpaX::ESLIF::Logger::Interface>, L<MarpaX::ESLIF::Grammar>, L<MarpaX::ESLIF::Recognizer>, L<Types::Standard>, L<JSON::MaybeXS>.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

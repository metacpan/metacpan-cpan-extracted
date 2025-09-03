#!/usr/bin/env perl
# Last modified: Tue Sep 02 2025 01:15:23 PM -04:00 [EDT]
# First created: Thu Jul 24 2025 12:47:02 PM -04:00 [EDT]

{
    package Env::Paths::2yaml;
    use strict;
    use v5.18;
    use utf8;
    use warnings;
    our $VERSION = '0.35';
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = ();
    our @EXPORT_OK = qw(ToYaml @Bare);
    our (@Bare, @Wanted);

=head1 SYNOPSIS

    C<my $Yaml = ToYaml( $labelkey, @{$arrayref} );>

=cut

    no warnings 'redefine'; # Why are we seeing a warning here?:
    sub ToYaml {
        my $Key = shift;
        my @pathels = @_;
        my $header = qq[$Key]  . qq[:\n];
        my @listing = map { qq[  - $_\n] } grep { defined $_ } @pathels;
        unshift( @listing, $header ) ;
        return \@listing; # Ready to load as YAML
    }

} # /end of module pkg/

# We're a modulino!
if (!caller() and $0 eq __FILE__)
{
   package main;
  # ---------------------- ### ---------------------- #
  BEGIN {
     @Wanted = map { push @Bare=> $_; q%@% .$_ } grep {
                $_ eq "PERL5LIB"
             || $_ eq "PATH"
             || /^XDG_[A-Z]+_DIRS\z/
             || ( /^[_A-Z0-9]+PATH\z/ && !/^XDG_.+_PATH\z/ )
             || /PSModulePath/i
                  } sort keys %ENV;

  }
  # ---------------------- ### ---------------------- #

   sub ::main {
     use Env::Paths::2yaml;
     use YAML::Any;
# It's nasty to hardcode it this way but this stuff in my env is just in the way:
     @Bare = grep { $_ ne 'ORIGINAL_PATH'
                 && $_ ne 'AMDRMSDKPATH'
                 && $_ ne 'HOMEPATH' } @Bare;

     my $accumulator;
     for my $kstr ( @Bare ) {
         no strict 'refs'; # a symbolic reference below:
         my $seq = Env::Paths::2yaml::ToYaml( $kstr, @{$kstr} );
         my $yaml_segment = join q[]=> @$seq;
         $accumulator .= qq[\n---\n] . $yaml_segment;
     }
     printf "Line %s:\n", __LINE__;
     print $accumulator;
  }
  ::main();
}

1;
__END__

=pod

=head1 TO-DO

"Regularize" (convert to mixed Windows pathname) PSModulePath.

=head1 TESTED-ON

Cygwin and Gnu/Linux and on Windows.

=cut
# vim: ft=perl et sw=4 ts=4 :

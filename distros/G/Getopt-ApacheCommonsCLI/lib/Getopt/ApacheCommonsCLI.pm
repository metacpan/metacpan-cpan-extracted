package Getopt::ApacheCommonsCLI;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ();

use constant OPT_PREC_UNIQUE        => 1;
use constant OPT_PREC_LEFT_TO_RIGHT => 0;
use constant OPT_PREC_RIGHT_TO_LEFT => 2;

our @EXPORT_OK = qw(
 GetOptionsApacheCommonsCLI
 OPT_PREC_UNIQUE
 OPT_PREC_LEFT_TO_RIGHT
 OPT_PREC_RIGHT_TO_LEFT
);

our @EXPORT = qw(
);

our $VERSION = '0.02';

# Preloaded methods go here.

use Getopt::Long 2.35;

sub GetOptionsApacheCommonsCLI {
   my ($rspec, $ropts, $roptions, $rerrsub) = @_;

   # process user-supplied options
   my $DEBUG      = defined $roptions->{'DEBUG'} ? $roptions->{'DEBUG'} : 0;
   my $JAVA_DOPTS = defined $roptions->{'JAVA_DOPTS'} ? $roptions->{'JAVA_DOPTS'} : 0;
   my $OPT_PREC   = defined $roptions->{'OPT_PRECEDENCE'} ? $roptions->{'OPT_PRECEDENCE'} : OPT_PREC_RIGHT_TO_LEFT;
   my $BUNDLING   = defined $roptions->{'BUNDLING'} ? $roptions->{'BUNDLING'} : 1;
   my $rambigs    = defined $roptions->{'AMBIGUITIES'} ? $roptions->{'AMBIGUITIES'} : undef; # reserved for future use

   $ropts->{__argv__}   = '';
   $ropts->{__errors__} = [];
   $ropts->{__argv_original__} = join(' ', @ARGV);

   my @GO_config = qw(pass_through no_auto_abbrev no_ignore_case prefix_pattern=--|-); # passed to Getopt::Long for behavior of Apache Common CLI Java library

   if ($BUNDLING) {
      push @GO_config, 'bundling_override';
   }

   my @GO_options;

   # setup a validation handler for missing argument
   if (ref($rerrsub) ne 'CODE') {
      $rerrsub = sub { my ($option, $value, $rhash) = @_; print "error: missing value for option: $option\n"; die "!FINISH"; };
   }

   my %longs;

   # read user input specification and process for Getopt::Long
   for my $s (@{$rspec}) {
      my ($long, $short, $type) = $s =~ /([a-zA-Z0-9_-]+)\|([a-zA-Z0-9]*)[=:]?([fios]*)/;
      next if $long eq '';

      if ($short eq '') {
         $short = $long;
      }

      if (length($short) > length($long)) {
         ($short, $long) = ($long, $short);
      }

      $longs{$long} = $short;

      # use either the first or second anonymous subroutine as a reference (we are not calling them ... GO will call them)
      push @GO_options, ($s, $type ne '' ?
           sub {
               my ($option, $value, $rhash) = @_;

               if (not defined $value or $value eq "") {
                  push @{$ropts->{__errors__}}, "no value for option $option";
                  &$rerrsub($option, $value, 0);
                  return 0;
               }

               if (exists $ropts->{$option}) {
                  if ($OPT_PREC == OPT_PREC_UNIQUE) {
                     push @{$ropts->{__errors__}}, "duplicate option $option with $value";
                     &$rerrsub($option, $value, 1);
                     return 0;
                  }
                  elsif ($OPT_PREC == OPT_PREC_RIGHT_TO_LEFT) {
                     $ropts->{$option} = $value;
                  }
                  elsif ($OPT_PREC == OPT_PREC_LEFT_TO_RIGHT) {
                     ; # ignore
                  }
                }
                else {
                    $ropts->{$option} = $value;
                }
           } :
           sub {
               my ($option, $value, $rhash) = @_;

               $ropts->{$option} = 1; # boolean option
           }
      );
   }

#   # bundling_override handles this fairly well ...
#
#   # args pre-processing - to reduce parsing ambiguities, replace some of the short options with long options before calling Getopt::Long
# 
#   if (scalar(@ARGV) > 0) {
#      for (my $n=0; $n < scalar(@ARGV); $n++) {
#          last if $ARGV[$n] eq '--';
#          $ARGV[$n] =~ s/^-([\w]+)$/exists $longs{$1} ? "--$1" : "-$1"/e; # double-dash long args which only start with a single-dash
#          $ARGV[$n] =~ s/^(--?)([\w]{2,3})$/exists $rambigs->{$2} ? "--$rambigs->{$2}" : "$1$2"/e; # convert short options to long options because of bundling ambiguity
#      }
#   }

   Getopt::Long::Configure(@GO_config);
   my $result = GetOptions(@GO_options);

   # args post-processing
   if (scalar(@ARGV)) {
      if ($JAVA_DOPTS) {
         for (my $n=0; $n < scalar(@ARGV); $n++) {
             if ($ARGV[$n] eq '--') {
                last;
             }
             $ARGV[$n] =~ s/^ +//;
             $ARGV[$n] =~ s/ +$//;
             $ARGV[$n] =~ s/^--?D(\w+)=['"]?([\w.]+)['"]?$/$ropts->{$1} = $2; '';/e; # process -Dabc=z.y.z, overwrite existing values in the special case of -D (behavior is like OPT_PREC_RIGHT_TO_LEFT)
         }
      }
   }

   my $cmd = join(' ', @ARGV);
   $cmd =~ s/ +/ /g; # is there a case where we care about embedded spaces in remaining ARGV?
   $cmd =~ s/^ +//g;
   $cmd =~ s/ +$//g;

   if ($DEBUG) {
      debug_print($ropts) if $DEBUG;
      print "cmd=$cmd\n";
   }

   # stash remaining ARGV in the output hash
   $ropts->{'__argv__'} = $cmd;

   if ($result == 0 or @{$ropts->{'__errors__'}}) {
      return 0; # failure (according to Getopt::Long protocol)
   }
   else {
      return 1; # success (according to Getopt::Long protocol)
   }
}

# sub value_not_required {
# # option arg not expected, but we still want to set it to 1
#    my ($option, $value, $rhash) = @_;
# 
#    if ($option ne "") {
#       $ropts->{$option} = 1;
#    }
# }
# 
# sub value_required {
# # option arg expected, do error handling if missing, including a custom error message
#    my ($option, $value, $rhash) = @_;
# 
#    if ($option ne "") {
#       if (not defined $value or $value eq "") {
#          print "Missing argument for option:$option\n";
#          $n_errs++;
#          die "!FINISH";
#       }
#       else {
#          if (exists $ropts->{$option} and $OPT_PREC == OPT_PREC_UNIQUE) {
#             print "Unrecognized command: $value\n";
#             $n_errs++;
#             die "!FINISH";
#          }
#          elsif (exists $ropts->{$option} and $OPT_PREC == OPT_PREC_LEFT_TO_RIGHT) {
#             ;
#          }
#          else {
#             $ropts->{$option} = $value;
#          }
#       }
#    }
# }

sub debug_print {
   my ($ropts) = @_;

   for my $o (sort keys %{$ropts}) {
      print "$o=$ropts->{$o}\n";
   }
}
1;
__END__
=head1 NAME

Getopt::ApacheCommonsCLI - Perl extension for parsing arguments similar to Apache Commons CLI Java library.

=head1 SYNOPSIS

 use Getopt::ApacheCommonsCLI qw(GetOptionsApacheCommonsCLI);

=head1 DESCRIPTION

Getopt::ApacheCommonsCLI - Perl extension for parsing arguments similar to Apache Commons CLI Java library.

The Apache Commons CLI Java library implements options parsing according to at least 3 different standards:

=over

=item 1.
Unix

=item 2.
POSIX (bundling, enabled with OPTIONS_BUNDLING=1 flag)

=item 3.
Java (-D options with right-to-left argument precedence, enabled with JAVA_DOPTS=1)

=back

Certainly there will be parsing ambiguities. An example is that single-character option bundling
and non-spaced single-character option args can be parsed in multiple ways for the same input.

If you need 100% compatibility, then it would be advisable to use the original Apache Commons CLI
Java library. However, if "pretty close" is adequate, then use this module, or consider submitting a bug report or patch.

Also, as the Getopt::Long module says, "Note: Using option bundling can easily lead to unexpected results,
especially when mixing long options and bundles. Caveat emptor."

Here are some definitions for the purpose of this module:

=over

=item *
'single-character option' (ie. -a)

=item *
'long option' is the longest option name or alias for an option (ie. --password)

=item *
'short option' is the shortest option name or alias for an option (usually a single-character option) (ie. -pw)

=item *
'Java option' is a single-character option starting with '-D' or '--D' and contains '=' (ie. -Dabc=xyz)

=item *
'bundling' is combining multiple single-character options after a single dash or double dash. (ie. ls -lat)

=back

This Perl module implements:

=over

=item *
options can have both a long and short name

=item *
space or = for trailing option arguments

=item *
allows single-character options to have a non-spaced trailing arg

=item *
options that are seen but don't take an arg have their value set to 1.

=item *
does not enable POSIX single-character options bundling by default, defined in OPTIONS_BUNDLING

=item *
argument assignment precedence is defined in LEFT_TO_RIGHT_ARGS flag, default is from left to right (Java standard is right-to-left)

=item *
Java options parsing is defined with JAVA_DOPTS, default is disabled

=item *
customized error message subroutine for missing args.

=back

For multiple-value arguments, either quote or comma-separate them. Read Getopt::Long documentation for more information.

Input specification format is: "(long-option)|(short-option)[:=]?([fios])?".

 my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

 $opts{'__argv__'}   is the string remaining after GetOpt::Long processing.
 $opts{'__errors__'} is the list of parsing errors.

%options may contain:

 AMBIGUITIES (reserved for future use in disambiguating short option names)
 BUNDLING (default=0, enabled=1 activates Getopt::Long's bundling_override)
 DEBUG (default=0, enabled=1)
 JAVA_DOPTS (default=0, enabled=1, implies post-processing with OPT_PREC_RIGHT_TO_LEFT for matching options)
 OPT_PRECEDENCE (default=OPT_PREC_UNIQUE, also OPT_PREC_LEFT_TO_RIGHT and OPT_PREC_RIGHT_TO_LEFT)

Return values

=over

=item *
Getopt::ApacheCommonsCLI returns 1=for success, 0=failure

=item *
a list of errors in $opts{'__errors__'}

=item *
@ARGV contains remainder of command line.

=back

=head1 EXAMPLE

 #!/usr/bin/perl

 # Program: nodetool_parser.pl
 # Purpose: parse command line arguments like Cassandra nodetool to build a mock object for testing
 # Author: James Briggs
 # Env: Perl5
 # Date: 2014 09 25

 use strict;
 use diagnostics;

 use Getopt::ApacheCommonsCLI qw(GetOptionsApacheCommonsCLI OPT_PREC_UNIQUE OPT_PREC_LEFT_TO_RIGHT OPT_PREC_RIGHT_TO_LEFT);

 use Data::Dumper;

   my $DEBUG = 1;

   # input spec format is: "longest-option|(short-option)(:[fios])"

   my @spec = ("include-all-sstables|a",
               "column-family|cf:s",
               "compact|c",
               "in-dc|dc:s",
               "host|h:s",
               "hosts|in-host:s",
               "ignore|i",
               "local|in-local",
               "no-snapshot|ns",
               "parallel|par",
               "partitioner-range|pr",
               "port|p:i",
               "resolve-ip|r",
               "skip-corrupted|s",
               "tag|t:s",
               "tokens|T",
               "username|u:s",
               "password|pw:s",
               "start-token|st:s",
               "end-token|et:s",
   );

   my %opts; # output hash with tokenized long options and args

   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, { DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, } , \&do_err) ||
      warn "parsing error. see \$opts{__errors__} for a list, ";

   print Dumper(\%opts) if $DEBUG;

 sub do_err {
   my ($option, $value) = @_;

   if (not defined $value or $value eq '') {
      print "Missing argument for option:$option\n";
   }
   else {
      print "Incorrect value, precedence or duplicate option for option:$option:$value\n";
   }

   return 0;
 }

=head2 EXPORT

No symbols are exported by default.

The following symbols can be imported:

 GetOptionsApacheCommonsCLI
 OPT_PREC_UNIQUE
 OPT_PREC_LEFT_TO_RIGHT
 OPT_PREC_RIGHT_TO_LEFT

=head1 SEE ALSO

Getopt::Long

Apache Commons CLI Library

http://commons.apache.org/proper/commons-cli/

=head1 AUTHOR

James Briggs, E<lt>james.briggs@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by James Briggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

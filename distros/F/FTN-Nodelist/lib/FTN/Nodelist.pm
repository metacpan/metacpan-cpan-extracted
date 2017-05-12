# FTN/Nodelist.pm
#
# Copyright (c) 2005-2007 Serguei Trouchelle. All rights reserved.
# Copyright (c)      2013  Robert James Clay. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.08  2013/05/09 Move 'pm' files to the more standard locations under the
#                   lib/ directory. Add Author & Copyright information for
#                   Robert James Clay <jame@rocasa.us>.
#  1.07  2007/02/28 License added
#  1.06  2007/02/04 Quality update (Test::Pod, Test::Pod::Coverage)
#  1.05  2005/09/29 Fixed problem with non-existing node
#  1.04  2005/09/29 Fixed problem with missing nodelist
#  1.03  2005/02/25 Cache problem fixed
#  1.02  2005/02/22 Perl license added
#                   Pointlist processing added
#                   Documentation improved
#  1.01  2005/02/16 Initial revision

=head1 NAME

FTN::Nodelist - Process FTN nodelist

=head1 SYNOPSIS

 my $ndl = new FTN::Nodelist(-file => '/fido/var/ndl/nodelist.*');
 if (my $node = $ndl->getNode('2:550/4077')) {
   print $node->sysop();
 } else {
   warn 'Cannot find node';
 }

=head1 DESCRIPTION

C<FTN::Nodelist> contains functions that can be used to process Fidonet
Technology Network nodelist and pointlist.

=head1 METHODS

=head2 new

This method creates C<FTN::Nodelist> object.
Can get following arguments:

Nodelist file path:

 -file => '/path/to/nodelist'

Path can point to definite file (ex.: C<'/var/ndl/nodelist.357'>) or contain
wildcard (.*) instead of digital extension. Maximum extension value will be
used to find exact nodelist (ex.: C<'/var/ndl/nodelist.*'>)

Cacheable status:

 -cache => 0/1

Default is 1. When cacheable status is set to 1, all search results are
stored in object cache. It saves resources when searching the same address,
but eats memory to store results. Choose appropriate behaviour depending on
your tasks.

=head2 getNode( $addr )

Takes FTN address as argument. Address can be feed in 3D or 4D style
(Zone:Net/Node, Zone:Net/Node.Point).

If 4D style is specified, point address is searching.

Returns C<FTN::Nodelist::Node> object if node can be found in nodelist. 

See L<FTN::Nodelist::Node> for details how these results can be used.

Examples:

  my $node = $ndl->getNode('2:550/0');
  my $node = $ndl->getNode('2:2/0');
  my $node = $ndl->getNode('2:550/4077');
  my $node = $ndl->getNode('2:550/4077.101');

=head1 KNOWN ISSUES

When using wildcard in nodelist path, maximum extension is taken into
account. It may bring to wrong results when there are many nodelist files
and current nodelist has lesser number (for example, C<nodelist.365> and
C<nodelist.006>).

This issue may be resolved in next versions of C<FTN::Nodelist>.

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>
Robert James Clay E<lt>F<jame@rocasa.us>E<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (c) 2005-2007 Serguei Trouchelle. All rights reserved.
Copyright (c)      2013 Robert James Clay. All rights reserved.

=cut

package FTN::Nodelist;

use FTN::Nodelist::Node;
use FTN::Address;

require Exporter;
use Config;

use strict;
use warnings;

our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ();
our @ISA = qw/Exporter/;

$FTN::Nodelist::VERSION = "1.08";

use File::Spec;
use File::Basename;

sub new {
  my $self = shift;
  my %attr = @_;
  $self = {};

  my $ndlfile = $attr{'-file'};

  unless (defined $ndlfile) {
    @$ = "No `-file' attribute specified, cannot find nodelist";
    return undef;
  }

  if ($ndlfile =~ /\.\*$/) { # wildmask used, find corresonding nodelist
    my $directory = dirname($ndlfile);
    my $filename = basename($ndlfile);

    $filename =~ s/\.\*$/.\\d\\d\\d/;

    if (opendir(DIR, $directory)) {
      my ($ndl, @rest) = sort {$b cmp $a}
                          grep { /^$filename/ && -f "$directory/$_" }
                           readdir(DIR);
      closedir DIR;
      if (defined $ndl) {
        $ndlfile = File::Spec->catfile($directory, $ndl);
      } else {
        $@ = 'Cannot find file ' . $ndlfile;
        return undef;
      }

    } else {
      # failed to read directory
      $@ = 'Cannot read directory ' . $directory;
      return undef;
    }
  }

  unless (-e $ndlfile) {
    $@ = 'Cannot find file ' . $ndlfile;
    return undef;
  }

  $self->{'__ndlfile'} = $ndlfile;

  $self->{'__cache'} = 1; # cache search results by default
                          # but may be overriden
  $self->{'__cache'} = $attr{'-cache'} if exists $attr{'-cache'};

  bless $self ;
  return $self;
}

sub getNode {
  my $self = shift;
  my $node = shift;

  if ($self->{'__cache'} and 
      $self->{'__nodes'}->{$node}) {
    # Return cached copy
    return $self->{'__nodes'}->{$node};
  }

  if (my $addr = new FTN::Address($node)) {
    if ($addr->{'p'}) {
      # Points are not in nodelist
      # Process boss/boss-point format pointlists...
      if (open (F, '<' . $self->{'__ndlfile'})) {
        my $found;

        PNT:
        while(<F>) {
          next if /^;/; # strip comments
          if (m!^Boss,(\d+):(\d+)/(\d+)!
                and $1 eq $addr->{'z'} 
                and $2 eq $addr->{'n'}        
                and $3 eq $addr->{'f'} ) {
            while(<F>) {
              next if /^;/; # strip comments
              if (((/^,(\d+),/) or
                   (/^Point,(\d+),/) or
                   0
                  ) and ($addr->{'p'} == $1)) {
                $found = $_;
                last PNT;
              }

              last PNT if /^Boss/; # Not found
            }
          }
        }

        close(F);
        if ($found)  {
          chomp $found;
          my $node = new FTN::Nodelist::Node($addr, $found);
          # cache result if needed
          $self->{'__nodes'}->{$node->address()} = $node if $self->{'__cache'};
          return $node;
        } else {
          # We will search point-format in nodelist
        }
      } else {
        $@ = 'Cannot read nodelist ' . $@;
        return undef;
      }
    } 

    # Process nodelist

    if (open (F, '<' . $self->{'__ndlfile'})) {
      my $found;

      NDL:

      while(<F>) {
        next if /^;/; # strip comments
        if ((/^Zone,(\d+),/) and ($addr->{'z'} == $1)) {
          if ($addr->{'z'} eq $addr->{'n'} and $addr->{'f'} == 0) {
            $found = $_;
            last NDL;
          }
          my $reg;
          while(<F>) {
            next if /^;/; # strip comments
            $reg = 1 if /^Region,/;
            if ((/^Region,(\d+),/ or
                 /^Host,(\d+),/
                ) and ($addr->{'n'} == $1)) {

              if ($addr->{'f'} == 0) {
                $found = $_;
                last NDL;
              }

              while(<F>) {
                next if /^;/; # strip comments
                last NDL if /^Zone,/ or
                            /^Region,/ or
                            /^Host,/;
                if (((/^,(\d+),/) or
                     (/^Hub,(\d+),/) or
                     (/^Pvt,(\d+),/) or
                     (/^Hold,(\d+),/) or
                     (/^Down,(\d+),/) or
                     0
                    ) and ($addr->{'f'} == $1)) {
                  $found = $_;
                  last NDL;
                }
              }
            } elsif (not $reg and $addr->{'z'} eq $addr->{'n'}
                     and /,(\d+)/ and $addr->{'f'} eq $1) {
              $found = $_;
              last NDL;
            }
          }
        }
      }

      if ($addr->{'p'}) {
        # Search for point (point-format)
        undef $found; # Don't need boss-node
        while(<F>) {
          next if /^;/; # strip comments
          last if /^((Zone)|(Region)|(Host)|(Hub)|(Pvt)|(Hold)|(Down))?,/;
                  # Next node found
          if (/^Point,(\d+),/
               and $1 == $addr->{'p'}) {
            $found = $_;
            last;
          }
        }
      }

      close(F);
      if ($found)  {
        chomp $found;
        my $node = new FTN::Nodelist::Node($addr, $found);
        # cache result if needed
        $self->{'__nodes'}->{$node->address()} = $node if $self->{'__cache'};
        return $node;
      } else {
        return undef; # Not found
      }
    } else {
      $@ = 'Cannot read nodelist ' . $@;
      return undef;
    }
  } else {
    $@ = 'Invalid address : ' . $node;
    return undef;
  }
}

1;

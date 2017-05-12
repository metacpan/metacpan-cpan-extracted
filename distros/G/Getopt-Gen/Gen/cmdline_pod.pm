# -*- Mode: CPerl -*-

#############################################################################
#
# File: Getopt::Gen::cmdline_pod.pm
# Author: Bryan Jurish <moocow@cpan.org>
# Description: template for command-line pod docs
#
#############################################################################

package Getopt::Gen::cmdline_pod;
use Getopt::Gen qw(:utils);

# fill_in(%args)
#   + provides 'SOURCE', 'TYPE', and 'PREPEND'
sub fill_in {
  my ($og,%args) = @_;

  ## -- get initial position of DATA
  my $datapos = tell(DATA);

  my $prepend = 'use Getopt::Gen qw(:utils);';
  if (exists($args{PREPEND})) {
    $prepend .= $args{PREPEND};
    delete($args{PREPEND});
  }

  my $rc = Getopt::Gen::fill_in($og,
				TYPE=>'FILEHANDLE',
				SOURCE=>\*DATA,
				PREPEND=>$prepend,
				BROKEN_ARG=>{SOURCE=>__PACKAGE__."::DATA"},
				%args);

  ## -- reset DATA
  seek(DATA,$datapos,0);

  return $rc;
}

1;

###############################################################
# POD docs
###############################################################
=pod

=head1 NAME

Getopt::Gen::cmdline_pod.pm - built-in template for generating plain old documentation.

=head1 SYNOPSIS

 use Getopt::Gen::cmdline_pod;

 $og = Getopt::Gen::cmdline_pod->new(%args);
 $og->parse($options_file);
 $og->fill_in(%extra_text_template_fill_in_args);

=cut

###############################################################
# DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

Generate pod documentation
from option specifications.

=cut

###############################################################
# METHODS
###############################################################
=pod

=head1 METHODS

Most are inherited from L<Getopt::Gen>.

=over 4

=item * C<fill_in(%args)>

Just like the Getopt::Gen method, except you do
not need to specify 'TYPE' or 'SOURCE' parameters.

=back

=cut

###############################################################
# Bugs
###############################################################
=pod

=head1 BUGS

Probably many.

=cut

###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

'gengetopt' was originally written by Roberto Arturo Tena Sanchez,
and it is currently maintained by Lorenzo Bettini.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

perl(1).
Getopt::Gen(3pm).
Getopt::Gen::cmdline_c(3pm).
Getopt::Gen::cmdline_h(3pm).
Text::Template(3pm).

=cut


###############################################################
# TEMPLATE DATA
###############################################################
__DATA__

[@ $og{podpreamble} || '' @]

=pod

=head1 NAME

[@
   (defined($og{USER}{program})
    ? $og{USER}{program}
    : (defined($og{package}) ? $og{package} : '?'))
@] - [@$og{purpose}@]

[@
  $OUT = '';
  if (defined($og{USER}{program_version}) || defined($og{version})) {
    $OUT .= "=head1 VERSION\n\n";
    if (defined($og{USER}{program})) {
      $OUT .= $og{USER}{program}.' ';
      if (defined($og{USER}{program_version})) {
        $OUT .= $og{USER}{program_version}.' ';
      }
    } else {
        $OUT .= (defined($og{package})
                 ? ($og{package}.' '.(defined($og{version}) ? ($og{version}) : ''))
                 : '');
    }
  }
@]

=head1 SYNOPSIS

[@
  $OUT .= (defined($og{USER}{program})
           ? $og{USER}{program}
           : (defined($og{package}) ? $og{package} : '?'));
  $OUT .= ' [OPTIONS]' if (@{$og{optl}});
  if ($og{unnamed}) {
    if (@{$og{args}}) {
      $OUT .= join("", map { " $_->{name}" } @{$og{args}});
    }
    else {
      $OUT .= " FILE(s)...";
    }
  }

@]
[@
   #// -- summary: argument descriptions
   if ($og{unnamed} && @{$og{args}}) {
     my ($arg,$maxarglen);
     #// -- get argument field-lengths
     foreach $arg (@{$og{args}}) {
      $maxarglen = length($arg->{name})
	if (!defined($maxarglen) || $maxarglen < length($arg));
     }
     $OUT .=
       join("\n ",
	    "",
	    q{Arguments:},
	    map {
	      sprintf("   %-${maxarglen}s  %s", $_->{name}, $_->{descr})
	    } @{$og{args}});
   }

    #// -- summary: option descriptions
    if (@{$og{optl}}) {
      #// -- get option field-lengths
      my ($optid,$opt,$maxshortlen,$maxlonglen,$oshortlen,$olonglen);
      my ($short,$long,$descr);
      foreach $opt (values(%{$og{opth}})) {
	$oshortlen = defined($opt->{short}) ? 2 : 0;
	$olonglen = defined($opt->{long}) ? 2+length($opt->{long}) : 0;
	if ($opt->{arg}) {
	  $oshortlen += length($opt->{arg});
	  $olonglen += 1+length($opt->{arg});
	}
	$maxshortlen = $oshortlen
	  if (!defined($maxshortlen) || $maxshortlen < $oshortlen);
	$maxlonglen = $olonglen
	  if (!defined($maxlonglen) || $maxlonglen < $olonglen);
      }
      #// -- print option summary
      my $group = '';
      foreach $optid (@{$og{optl}}) {
	$opt = $og{opth}{$optid};
	if ($opt->{group} ne $group) {
          #// -- print group header
	  $group = $opt->{group};
	  $OUT .= "\n\n $group";
	}
        #// -- print option
	$short = $long = $descr = '';
	if (defined($opt->{short}) && $opt->{short} ne '-') {
	  $short = "-$opt->{short}";
	  $short .= $opt->{arg} if (defined($opt->{arg}));
	}
	if (defined($opt->{long}) && $opt->{long} ne '-') {
	  $long = $opt->{long};
	  $long = '--'.$long;
	  $long .= '='.$opt->{arg} if (defined($opt->{arg}));
	}
	next if ($short eq '' && !$og{longhelp});
	$OUT .= ("\n    "
		 .sprintf("%-${maxshortlen}s", $short)
		 .($og{longhelp} ? sprintf("  %-${maxlonglen}s", $long) : '')
		 .'  '.$opt->{descr});
      }
    }
@]

=cut

###############################################################
# Description
###############################################################
=pod

=head1 DESCRIPTION

[@ $og{purpose} ? $og{purpose} : '' @]

[@ defined($og{USER}{details}) ? $og{USER}{details} : '' @]

=cut

###############################################################
# Arguments
###############################################################

[@
  if ($og{unnamed}) {
    $OUT .= "=head1 ARGUMENTS\n\n=over 4\n\n";
    if (@{$og{args}}) {
      foreach my $arg (@{$og{args}}) {
        my ($name,$descr) = @$arg{qw(name descr)};
        $OUT .= ("=item C<".podify($name).">\n\n".podify($descr)."\n\n"
		 .(defined($arg->{details}) ? "$arg->{details}\n\n" : ''));
      }
    } else {
     $OUT .= "=item C<FILE(s)>\n\nInput files.\n\n";
    }
    $OUT .= "=back\n\n";
  }
  $OUT = "=pod\n\n$OUT\n\n=cut\n\n" if ($OUT);
@]

###############################################################
# Options
###############################################################

[@
  if (@{$og{optl}}) {
    $OUT .= "=head1 OPTIONS\n\n=over 4\n\n";
      my $group = 'Options'; ## -- use the default
      my ($short,$long,$descr,$optid,$opt);
      foreach $optid (@{$og{optl}}) {
	$opt = $og{opth}{$optid};
	if ($opt->{group} ne $group) {
	  $group = $opt->{group};
          #// -- print last-group footer
          $OUT .= "=back\n\n=cut\n\n";
          #// -- print new-group header
          $OUT .= ('#'.('-' x 62)."\n"
                   ."# Option-Group $group\n"
                   .'#'.('-' x 62)."\n"
                   ."=pod\n\n=head2 $group\n\n=over 4\n\n");
	}
        #// -- print option
	$short = $long = $descr = '';
	if (defined($opt->{short}) && $opt->{short} ne '-') {
	  $short = "-$opt->{short}";
	  $short .= $opt->{arg} if (defined($opt->{arg}));
	}
	if (defined($opt->{long}) && $opt->{long} ne '-') {
	  $long = $opt->{long};
	  $long = '--'.$long;
	  $long .= '='.$opt->{arg} if (defined($opt->{arg}));
	}

	# remember we saw an rc-file
	if ($opt->{is_rcfile}) {
	  $saw_rc_file = 1;
	}

	$OUT .= ("=item "
                 .join(" , ",
		       ($long ? ("C<".podify($long).">") : qw()),
		       ($short ? ("C<".podify($short).">") : qw()))
		 ."\n\n"
		 .(defined($opt->{descr}) ? (podify($opt->{descr})."\n\n") : '')
		 .($opt->{required}
		   ? "Required.\n\n"
		   : ((defined($opt->{edefault})
		       ? "Environment Variable: '$opt->{edefault}'\n\n"
		       : '')
		      .(defined($opt->{default})
			? "Default: '$opt->{default}'\n\n"
			: '')))
		 .($opt->{is_rcfile}
		   ? "See also: L<CONFIGURATION FILES>.\n\n"
		   : '')
		 .(defined($opt->{details}) ? ($opt->{details}."\n\n") : '')
		 ."\n\n\n");
      }
      #// -- print last-group footer
      $OUT .= "=back\n\n\n";
  }
  $OUT = "=pod\n\n$OUT\n\n=cut\n\n" if ($OUT);
@]

###############################################################
# configuration files
###############################################################
[@
  if (@{$og{rcfiles}} || $og{handle_rcfile} || $saw_rc_file) {
    $OUT .= qq(

=head1 CONFIGURATION FILES

Configuration files are expected to contain lines of the form:

    LONG_OPTION_NAME    OPTION_VALUE

where LONG_OPTION_NAME is the long name of some option,
without the leading '--', and OPTION_VALUE is the value for
that option, if any.  Fields are whitespace-separated.
Blank lines and comments (lines beginning with '#')
are ignored.

);
    if (@{$og{rcfiles}}) {
      $OUT .= ("The following configuration files are read by default:\n"
               ."\n"
               ."=over 4\n\n"
               .join('', map { "=item * $_\n\n" } @{$og{rcfiles}})
               ."=back\n\n");
    } else {
      $OUT .= "No configuration files are read by default.\n\n";
    }
  }
  $OUT = "=pod\n\n$OUT\n\n=cut\n\n" if ($OUT);
@]


###############################################################
# Addenda
###############################################################

=pod

=head1 ADDENDA

[@ defined($og{USER}{addenda}) ? $og{USER}{addenda} : ''; @]

=head2 About this Document

Documentation file auto-generated by [@$og{name}@] version [@$OptGenVersion@]
using Getopt::Gen version [@ $Getopt::Gen::VERSION @].
[@
 my $ts='Translation was initiated';
 if ($og{want_timestamp}) {
   my $d=`date`;
   $d=~s/\s*$//s;
   $ts.=" on $d";
 }
 $ts;
@]
as:

   optgen.perl [@ $CMDLINE_OPTIONS @]

=cut


###############################################################
# Bugs
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

[@ defined($og{USER}{bugs}) ? $og{USER}{bugs} : "Unknown." @]

=cut

###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

[@ defined($og{USER}{acknowledge}) ? $og{USER}{acknowledge} : 'Perl by Larry Wall.

Getopt::Gen by Bryan Jurish.'; @]

=head1 AUTHOR

[@ (defined($og{USER}{author})
    ? podify($og{USER}{author})
    : 'A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>'); @]

=head1 SEE ALSO

[@ (defined($og{USER}{seealso}) ? $og{USER}{seealso} : 'L<perl>, L<Getopt::Gen>.'); @]

=cut

[@ $saw_rc_file = 0; '' @]

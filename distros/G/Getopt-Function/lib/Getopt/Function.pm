package Getopt::Function;
@ISA=qw(Exporter);
@EXPORT_OK = qw(maketrue makevalue);

use Getopt::Mixed 1.006, 'nextOption';

use strict;
use Carp;
use vars qw($VERSION $verbose_default);
$VERSION=0.017;


=head1 NAME

Getopt::Function - provide mixed options with help information

=head1 SYNOPSIS

    use Getopt::Function qw(maketrue makevalue);
    $::opthandler = new Getopt::Function 
      [ <option-list> ], { <option> => [ <function>, <short descript>, 
				       <argument type>] }
   $result = GetOptions (...option-descriptions...);
   $::opthandler->std_opts;
   $::opthandler->check_opts;

=head1 DESCRIPTION

The B<aim> of this module is to make it easy to provide sophisticated and
complex interfaces to commands in a simple to use and clear manner
with proper help facilities.

It is designed to do this by making it possible to write the options,
with documentation and subroutines to implement them, directly into a
hash and then call the appropriate ones as options detected on the
command line.

=head2 $gto = new Getopt::Function

This constructor takes two arguments.  the first is a reference to a
list of options names in Getopt::Mixed format (see the documentation
for Getopt::Mixed), but with options grouped in strings with their
different forms.

The second argument is a reference to a hash of option functions and
descriptions.  Example:-

  new Getopt::Function 
    [ "red r>red", "green g>green", 
      "bright=s b>bright"] ,
    { "red" => [ &maketrue,
		   "print using red" ],
      "green" => [ sub { print STERR "warning: the green isn't very "
				 . "good\n"; &maketrue},
			   "print using green" ],
      "bright" => [ &makevalue, "set brightness", "INTENSITY" ],
    }


=head1 EXAMPLE

This is a basic code example using most features


    use Getopt::Function qw(maketrue makevalue);

    use vars qw($not_perfect $redirect $since); 

    $::ignore_missing=0;
    @::exclude=();
    @::include=();
    $::maxno=0;

    $::opthandler = new Getopt::Function
      [ "version V>version",
	"usage h>usage help>usage",
	"help-opt=s",
	"verbose:i v>verbose",
	"exclude=s e>exclude",
	"include=s i>include",
        "maxno=i",
      ],
      {
	  "exclude" => [ sub { push @::exclude, $::value; },
	    "Add a list of regular expressions for URLs to ignore.",
	    "EXCLUDE RE" ],
	  "include" => [ sub { push @::include, $::value; },
	    "Give regular expression for URLs to check (if this "
	    . "option is given others aren't checked).",
	    "INCLUDE RE" ],
	  "maxno" => [ \&makevalue, 
	    "stop after a certain number",
	    "ITERATIONS" ],
      };
    $::opthandler->std_opts;

    $::opthandler->check_opts;

    sub usage() {
      print <<EOF;
    example [options]

    EOF
      $::opthandler->list_opts;
      print <<EOF;

    Show off how we could use uptions
    EOF
    }

    sub version() {
      print <<'EOF';
    example version
    $NOTId: example.pl,v 1.3 1010/10/22 09:10:46 joebloggs Exp $
    EOF
    }

    my @list=biglist(); #get a list of things
    foreach $item ( @biglist ) {
      $maxno--;
      $maxno==0 && last;
      is_member ($item, @include) or is_member ($item, @exclude) && next;
      do_big_things @item;
    }

=cut

#FIXME we should either get rid of the grouping restriction by
#reordering the list ourselves or we should do some basic checking
#that the list is validly grouped.


sub new {
  my $class=shift;
  my $self=bless {}, $class;
  my $optlist=shift;
  my $opthash=shift;
  $self->{"list"}=$optlist;
  $self->{"hash"}=$opthash;
  return $self;
}


=head2 $gto->std_opts

This adds the standard options provided by the options module its self
to the hash.  It says nothing about the option list so some of these
options may be made inaccessible.

To use these you have to provide the usage() and version() functions
in the main package.  Something like this.

	sub usage() {
	  print <<EOF;
	lists-from-files.pl [options] url-base file-base 

	EOF
	  $::opthandler->list_opts;
	  print <<EOF;

	Extract the link and index information from a directory containing
	HTML files.
	EOF
	}

	sub version() {
	  print <<'EOF';
	lists-from-files version 
	$Id: Function.pm,v 1.10 2001/08/30 21:31:11 mikedlr Exp $
	EOF
        }


The standard functions will not override ones you have already provided.

=over 4

=item usage

This just gives the usage information for the program then exits.
Normally this should be mapped also to the C<--help> option (and
possibly a short option like C<-h> if that's available).

=item version

This prints the version of the program then exits.

=item help-opt

This gives the help information for the options which are its
parameters.

=item verbose

This sets the variable C<$::verbose> to the value given as a parameter or
C<$Getopt::Function::verbose_default> (default value 4) if no value is given.

=item silent

This sets the variable silent to be true for hushing normal program
output.  Standard aliases to create for this would be C<--quiet> and
C<-q>.

=back

=cut

$verbose_default=4;

my %std_opts = (
	  "usage" => [ sub { main::usage(); exit();  },
		       "Describe usage of this program." ],
	"version" => [ sub { main::version(); exit(); },
		       "Give version information for this program" ],
       "help-opt" => [ sub { foreach (split /\s+/, $::value) {
	                       $::opt_obj->help_opt($::value);
                             } exit();},
		       "Give help information for a given option",
		       "OPTION" ],
	"verbose" => [ sub { ($::value eq "")  ? ($::verbose=$verbose_default)
                                               : ($::verbose=$::value); },
		       "Give information about what the program is doing.  " .
		       "Set value to control what information is given.",
		       "VERBOSITY" ],
         "silent" => [ \&maketrue, "Program should generate no output " .
                                   "except in case of error." ],
);


sub std_opts {
  my $self=shift;
  my $opt_hash=$self->{"hash"};
  my $key;
  foreach $key (keys %std_opts) {
    $opt_hash->{$key} = $std_opts{$key} 
      unless defined $opt_hash->{$key};
  }
}

=head1 maketrue

This provides a convenience function which simply sets a variable in
the main package true according to the option it is called for.  If
the option is negative (no-... e.g. no-delete as opposed to delete),
it sets the variable false.

If the option name contains B<-> then this is substituted for with 
a B<_>.

=cut

sub maketrue {
  confess '$::option must be defined' unless $::option;
  $::option =~ s/-/_/g;
  if ( $::option =~ m/^no_/ ) {
    $::option =~ s/^no_//;
    eval "\$::$::option = 0";
  } else {
    eval "\$::$::option = 1";
  }
}


=head1 makevalue

This provides a convenience function which simply sets a variable in
the main package corresponding to the option to a the given value.

If the option name contains B<-> then this is substituted for with 
a B<_>.

=cut

sub makevalue {
  confess '$::option must be defined' unless $::option;
  $::option =~ s/-/_/g;
  eval "\$::$::option = " . '$::value';
}


=head2 check_opts

Checks all of the options calling the appropriate functions.

The following local variables are available to the function in the
main package.

=over 4

=item $::opt_obj

The option object.  This can be used to call include

=item $::option

This is the option that was called.  The same as the hash key that is
used.  It is determined through the option list.  See above.

=item $::value

If the option can take a parameter this will contain it.  It will be
undefined if the parameter wasn't given.

=item $::as_entered

This will be the option string as entered.

=back

=cut


sub check_opts {
  my $self=shift;
  my $opt_list=$self->{"list"};
  my $opt_hash=$self->{"hash"};
  Getopt::Mixed::init(@$opt_list);

  local ( $::option, $::value, $::as_entered, $::opt_obj);
  $::opt_obj=$self;
  while (($::option, $::value, $::as_entered) = nextOption()) {
    &{$opt_hash->{$::option}[0]};
  }
}

=head2 opt_usage

This is really an internal function and is used to implement list_opts
and help_opt.  Given a string from the options list, this prints out
the the options listed in the string and their docuentation in a neat
format.

=cut

sub opt_usage ($$) {
  my $self=shift;
  $_=shift;
  my $opt_hash=$self->{"hash"};

  s/(\S+)\s+(.+)/$2 $1/; #move key option to last
  my $optname;
  my $olen;
  my $ostr = " ";
  m/^\s*[-A-Za-z]{2,}\S*\s*$/ and $ostr = $ostr . "   ";
OPTION: foreach ( split /\s+/, $_ ) { #FIXME  will split ever work?
    my       ($opt,         $meaning,   $control         ) = 
      m{^  ([-A-Za-z]+)  (?: ([>:=])  ([-A-Za-z]+) )? $ }x ;
    die "badly formed option string `$_'" unless $opt ;
    $ostr = $ostr . '-' unless length $opt == 1;
    $ostr = $ostr . '-' . $opt;
    unless ($meaning) { $optname=$opt; next OPTION; }
    $meaning =~ m/>/ and next OPTION;
    $optname=$opt;
    $meaning =~ m/:/ && do { #optional value
      $ostr = $ostr . '[';
      $ostr = $ostr . '=' unless length $opt == 1;
      $ostr = $ostr . $opt_hash->{$opt}[2] . ']';
    };
    $meaning =~ m/=/ && do { #mandatory value
      $ostr = $ostr . '=' unless length $opt == 1;
      $ostr = $ostr . $opt_hash->{$opt}->[2];
    };
  } continue { #print each form of option
    $ostr = $ostr . " ";
  }
  die "malformed option"  unless defined $optname;

  print $ostr;
  my $width=80;
  my $opt_indent=25;
  my $line_len=$width - $opt_indent;
  if ((length $ostr) < $opt_indent) {
    print " " x ($opt_indent - (length $ostr) );
  }

  $_ = $opt_hash->{$optname}[1];
  if (length $ostr > $opt_indent) {
    #FIXME what about too short lines.. it's programmers
    #responsibility, but we should be reasonably okay.
    my $left=$width - length $ostr;
    (my $firstline,$_) = m[(
	(?:(?:.{1,$left})(?=\Z|\n)) #  a line ended by a newline
	|	#or
	(?:(?:.{1,$left})(?=\s)) #  a line broken at a space
	|	#or
	(?:[\S]{$left}) #  too long.. break anyway
	) (.*) #the rest.
      ]xg;
    print $firstline, "\n";
    return unless $_;
    print " " x $opt_indent;
  }
  Carp::croak( "no help information for option $optname" ) unless $_;
  my @lines = m[\s*
	(
	 (?:(?:.{1,$line_len})(?=\Z|\n)) #  a line ended by a newline or EOS
	 |                      #or
	 (?:(?:.{1,$line_len})(?=\s)) #  a line broken at a space
	 |                      #or
	 (?:[\S]{$line_len})      #  too long.. break anyway
	)
       ]xg;
  my $first=shift @lines;
  print STDOUT $first, "\n";
  foreach (@lines) {
    print " " x $opt_indent, $_, "\n";
  }
}


=head2 list_opts

This function prints out the usage information for all of the options.

=cut

sub list_opts ($) {
  my $self=shift;
  my $opt_list=$self->{"list"};
  my $opt_hash=$self->{"hash"};
  OPTSTRING: foreach (@$opt_list) {
    m/^$/ && do { print "\n"; next OPTSTRING};
    $self->opt_usage($_);
  } #loop over the strings
}


=head2 help_opt

This function searches through the array of options until it gets one
which matches then prints out its documentation.

If the help option is a single character then we only print out a
single character option which matches exactly.  Otherwise we print the
first long option who's start matches.  This doesn't guarantee that we
unambiguously have chosen that option, but could be useful where
someone has forgotten part of the option name...

=cut

sub help_opt ($$) {
  my $self=shift;
  my $opt_list=$self->{"list"};
  my $opt_hash=$self->{"hash"};
  my $option = shift;
  $option =~ m/^-/ && die "for option help please give the option without '-'s";
  my $found=0;
  if ((length $option) == 1) {
    foreach (@{$opt_list}) {
      m/(^|\s)$option([>:=]|$)/ && do { $self->opt_usage($_); $found++};
    }
  } else {
    foreach (@{$opt_list}) {
      my @call_list = ($_);
      m/(^|\s)$option/ && do { $self->opt_usage($_); $found++};
    }
  }
  die "Couldn't find a matching option for $option"  unless $found;
}

=head1 BUGS

There is no scheme for automatic way to do negation.  The workaround
is to define the negative and positive options.  This should be fixed.

=cut

1;


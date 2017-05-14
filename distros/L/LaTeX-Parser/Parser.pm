package LaTeX::Parser;

=head1 NAME

LaTeX::Parser - Perl extension to parse LaTeX files

=head1 SYNOPSIS

  use LaTeX::Parser;
  my $l = new LaTeX::Parser 'file' => 'file.tex';
  my $p = $l->latex; # $p now hold a reference to an array of
                     # file.tex parsed

Or use it to break up LaTeX in a variable:

  my $l = new LaTeX::Parser 'content' =>
    '\textit{Three Lives} by Gertrude Stein.';

Contents of nested braces are extracted as a single element.  Another
C<LaTeX::Parser> will have to be created to parse nested braces.

This is a very early version of C<LaTeX::Parser>, there are many bugs.
I think this will work fine with plain TeX files but I do not plan on
ever support that.

=head1 DESCRIPTION

For now, only simple descriptions of the modules functions.

=cut

use strict;
use integer;


=over 4

=item LaTeX::Parser->new %hash

Creates a LaTeX::Parser object.  All values in C<%hash> are initialize
to the values in the object.  The only two tested values to set are
`C<file>' and `C<content>'.  `C<file>' is the name of the file to load
the LaTeX file from, and it get copied into `C<content>'.  If content
is set by then C<%hash> then `C<file>' will never be called.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %hash = @_;
  my $self = \%hash;
  bless $self, $class;
  return $self;
}

# Function to be considered private that loads the LaTeX file and
# throws out comments.
sub load {
  my $self = shift;

  $self->{'content'} = '';
  open(FILE, $self->{'file'}) || die "Can't load `$self->{file}', $!\n";
  
 LINE:
  while (<FILE>) {
    if (m/^%/) {
      next LINE;
    }
    s/%.*$//;
    $self->{'content'} .= $_;
  }
  close(FILE);
  return $self;
}

=item LaTeX::Parser->latex

No arguments.  Actualy does all the work.  Loads the LaTeX file if not
content was specified, and returns a reference to all parsed
information.

=cut
sub latex {
  my $self = shift;

  if (!defined $self->{'content'}) {
    $self->load;
  }

  my $content = $self->{'content'};
  
  do {
    if ($content =~ m/^(.*?)([\\\{])/s) {
      my $prematch = $1;
      my $match = $2;

      if ($prematch ne '') {
	push @{$self->{'parsed'}}, $prematch;
	$prematch = quotemeta($prematch);
	$content =~ s/^$prematch//s;
      }
      
      if ($match eq '{') {
	$match = &matching('{', '}', $content);
	push @{$self->{'parsed'}}, $match;
	$match = quotemeta($match);
	$content =~ s/^$match//s;
      } elsif ($match eq '\\') {
	if ($content =~ m/^(\\[\w\\]+)/) {
	  $match = $1;
	} elsif ($content =~ m/^(\\.)/) {
	  $match = $1;
	} else {
	  die "A \\ Command I don't understand";
	}
	push @{$self->{'parsed'}}, $match;
	$match = quotemeta($match);
	$content =~ s/^$match//s;
      } else {
	die "Found `$match' where only `{' of `\\' should be"; 
      }

    } else {
      push @{$self->{'parsed'}}, $content;
      $content = '';
    }
  } while ($content ne '');
  return $self->{'parsed'};
}



##############

# Just a little utility program to match nested, single character
# delimited quotes.  Should make it so one can backslach the
# delimiter.

sub matching {
  my $begin = shift;
  my $end = shift;
  my $text = shift;

  my $loop = 1;
  my $deep = 1;

  until ($deep == 0) {
    my $c = substr($text, $loop, 1);
    if ($c eq $begin) {
      $deep++;
    } 
    if ($c eq $end) {
      $deep--;
    }
    $loop++;
  }
  return substr($text, 0, $loop);
}

1;
__END__

=back

=head1 BUGS

Many bugs i'll find soon enough.  Off the top of my head, I know
backslashed brackes in LaTeX are considered normal brackets.  I
haven't even thought about math things, and don't think I will think
about that any time soon.

=head1 AUTHOR

Sven Heinicke, <sven@zen.org>

=head1 SEE ALSO

perl(1), latex(1).

=cut

package Language::Frink::Eval;

=head1 NAME

Language::Frink::Eval

=head1 DESCRIPTION

This module is a simple wrapper around the Frink interpreter written by Alan
Eliasen.  As such, it requires a local copy of the Java interpreter and the
C<frink.jar> file.  For more information on Frink, please see
L<http://futureboy.homeip.net/frinkdocs/>.  This module works by starting a JVM
as a child process, and sending Frink expressions to it via a pipe, and
retrieving the results the same way.  Also, this module has the ability to
function in a restricted mode it attempts to filter "dangerous" expressions,
such as functions that read files from local disk, the network, and also
commands that may persistantly change the interpreter state.

The list of "dangerous" functions and expressions was derived by reading the
Frink documentation, and probably is not complete.  If you find
commands that get through the filter that should, please report them.

=cut 

use strict;
use warnings;
use Params::Validate qw(:all);
use IPC::Open2;
use IO::Select;
use Carp;

our $VERSION = '0.02';

=pod

The following functions are not allowed in restricted mode:

=over

=item C<lines[]>

=item C<read[]>

=item C<eval[]>

=item C<input[]>

=item C<select[]>

=item C<callJava[]>

=item C<newJava[]>

=item C<staticJava[]>

=back

=cut

my @bannedFunctions = (
  'lines',  'read',     'eval',    'input',
  'select', 'callJava', 'newJava', 'staticJava',
);

=pod

The following language constructs are not allowed in restricted mode:

=over

=item Regexes

=item Function Declarations

=item Unit display format

=item Loops

=item Time display format

=item Procedure blocks

=item File inclusion

=item Class Declaration

=back

=cut

my %bannedRegex = (
  '=~'                 => 'Regular expressions are not allowed',
  ':='                 => 'Function declarations are not allowed',
  ':->'                => 'Display format cannot be changed',
  'while[\s{]'         => "'while' loops are not allowed",
  '(^|\s+)for[\s{]'    => "'for loops are not allowed",
  '####'               => 'Cannot redefine the default time format',
  '{.+}'               => 'Procedure blocks are not allowed',
  '(^|\s+)use\s+'      => 'File inclusion not allowed',
  '(^|\s+)class\s+\S+' => 'Class declaration not allowed',
);

=head1 METHODS

=head2 C<new(Param1 =E<gt> ..., etc)>

This method will create a new Language::Frink::Eval object, and start up an
external Frink interpreter in a JVM.  If it encounters any problems when
starting the JVM, then it will call C<die>.

=head3 CONSTRUCTOR PARAMETERS

These parameters are B<not> case sensitive.

=over 4

=item Restricted

This is a boolean value.  If it is true, then expressions will be filtered to 
attempt to prevent "dangerous" expressions from being evaluated.  

=item JavaPath

This specifies the entire commandline to run.  This defaults to C<java -cp 
frink.jar frink.parser.Frink>.  If the java interpreter is not in your path, or
if the C<frink.jar> is not in your current directory, then you will need to 
change this.

=back

=cut

sub new {
  my $class = shift;
  my %p     = validate_with(
    params => \@_,
    spec   => {
      RunCommand => {
        type     => SCALAR,
        default  => "java -cp frink.jar frink.parser.Frink",
        optional => 1
      },
      Restricted => {
        type     => SCALAR,
        default  => 0,
        optional => 1,
      },
    },
    normalize_keys => sub { lc($_[0]) },
  );

  my ($rfh, $wfh);
  my $pid = open2($rfh, $wfh, $p{runcommand});
  # TODO: Verify that this returns a copyright string.
  my $copyright = <$rfh>;
  my $self      = {
    pid        => $pid,
    rfh        => $rfh,
    wfh        => $wfh,
    sel        => IO::Select->new($rfh),
    restricted => $p{restricted},
  };
  bless $self, $class;
  $self;
}

sub filterExpression {
  my $expr = shift;

  foreach my $regex (keys %bannedRegex) {
    if ($expr =~ /$regex/i) {
      croak $bannedRegex{$regex};
    }
  }

  foreach my $func (@bannedFunctions) {
    if ($expr =~ /(^|\s+)$func\s*\[/i) {
      croak "Function $func is not allowed";
    }
  }

  $expr =~ s/[[:cntrl:]]//g;

  $expr;
}

sub restricted {
  my $self = shift;
  my $flag = shift;

  my $old = $self->{restricted};
  $self->{restricted} = $flag if defined $flag;
  $old;
}

=head2 C<eval($expression)>

This passes the expression that is given to the Frink interpreter, and returns
the results as a string. This may return a single string will multiple embedded
newlines. If the interpreter's results end in a newline, then it will be removed
before returning, to make processing the common case of a single line result
easier. If the object is set to C<Restricted> then results will be filtered
before evaluation. If it is determined that the expression cannot be evaluated
due to policy, then the program will C<croak> with an error message describing
why.

=cut

sub eval {
  my $self = shift;
  my $expr = shift;
  $expr = filterExpression($expr) if $self->{restricted};
  my ($wfh, $rfh) = ($self->{wfh}, $self->{rfh});
  print $wfh "$expr\n";
  my $result = '';
  while (1) {
    my @ready = $self->{sel}->can_read(0.1);
    if (@ready == 0) {
      if ($result ne '') {
        chomp($result);
        return $result;
      } else {
        next;
      }
    }
    sysread($rfh, $result, 4096, length($result));
  }
}

=head1 FILES

This module requires a Java interpreter and a local copy of C<frink.jar>.

=head1 LICENSE

This program is free software;  you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 AUTHOR

Clayton O'Neill E<lt>coneill@oneill.netE<gt>

=cut

1;

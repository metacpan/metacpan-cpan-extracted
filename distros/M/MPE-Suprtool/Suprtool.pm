package MPE::Suprtool;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = ( );
our @EXPORT = ( );
our $VERSION = '0.51';


bootstrap MPE::Suprtool $VERSION;
my $plabel;

sub new {
  my $class = shift;
  my %defaults = (
     pri => '  ',
     printstate => 'ER',
     xl => configst2loc()
  );
  my %opt = (%defaults, @_);
  my $self;
  $plabel = getsuprcall("\0$opt{xl}\0") unless defined($plabel);
  if (!$plabel) {
    return undef;
  }
  $self = pack("nnA256A2NA2A2A18A270NA20",
        4, 0, " ", $opt{pri}, 0, $opt{printstate}, "AS", " ", " ", 0, " ");
#       n  n  A256  A2        N   A2               A2   A18   A270 N  A20
  return bless \$self, $class;
}

sub cmd {
  my $self = shift;
  my $cmdstr;
  my $result;
  for $cmdstr (@_) {
    substr($$self, 4, 256) = pack("A256", $cmdstr);
    last unless $result=suprcall($$self);
  }
  return $result;
}

sub status {
  my $self = shift;
  unpack("n",substr($$self, 2,2));
}

sub lastcmd {
  my $self = shift;
  unpack("A256",substr($$self, 4, 256));
}

sub count {
  my $self = shift;
  unpack("N",substr($$self, 558,4));
}

sub totals {
  my $self = shift;
  my $totalstr = substr($$self, 288, 270);
  my @j;
  my @k;

  $totalstr =~ s/( {18})+$//;
  unpack "A18"x(length($totalstr)/18), $totalstr;
}


1;
__END__

=head1 NAME

MPE::Suprtool - Perl extension for calling Robelle Suprtool

=head1 SYNOPSIS

  use MPE::Suprtool;

  chdir "/$ENV{HPACCOUNT}/PUB" or die "Cannot cd to PUB: $!\n";
     # May be necessary to chdir to an MPE group
     # (depending on Suprtool version)

  my $supr = MPE::Suprtool->new
     or die "Cannot run Suprtool\n";

  my $account = 518;

  $supr->cmd(
   "bas ordrdb,5,password",
   "chain order-detail,account=$account",
   "extr order-num, account, invoice",
   "output ordlist,ascii",
   "purge ordlist",
   "exit") or die "Error on Suprtool comand '" . $supr->lastcmd . 
     "', status = " . $supr->status . "\n";

  print "I wrote ", $supr->count, " records.";


=head1 DESCRIPTION

This module allows you to easily call Robelle's Suprtool from Perl
and pass it commands dynamically.  You must, of course, already
have Suprtool installed.  This module is somewhat easier than creating
a Suprtool script file, running Suprtool and then reading JCWs to
figure out if it worked.

See http://www.robelle.com for more on Suprtool.

=over 5

=item new ( [args] )

Creates a new Suprtool object. C<new> optionally takes arguments; 
these arguments are in key-value pairs. Available options:

  OPTION     DEFAULT

  pri           'DS'
     specifies the process queue for Suprtool
     legal values are 'CS', 'DS', or 'ES'

  printstate    'ER'
     specifies when Suprtool prints
     legal values are 'ER' - print on error
                      'AL' - always print
                      'NE' - never print

  xl            'ST2XL.PUB.ROBELLE'
     where Perl should look for the Suprtool2 subroutine
     (Can also be changed when installing module--see README)


  Example:
    my $supr = MPE::Suprtool->new( printstate => 'AL', pri => 'CS')
               or die "Cannot run Suprtool\n";

=item cmd( @list )

C<cmd> submits a command or list of commands to Suprtool.  This is a list of
strings, which can be an array variable, string literals, a list of scalar
string variables, or just about any combination.  The normal Perl rules
apply, so if you want to say OUTPUT $NULL you'll need to use single quotes
  'OUTPUT $NULL'
or escape the $ in double quotes:
  "OUTPUT \$NULL"

Of course, sometimes you want to interpolate a variable.  The commands are only executed when there's an "EXIT" in a string by itself.  Each command string
can be up to 256 characters long.  You can combine commands in one string by
separating them with a semicolon.

The following all have the same effect:
 
  $supr->cmd("INPUT FILE1; KEY 1,4; OUTPUT FILE2", "EXIT");

OR

  $supr->cmd("INPUT FILE1", "KEY 1,4");
  $supr->cmd("OUTPUT FILE2", "EXIT");

OR

  $supr->cmd("INPUT FILE1");
  $supr->cmd("KEY 1,4");
  $supr->cmd("OUTPUT FILE2");
  $supr->cmd("EXIT");

OR

  @a = ("KEY 1,4", "OUTPUT FILE2");
  $supr->cmd("INPUT FILE1", @a, "EXIT");

and so on.

C<cmd> will return false if there is an error. You can use C<status>
to see the status, which is usually not very informative, and
C<lastcmd> to see the command in the list which returned the 
error.

=item lastcmd

The last command executed.  If C<cmd> is passed a list, it will stop
on any command giving an error.  Some syntax errors will be caught
on the command containing the error, but most errors will only
get caught on the 'EXIT' command, so this is of limited utility.

=item Information returned by the calls

See the documenation in the Suprtool manual for the control record for
these items.

=over 4

=item status

  0 - Successfull
  1 - Unable to Access Files
  2 - Suprtool Aborted
  3 - Unable to Create Suprtool Process
  4 - Invalid Total Type
  5 - Unable to Create Suprtool Process

=item count

The number of records that Suprtool output.

=item totals

If you specify the Total command as part of an extract task,
Suprtool2 returns the totals in the totals array. Totals are
returned in exactly the same order in which they were specified.

  Example:

    $supr->cmd(
     "in sales",
     "def division,1,4",
     "def sale-amt,5,6,display",
     "if division='WEST'",
     "ext division, sale-amt",
     "total sale-amt",
     "out sales2,link",
     "purge sales2",
     "exit") or die "Error on Suprtool\n";

     @tot = $supr->totals();
     print "The sum of sales in the west is ", $tot[0], "\n";


=back

=back

=head1 EXPORT

None by default.


=head1 AUTHOR

Ken Hirsch E<lt>F<kenhirsch@myself.com>E<gt>

Many thanks to Robelle, which generously supported the completion of
this module.

This module may be used and distributed on the same terms as Perl.

=head1 SEE ALSO

perl(1).

MPE::Image on CPAN

http://www.robelle.com

=head1 BUGS

As of Suprtool 4.3, the C<suprtool2> routine only works if the current
working directory of your Perl process is an MPE group.

=cut

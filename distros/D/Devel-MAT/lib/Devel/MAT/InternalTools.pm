#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::InternalTools 0.50;

use v5.14;
use warnings;

package Devel::MAT::Tool::help;

use base qw( Devel::MAT::Tool );

use constant CMD => "help";
use constant CMD_DESC => "Display a list of available commands";

use constant CMD_ARGS => (
   { name => "cmdname", help => "name of a command to display more help",
     slurpy => 1 },
);

sub run
{
   my $self = shift;
   my ( $cmdname, @subnames ) = @_;

   if( defined $cmdname ) {
      $self->help_cmd( $cmdname, @subnames );
   }
   else {
      $self->help_summary;
   }
}

sub help_summary
{
   my $self = shift;

   my $pmat = $self->{pmat};

   my @commands = sort map {
      my $class = "Devel::MAT::Tool::$_";
      $class->can( "CMD" ) ? [ $class->CMD => $class->CMD_DESC ] : ()
   } $pmat->available_tools;

   Devel::MAT::Cmd->print_table(
      [
         map { [
            Devel::MAT::Cmd->format_note( $_->[0] ),
            $_->[1],
         ] } sort { $a->[0] cmp $b->[0] } @commands
      ],
      sep => " - ",
   );
}

# A join() that respects stringify overloading
sub _join
{
   my $sep = shift;
   my $ret = shift;
   $ret .= "$sep$_" for @_;
   return $ret;
}

sub help_cmd
{
   my $self = shift;
   my ( $cmdname, @subnames ) = @_;

   my $fullname = join " ", $cmdname, @subnames;

   my $tool = $self->{pmat}->load_tool_for_command( $cmdname );
   $tool = $tool->find_subcommand( $_ ) for @subnames;

   Devel::MAT::Cmd->printf( "%s - %s\n",
      Devel::MAT::Cmd->format_note( $fullname ),
      $tool->CMD_DESC,
   );

   if( my $code = $tool->can( "help_cmd" ) ) {
      $tool->$code();
      return;
   }

   my %optspec = $tool->CMD_OPTS;
   my @argspec = $tool->CMD_ARGS;

   Devel::MAT::Cmd->printf( "\nSYNOPSIS:\n" );
   Devel::MAT::Cmd->printf( "  %s\n", join " ",
      $fullname,
      %optspec ? "[OPTIONS...]" : (),
      $tool->CMD_ARGS_SV ? "[SV ADDR]" : (),
      @argspec ? ( map { "\$\U$_->{name}" } @argspec ) : (),
   );

   if( %optspec ) {
      Devel::MAT::Cmd->printf( "\nOPTIONS:\n" );

      Devel::MAT::Cmd->print_table(
         [ map {
            my $optname = $_;
            my $opt = $optspec{$_};

            my @names = $optname;
            push @names, $opt->{alias} if $opt->{alias};
            s/_/-/g for @names;

            my $synopsis = _join ", ", map {
               Devel::MAT::Cmd->format_note( length > 1 ? "--$_" : "-$_", 1 )
            } @names;

            if( my $type = $opt->{type} ) {
               $synopsis .= " INT" if $type eq "i";
               $synopsis .= " STR" if $type eq "s";
            }

            [ $synopsis, $opt->{help} ],
         } sort keys %optspec ],
         sep    => "    ",
         indent => 2,
      );
   }

   if( @argspec ) {
      Devel::MAT::Cmd->printf( "\nARGUMENTS:\n" );

      Devel::MAT::Cmd->print_table(
         [ map {
            my $arg = $_;

            [ "\$\U$arg->{name}" . ( $arg->{slurpy} ? "..." :
                                     $arg->{repeated} ? "*" : "" ), $arg->{help} ],
         } @argspec ],
         sep    => "    ",
         indent => 2,
      );
   }
}

package Devel::MAT::Tool::more;

use base qw( Devel::MAT::Tool );

use constant CMD => "more";
use constant CMD_DESC => "Continue the previous listing";

my $more;

sub run
{
   if( $more ) {
      $more->() or undef $more;
   }
   else {
      Devel::MAT::Cmd->printf( "%s\n", Devel::MAT::Cmd->format_note( "No more" ) );
   }
}

sub paginate
{
   shift;
   my $opts = ( ref $_[0] eq "HASH" ) ? shift : {};
   my ( $func ) = @_;

   $more = sub { $func->( $opts->{pagesize} // 30 ) };

   $more->() or undef $more;
}

sub can_more
{
   return defined $more;
}

package Devel::MAT::Tool::time;

use base qw( Devel::MAT::Tool );

use constant CMD => "time";
use constant CMD_DESC => "Measure the runtime of a command";

use Time::HiRes qw( gettimeofday tv_interval );

sub run_cmd
{
   my $self = shift;
   my ( $inv ) = @_;

   my $cmd = $inv->pull_token;

   my $starttime = [gettimeofday];

   my $tool = $self->pmat->load_tool_for_command( $cmd );
   my $loadtime = tv_interval( $starttime );

   $tool->run_cmd( $inv );

   my $runtime = tv_interval( $starttime );

   Devel::MAT::Cmd->printf( "\nLoaded in %.03fs, ran in %.03fs\n",
      $loadtime, $runtime - $loadtime,
   );
}

0x55AA;

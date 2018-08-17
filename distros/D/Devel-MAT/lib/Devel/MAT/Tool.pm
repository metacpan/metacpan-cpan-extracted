#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool;

use strict;
use warnings;

our $VERSION = '0.39';

use List::Util qw( any );
use Commandable::Invocation;
Commandable::Invocation->VERSION( '0.02' ); # ->putback_tokens

sub new
{
   my $class = shift;
   my ( $pmat, %args ) = @_;

   my $self = bless {
      pmat     => $pmat,
      df       => $pmat->dumpfile,
      progress => $args{progress},
   }, $class;

   $self->init_tool if $self->can( 'init_tool' );

   return $self;
}

sub pmat
{
   my $self = shift;
   return $self->{pmat};
}

sub df
{
   my $self = shift;
   return $self->{df};
}

sub report_progress
{
   my $self = shift;
   $self->{progress}->( @_ ) if $self->{progress};
}

sub get_sv_from_inv
{
   my $self = shift;
   my ( $inv ) = @_;

   my $sv = Devel::MAT::UI->can( "current_sv" ) && Devel::MAT::UI->current_sv;

   if( defined( my $addr = $inv->pull_token ) ) {
      # Acccept any root name symbolically
      if( any { $addr eq $_ } Devel::MAT::Dumpfile->ROOTS ) {
         $sv = $self->df->$addr;
      }
      # Accept named symbols
      elsif( $addr =~ m/^[\$\@\%\&]/ ) {
         $sv = $self->pmat->find_symbol( $addr );
      }
      else {
         $addr = do {
            no warnings 'portable';
            hex $addr;
         } if $addr =~ m/^0x/;

         do { no warnings 'numeric'; $addr eq $addr+0 } or
            die "Expected numerical SV address\n";

         $sv = $self->df->sv_at( $addr ) or
            die sprintf "No such SV at address %x\n", $addr;
      }
   }

   $sv or die "Need an SV address\n";

   return $sv;
}

# Some empty defaults
use constant CMD_OPTS => ();
use constant CMD_ARGS_SV => 0;
use constant CMD_ARGS => ();
use constant CMD_SUBS => ();

sub find_subcommand
{
   my $self = shift;
   my ( $subname ) = @_;

   # TODO: sanity check

   return ( ref($self) . "::" . $subname )->new( $self->pmat,
      progress => $self->{progress},
   );
}

sub run_cmd
{
   my $self = shift;
   my ( $inv ) = @_;

   # TODO: consider what happens if parent commands have CMD_OPTS
   if( my @subs = $self->CMD_SUBS ) {
      my $subcmd = $inv->pull_token // $subs[0];
      return $self->find_subcommand( $subcmd )->run_cmd( $inv );
   }

   my @args;

   if( my %optspec = $self->CMD_OPTS ) {
      push @args, $self->get_opts_from_inv( $inv, \%optspec );
   }

   if( $self->CMD_ARGS_SV ) {
      push @args, $self->get_sv_from_inv( $inv );
   }

   if( my @argspec = $self->CMD_ARGS ) {
      push @args, $self->get_args_from_inv( $inv, @argspec );
   }

   $self->run( @args );
}

sub get_opts_from_inv
{
   my $self = shift;
   my ( $inv, $optspec, %args ) = @_;

   my $permute = $args{permute} // 1;

   my %opts;
   my %aliases;

   foreach my $name ( keys %$optspec ) {
      my $spec = $optspec->{$name};

      $opts{$name} = $spec->{default};

      $aliases{ $spec->{alias} } = $name if defined $spec->{alias};
   }

   my @remaining;

   while( defined( my $opt = $inv->pull_token ) ) {
      last if $opt eq "--";

      if( $opt =~ m/^--(.*)$/ ) {
         $opt = $1;
      }
      elsif( $opt =~ m/^-(.)$/ ) {
         $opt = $aliases{$1} or die "No such option '-$1'\n";
      }
      else {
         push @remaining, $opt;

         last if !$permute;
         next;
      }

      my $spec = $optspec->{$opt} or die "No such option '--$opt'\n";

      for( $spec->{type} // "" ) {
         m/^$/ and $opts{$opt} = 1, last;
         m/^[si]$/ and $opts{$opt} = $inv->pull_token, last; # TODO: check number
         die "TODO: unrecognised type $_\n";
      }
   }

   $inv->putback_tokens( @remaining );

   return \%opts;
}

sub get_args_from_inv
{
   my $self = shift;
   my ( $inv, @argspec ) = @_;

   my @args;

   foreach my $argspec ( @argspec ) {
      my $val = $inv->pull_token;
      defined $val or !$argspec->{required} or
         die "Expected a value for '$argspec->{name}' argument\n";
      push @args, $val;
      if( $argspec->{slurpy} ) {
         push @args, $inv->pull_token while length $inv->remaining;
      }
   }

   return @args;
}

0x55AA;

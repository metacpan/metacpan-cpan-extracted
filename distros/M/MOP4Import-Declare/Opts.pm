package MOP4Import::Opts;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Exporter qw/import/;

use fields
  (
   # Where to export. Always defined.
   'destpkg'

   # What to define. Optional.
   , 'objpkg'

   # What to inherit. Optional.
   , 'basepkg'

   # Used in MOP4Import::Types::Extend and MOP4Import::Declare::Type
   , 'extending'

   , qw/filename line/
 );

use MOP4Import::Util;

#========================================

sub Opts () {__PACKAGE__}

sub new {
  my ($pack, $caller, @toomany) = @_;
  if (@toomany) {
    croak "Too many arguments! You may need to write Opts->new(scalar caller)";
  }
  my Opts $opts = fields::new($pack);
  ($opts->{destpkg}, $opts->{filename}, $opts->{line})
    = ref $caller ? @$caller : $caller;
  $opts->{objpkg} = $opts->{destpkg};
  $opts;
}

sub take_hash_maybe {
  (my Opts $opts, my $list) = @_;

  return $opts unless @$list and ref $list->[0] eq 'HASH';

  my $o = shift @$list;

  $opts->{$_} = $o->{$_} for keys %$o;

  $opts;
}

# Should I use Clone::clone?
sub clone {
  (my Opts $old) = @_;
  my Opts $new = fields::new(ref $old);
  %$new = %$old;
  $new;
}

sub with_destpkg { my Opts $new = clone($_[0]); $new->{destpkg} = $_[1]; $new }
sub with_objpkg  { my Opts $new = clone($_[0]); $new->{objpkg}  = $_[1]; $new }
sub with_basepkg { my Opts $new = clone($_[0]); $new->{basepkg} = $_[1]; $new }

our @EXPORT = qw/Opts/;
our @EXPORT_OK = (@EXPORT, MOP4Import::Util::function_names
		  (matching => qr/^with_/));

1;

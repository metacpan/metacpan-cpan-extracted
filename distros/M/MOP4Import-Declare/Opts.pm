package MOP4Import::Opts;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Exporter qw/import/;
use overload '""' => 'as_string';

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};
BEGIN {
  print STDERR "Using (file '" . __FILE__ . "')\n" if DEBUG and DEBUG >= 2
}

use MOP4Import::Util qw/globref/;

use fields
  (
   # caller() of import in usual case.
    'callpack'

   # Where to export. Always defined.
   , 'destpkg'

   # What to define. Optional.
   , 'objpkg'

   # What to inherit. Optional.
   , 'basepkg'

   # Used in MOP4Import::Types::Extend and MOP4Import::Declare::Type
   , 'extending'

   # original caller info. This may be empty for faked m4i_opts()
   , 'caller'

   # closures which are called at the each end of MOP4Import handling.
   , 'delayed_tasks'

   # default value for json_type. 'string' if not specified
   , 'default_json_type'

   # Cache to store and keep heavy computation results between pragmas.
   , 'stash'

   , qw/filename line/
 );

use MOP4Import::Util;

#========================================

sub Opts () {__PACKAGE__}

sub new {
  my ($pack, %opts) = @_;

  my Opts $opts = fields::new($pack);

  if (my $caller = delete $opts{caller}) {
    $opts->{caller} = $caller;
    ($opts->{callpack}, $opts->{filename}, $opts->{line})
      = ref $caller ? @$caller : ($caller, '', '');
  }

  $opts->{delayed_tasks} = [];

  $opts->{$_} = $opts{$_} for keys %opts;

  $opts->{objpkg} = $opts->{destpkg} = $opts->{callpack};

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

# XXX: Not extensible. but how?
sub m4i_opts {
  my ($arg) = @_;
  if (not ref $arg) {
    # Fake Opts from string.
    Opts->new(caller => $arg);

  } elsif (UNIVERSAL::isa($arg, Opts)) {
    # Pass through.
    $arg

  } elsif (ref $arg eq 'ARRAY') {
    # Shorthand of MOP4Import::Opts->new(caller => [caller]).
    Opts->new(caller => $arg);

  } elsif (ref $arg eq 'HASH' and m4i_opts_alike($arg)) {
    # pass-thru when m4i_opts-compatible plain HASH is given.
    $arg;

  } else {
    Carp::croak("Unknown argument! ". MOP4Import::Util::terse_dump($arg));
  }
}

sub m4i_opts_alike {
  my ($arg) = @_;
  not grep {not exists $arg->{$_}}
    qw(caller callpack filename line)
}

sub m4i_args {
  ($_[0], m4i_opts($_[1]), @_[2..$#_]);
}

sub m4i_fake_opts {
  my ($fakedCallpack) = @_;
  (undef, my (@callerTail)) = caller;
  Opts->new(caller => [$fakedCallpack, @callerTail]);
}

sub as_string {
  (my Opts $opts) = @_;
  $opts->{callpack};
}

# Provide field getters.
foreach my $field (keys our %FIELDS) {
  *{globref(Opts, $field)} = sub {shift->$field()};
}

our @EXPORT = qw/
                  Opts
                  m4i_args
                /;
our @EXPORT_OK = (@EXPORT, MOP4Import::Util::function_names
		  (matching => qr/^(with_|m4i_)/));

1;

=head1 NAME

MOP4Import::Opts - Object to encapsulate caller() record

=head1 SYNOPSIS

  # To import the type 'Opts' and m4i api functions.
  use MOP4Import::Opts;

  # To create an instance of MOP4Import::Opts.
  sub import {
    ...
    my Opts $opts = m4i_opts([caller]);
    ...
  }

  # To extract MOP4Import::Opts safely from pragma args.
  sub declare_foo {
    (my $myPack, my Opts $opts, my (@args)) = m4i_args(@_);
    ...
  }

=head1 DESCRIPTION

This hash object encapsulates L<caller()|perlfunc/caller> info
and other parameters for L<MOP4Import::Declare> family.

=head1 ATTRIBUTES

=over 4

=item callpack

L<scalar caller()|perlfunc/caller> of import in usual case.

=item destpkg

Where to export. Always defined.

=item objpkg

What to define. Optional.

=item basepkg

What to inherit. Optional.

=item extending

Used in MOP4Import::Types::Extend and MOP4Import::Declare::Type

=item caller

Original L<caller()|perlfunc/caller> info.
This may be empty for faked m4i_opts().

=item filename

=item line

=back

=head1 FUNCTIONS

=head2 m4i_args

This function converts C<$_[1]> by L<m4i_opts> and returns whole C<@_>.

  (my $myPack, my Opts $opts, my (@args)) = m4i_args(@_);

=head2 m4i_opts

  my Opts $opts = m4i_opts([caller]);

  my Opts $opts = m4i_opts(scalar caller); # string is ok too.

=head1 METHODS

=head2 as_string

  $opts->as_string;

  "$opts"; # Same as above.

=head1 AUTHOR

Kobayashi, Hiroaki E<lt>hkoba@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


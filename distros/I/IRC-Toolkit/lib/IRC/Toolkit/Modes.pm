package IRC::Toolkit::Modes;
$IRC::Toolkit::Modes::VERSION = '0.092002';
use strictures 2;
use Carp;

use Scalar::Util 'blessed', 'reftype';

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  array_to_mode
  mode_to_array
  mode_to_hash
/;


sub array_to_mode {
  my ($array) = @_;
  if (blessed $array && $array->isa('IRC::Mode::Set')) {
    $array = $array->mode_array
  }
  confess "Expected an ARRAY but got $array" 
    unless ref $array and reftype $array eq 'ARRAY';

  my $mstr;
  my $curflag = my $pstr = '';
  for my $cset (@$array) {
    my ($flag, $mode, $param) = @$cset;
    confess "Appear to have been given an invalid mode array"
      unless defined $flag and defined $mode;
    $mstr .= $flag eq $curflag ? $mode : ($curflag = $flag) . $mode ;
    $pstr .= " $param" if defined $param;
  }

  $mstr .= $pstr if length $pstr;
  $mstr
}

sub mode_to_array {
  ## mode_to_array( $string,
  ##   param_always => [ split //, 'bkov' ],
  ##   param_set    => [ 'l' ],
  ##   params       => [ @params ],
  ##
  ## Returns ARRAY-of-ARRAY like:
  ##  [  [ '+', 'o', 'some_nick' ], [ '-', 't' ] ]

  my $modestr = shift;
  confess "mode_to_array() called without mode string"
    unless defined $modestr;

  my %args = @_;
  if (my $isup = $args{isupport_chanmodes}) {
    confess 
    "isupport_chanmodes specified but not an ISupport chanmodes() obj: $isup"
      unless blessed $isup and $isup->can('always') and $isup->can('whenset');
    $args{param_always} = $isup->always->unbless;
    $args{param_set}    = $isup->whenset->unbless;
  }
  $args{param_always} ||= [ split //, 'bkohv' ];
  $args{param_set}    ||= ( $args{param_on_set} || [ 'l' ] );
  $args{params}       ||= [ ];

  if ( index($modestr, ' ') > -1 ) {
    my @params;
    ($modestr, @params) = split ' ', $modestr;
    unshift @{ $args{params} }, @params;
  }

  for (qw/ param_always param_set params /) {
    confess "$_ should be an ARRAY"
      unless reftype $args{$_} eq 'ARRAY';
  }

  my @parsed;
  my %param_always = map {; $_ => 1 } @{ $args{param_always} };
  my %param_set    = map {; $_ => 1 } @{ $args{param_set} };
  my @chunks = split //, $modestr;
  my $in = '+';
  CHUNK: while (my $chunk = shift @chunks) {
    if ($chunk eq '-' || $chunk eq '+') {
      $in = $chunk;
      next CHUNK
    }

    my @current = ( $in, $chunk );
    if ($in eq '+') {
      push @current, shift @{ $args{params} }
        if exists $param_always{$chunk}
        or exists $param_set{$chunk};
    } else {
      push @current, shift @{ $args{params} }
        if exists $param_always{$chunk};
    }

    push @parsed, [ @current ]
  }

  [ @parsed ]
}

sub mode_to_hash {
  ## Returns HASH like:
  ##  add => {
  ##    'o' => [ 'some_nick' ],
  ##    't' => 1,
  ##  },
  ##  del => {
  ##    'k' => [ 'some_key' ],
  ##  },

  ## This is a 'lossy' approach.
  ## It won't accomodate batched modes well.
  ## Use mode_to_array instead.
  my $array = mode_to_array(@_);
  my $modes = { add => {}, del => {} };
  while (my $this_mode = shift @$array) {
    my ($flag, $mode, $param) = @$this_mode;
    my $key = $flag eq '+' ? 'add' : 'del' ;
    $modes->{$key}->{$mode} = $param ? [ $param ] : 1
  }

  $modes
}

1;


=pod

=head1 NAME

IRC::Toolkit::Modes - IRC mode parsing utilities

=head1 SYNOPSIS

  use IRC::Toolkit::Modes;
  my $mode_string = '+o-o avenj Joah';
  my $array = mode_to_array( $mode_string );
  my $hash  = mode_to_hash( $mode_string );

=head1 DESCRIPTION

Utility functions for parsing IRC mode strings.

Also see L<IRC::Mode::Set> for an object-oriented approach to modes.

=head2 mode_to_array

  my $array = mode_to_array(
    ## Mode change string with or without params, e.g. '+kl-t'
    $mode_string,

    ## Modes that always have a param:
    param_always => ARRAY,

    ## Modes that only have a param when set:
    param_set    => ARRAY,

    ## Respective params for modes specified above
    ## (or can be specified as part of mode string)
    params       => ARRAY,
  );

Given a mode string and some options, return an ARRAY of ARRAYs containing
parsed mode changes.

The structure looks like:

  [
    [ FLAG, MODE, MAYBE_PARAM ],
    [ . . . ],
  ]

For example:

  mode_to_array( '+kl-t',
    params => [ 'key', 10 ],
    param_always => [ split //, 'bkov' ],
    param_set    => [ 'l' ],
  );

  ## Result:
  [
    [ '+', 'k', 'key' ],
    [ '+', 'l', 10 ],
    [ '-', 't' ],
  ],

If the mode string contains (space-delimited) parameters, they are given
precedence ahead of the optional 'params' ARRAY.

Instead of manually specifying C<param_always> and C<param_set>, you can pass
in the B<chanmodes> object provided by L<IRC::Toolkit::ISupport>:

  my $isupport = parse_isupport(@isupport_lines);
  my $array = mode_to_array( '+kl-t',
    params => [ 'key', 10 ],
    isupport_chanmodes => $isupport->chanmodes,
  );

C<isupport_chanmodes> will override C<param_always> / C<param_set> -- if
that's not acceptable, you can select individual sets:

  my $array = mode_to_array( '+klX-t',
    params => [ 'key', 10, 'foo' ],
    param_always => $isupport->chanmodes->always,
    param_set    => [ 'lX' ],

=head2 array_to_mode

Takes an ARRAY such as that produced by L</mode_to_array> and returns an IRC
mode string.

=head2 mode_to_hash

Takes the same parameters as L</mode_to_array> -- this is just a way to
inflate the ARRAY to a hash.

Given a mode string and some options, return a HASH with
the keys B<add> and B<del>.

B<add> and B<del> are HASHes mapping mode characters to either a simple
boolean true value or an ARRAY whose only element is the mode's
parameters, e.g.:

  mode_to_hash( '+kl-t',
    params => [ 'key', 10 ],
    param_always => [ split //, 'bkov' ],
    param_set    => [ 'l' ],
  );

  ## Result:
  {
    add => {
      'l' => [ 10 ],
      'k' => [ 'key' ],
    },

    del => {
      't' => 1,
    },
  }

This is a 'lossy' approach that won't deal well with multiple conflicting mode
changes in a single line; L</mode_to_array> should generally be preferred.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut


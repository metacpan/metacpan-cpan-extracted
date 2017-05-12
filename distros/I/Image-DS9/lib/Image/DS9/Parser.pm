package Image::DS9::Parser;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use Image::DS9::PConsts;



sub parse_spec
{
  my $command = shift;
  my $specs = shift;

  # keep the rest of the args in @_, so don't copy data

  my %match;

  my $max_match = 0;
  my $nmatch = 0;

 SPEC:
  for my $spec ( @$specs )
  {
    $max_match = $nmatch if $max_match < $nmatch;

    my $iarg = 0;

    $nmatch = 0;

    $match{cmds} = [];

    next if @_ < @{$spec->[0]};

    foreach my $icmd ( 0 .. @{$spec->[0]}-1 )
    {
      # input arguments must have at least the number of
      # sub command slots.

      if ( my ( $tag, $valref, $extra ) = 
	   match( $_[$iarg++], $spec->[0][$icmd] ) )
      {
	push @{$match{cmds}}, [ $tag, $valref, $extra ];
	$nmatch++;
      }
      else  {
	next SPEC ;
      }

    }

    $match{spec} = $spec;


    # if we've come this far, we CANNOT match any further specs.  why?
    # well, because the person setting up the spec list is supposed to
    # ensure that!
    $max_match = $nmatch if $max_match < $nmatch;

    my $s_nmatch = $nmatch;
    my $s_iarg = $iarg;

  ARGLIST:
    for my $argl ( @{$spec}[ 1 .. @{$spec}-1] )
    {

      # this may get adjusted if there's an attribute hash, and will
      # need to be reinitialized if this arglist doesn't match
      # and we do another ARGLIST goround
      my $nargs = @_ - @{$spec->[0]};

      # have to reset pointer into passed arguments for each attempt
      # at matching another argument list
      $iarg = $s_iarg;

      $max_match = $nmatch if $max_match < $nmatch;
      $nmatch = $s_nmatch;

      # default is to query, no args.
      $argl->{query} = QYES unless exists $argl->{query};
      
      # make sure there's an array there, even if empty
      $argl->{args} ||= [];
      
      # number of return values in case of a query; the grammar
      # need only specify it if it's not the same as the number
      # of arguments
      $argl->{rvals} = $argl->{args}
        unless defined $argl->{rvals};

      # adjust things if attributes are ok and we found one at the
      # end of the argument list
      my $found_attrs = 0;
      if ( exists $argl->{attrs} && 'HASH' eq ref $_[-1] )
      {
	$found_attrs = 1;
	# so we don't stumble across 'em
	$nargs--;
      }

      # if we have no passed arguments, and the spec is query only or
      # query possible, we have a match!
      
      if ( ! $nargs && $argl->{query} && !( $argl->{query} & QARGS ))
      {
	$match{argl} = $argl;

	# the number of returned values. set to number of possible
	# arguments if not explicitly specified.
	$match{query} = @{$argl->{rvals}} || @{$argl->{args}} || 1;
      }
      
      # correct number of arguments.
      elsif ( $nargs == @{$argl->{args}} )
      {
	$match{args} = [];

	foreach my $arg ( @{$argl->{args}} )
	{
	  # $extra is not yet supported for args
	  if ( my ( $tag, $valref, $extra ) =
	       match( $_[$iarg++], $arg ) )
	  {
	    push @{$match{args}}, [ $tag, $valref, $extra ];
	    $nmatch++;
	  }
	  else {
	    next ARGLIST ;
	  }
	  
	}

	$match{argl} = $argl;

	# the number of returned values. set to number of possible
	# arguments if not explicitly specified.
	$match{query} = $argl->{query} & QARGS ? 
	  @{$argl->{rvals}} || @{$argl->{args}} || 1 : 0;
      }
      
      else
      {
	next ARGLIST;
      }

      if ( $found_attrs )
      {
	# we need to make a copy, 
	$match{attrs} = parse_attr( $command, $_[-1], $argl->{attrs} );

	croak( __PACKAGE__,
	       ": $command: cannot specify attributes with this query" )
	  if $match{query} && ! ($argl->{query} & QATTR);

      }

      # we found it, $match{argl} will have been set.
      last SPEC;
    }

    last SPEC;
  }

  $max_match += $nmatch + 1;

  croak( __PACKAGE__, 
	 ": $command: missing, unexpected, or illegal value for argument #$max_match" )
    unless defined $match{argl};

#  print Dumper \%match;

  \%match;
}

sub parse_attr
{
  my ( $command, $uattr, $specs ) = @_;

  my %attr;

  # need to make a local copy of the specs array, as _parse_attr 
  # destroys the array
  my @specs = @$specs;

  _parse_attr( $command, \%attr, $uattr, \@specs );

  my @unknown = grep { ! exists $attr{$_} } keys %$uattr;

  croak( __PACKAGE__, ": $command: unknown attribute(s): ",
	 join( ', ', @unknown ) ) if @unknown;

  \%attr;
}

sub _parse_attr
{
  my ( $command, $attr, $uattr, $specs ) = @_;

  my $nmatch;
  my @res;

  while ( my $spec = shift @$specs )
  {
    if ( $spec =~ /^-(o|a)/ )
    {
      my $op = $1;

      my ($sres, $smatch) = _parse_attr( $command, $attr, $uattr, shift @$specs );

      if ( 'a' eq $op )
      {
	
	# no matches? record and continue 
	unless ( $smatch )
	{
	  push @res, { what => $sres, match => 0 };
	  next;
	}

	# number of matches should equal number of attrs
	unless ( $smatch == @$sres )
	{
	  croak( __PACKAGE__, ": $command: missing attributes: ", 
	        dump_attr_chk( [ { what => $sres, match => 1, op => $op }] ) );
	}

	push @res, { what => $sres, match => 1, op => $op };
	$nmatch++;
      }

      elsif ( 'o' eq $op )
      {
	
	# no matches? record and continue 
	unless ( $smatch )
	{
	  push @res, { what => $sres, match => 0 };
	  next;
	}

	# only should have one match
	unless ( $smatch == 1 )
	{
	  croak( __PACKAGE__, ": $command: too many attributes: ", 
	        dump_attr_chk( [ { what => $sres, match => 1, op => $op }] ) );
	}

	push @res, { what => $sres, match => 1, op => $op };
	$nmatch++;
      }

    }
    else
    {
      my $match = chk_attr( $command, $spec, shift(@$specs), $attr, $uattr );
      $nmatch++ if $match;

      push @res, { what => $spec, 
		   match => $match };
    }
  }
  \@res, $nmatch;
}

sub dump_attr_chk
{
  my ( $chks, $sep ) = @_;

  $sep ||= ' , ';

  my $msg;

  for my $res ( @$chks )
  {

    if    ( 'ARRAY' eq ref($res->{what}) )
    {
      my $msep = 
	'a' eq $res->{op} ? ' & ' :
	'o' eq $res->{op} ? ' | ' :
	  croak( __PACKAGE__, "::dump_attr_chk: internal error" );

      my $nmsg = dump_attr_chk( $res->{what}, $msep );
      $msg .= "($nmsg)$sep";
    }
    else
    {
      $msg .= $res->{what} . ($res->{match} ? '' : '?' ) . $sep;
    }
  }

  $sep =~ s/(\W)/\\$1/g;
  $msg =~ s/$sep$//;

  $msg;
}

sub chk_attr
{
  my ( $command, $key, $type, $attr, $uattr ) = @_;
  
  if ( exists $uattr->{$key} )
  {
    # $extra is not yet supported for attrs
    if ( my ( $tag, $valref, $extra ) 
	 = match( $uattr->{$key}, $type ) )
    {
      $attr->{$key} = { tag => $tag, valref => $valref, extra => $extra };
    }
    else
    {
      croak( __PACKAGE__, ": $command: attribute `$key': illegal value. perhaps the wrong type or array length?" );
    }

    return 1;
  }

  0;
}

# ( $tag, $valref, $extra ) = match( $value, $type )
# 
sub match
{
# don't do this! we need to pass by reference to avoid copying tons
# of data
#  my ( $value, $type ) = @_;

  my $type = $_[1];
  my $tag = T_OTHER;
  my $extra;

  my $valref = ref($_[0]) ? $_[0] : \( $_[0] );

  # if the type is an array, the first element is a tag for the
  # type, the second is what to match, the third is just plain extra
  if ( 'ARRAY' eq ref $type )
  {
    $tag   = $type->[0];
    $extra = $type->[2] if exists $type->[2];
    $type  = $type->[1];
  }

  if ( 'Regexp' eq ref($type) )
  {
    return $_[0] =~ /^($type)$/ ? ( $tag, \( my $x = $1 ), $extra ) : ();
  }

  elsif ( 'CODE' eq ref($type) )
  {
    return $type->($_[0], $valref) ? 
      ( $tag, $valref, $extra) : ();
  }

  else
  {
    return $type eq $_[0] ? ( $tag, $valref, $extra ) : ();
  }

  ();
}

1;
__END__


=pod

=head2 Command specification structure.

Commands may have "sub-commands" and arguments.  A given sub-command 
is allowed to have alternate argument lists.  Sub-commands may be
queries as well as directives, and thus will return information.

Commands are specified as arrays.  Each element in the array is a
separate sub-command.  Sub-commands are specified via arrays,
the first element of which defines the sub-command tokens, the rest
the alternate argument lists.

Sub-command tokens are presented as an array of strings or regular
expressions.  If there is more than one, the input list of tokens
must match exactly in order.

An argument list is a hash which describes the order and type of
arguments and whether and how the sub-command can be queried with
the specified argument list.

In detail, here's what a sub-command specification looks like:

=over 8

=item Subcommand

This is an arrayref which contains strings or RE's to match.  all must
match, in the specified order. It may be empty.

=item Argument list

A hashref with the following possible keys:

=over 8

=item args

An array of argument types.  The types may be strings, regular
expressions (generated with the B<qr> operator), or subroutine refs.
The arguments must match the types, in the specified order.

=item query

This determines how and if the sub-command with the specified
arguments may be queried.  It may have the following values:

=over 8

=item QNONE

This sub-command with the specified argument list may not be queried.

=item QARGS

This sub-command with the specified argument list may only be
queried. All of the arguments must specified.

=item QONLY

This sub-command may only be queried.  No arguments may be specified.

=item QYES

This sub-command may be queried.  No arguments may be specified for the query.
This is the default if B<query> isn't specified.

=back

=item bufarg

The last argument passed to the command should be sent via the XPASet buf
argument.

=item cvt

If true (the default) returned results are converted if their type has
a conversion routine available.  The list of arguments is used
to determine the return types.

=item retref

If true, a reference to the queried value is returned if
the user queries the command in a scalar context.

=item attrs

If this is present and the last element in the argument list is a
hashref, it will be scanned for attributes which will modify the query
or directive.  Attributes are command specific, typed, and may be
specified in combination or exclusion.  Attributes are specified in
an array as keyword/type pairs.  Attributes which must appear together
should be in their own array, preceded by the token C<-a>.
Attributes which must not appear together should be in their own
array, preceded by the token C<-o>.  Such clauses may be nested.  

For example:

=over 8

=item C<ydim> and C<xdim> must both be specified:

 -a => [ xdim => FLOAT, ydim => FLOAT ]

=item C<night> and C<day> must not both be specified:

 -o => [ night => BOOL, day => BOOL ]

=item C<ydim> and C<xdim> must both be specified, but cannot
be specified with C<dim>:

 -o => [ ( -a => [ xdim => FLOAT, ydim => FLOAT ] ),
         ( dim => FLOAT ) ]

=back

Note that all clauses are evaluated, to catch possibly typos by the user.

=back

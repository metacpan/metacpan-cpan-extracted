package Image::DS9::Parser;

# ABSTRACT: Parser driver

use v5.10;

use strict;
use warnings;

our $VERSION = 'v1.0.0';

our @CARP_NOT = qw( Image::DS9::Command );

use Image::DS9::PConsts;
use Ref::Util qw( is_arrayref is_coderef is_hashref is_ref is_regexpref );
use Log::Any '$log';

use namespace::clean;

## no critic (Modules::ProhibitMultiplePackages)

{
    package    #
      Image::DS9::Parser::Value;

    sub new {
        my ( $class, $token, $valref, $extra ) = @_;

        return bless {
            token  => $token,
            valref => $valref,
            extra  => $extra,
        }, $class;
    }

    sub token     { $_[0]{token} }
    sub valref    { $_[0]{valref} }
    sub extra     { $_[0]{extra} }
    sub has_extra { defined $_[0]{extra} }


    sub is_ephemeral { $_[0]->token->is_ephemeral }
    sub is_rewrite   { $_[0]->token->is_rewrite }

    sub cvt_from_get {
        my $self = shift;
        die if @_;
        return $self->token->cvt_from_get( $self->valref );
    }

    sub cvt_for_set {
        my $self = shift;
        die if @_;
        return $self->token->cvt_for_set( $self->valref );
    }

}

sub _croak {
    require Carp;
    my $fmt = shift;
    @_ = sprintf( $fmt, @_ );
    goto \&Carp::croak;
}

sub parse_spec {    ## no critic (Subroutines::ProhibitExcessComplexity)
    my $command = shift;
    my $specs   = shift;

    # $log->debug( "parsing: ", { cmd => $command, args => \@_ } );

    # keep the rest of the args in @_, so don't copy data

    my %match;

    my $max_match = 0;
    my $nmatch    = 0;

  SPEC:
    for my $spec ( @$specs ) {
        $max_match = $nmatch if $max_match < $nmatch;

        my $iarg = 0;

        $nmatch = 0;

        $match{cmds} = [];

        # input arguments must have at least the number of
        # sub command slots.
        next if @_ < @{ $spec->[0] };

        # compare against the sub-command slots.
        foreach my $icmd ( 0 .. @{ $spec->[0] } - 1 ) {
            my $value = match( $_[ $iarg++ ], $spec->[0][$icmd] );
            next SPEC unless defined $value;

            # $log->debug( "matched: ", { spec => $spec->[0][$icmd] } );
            push @{ $match{cmds} }, $value;
            $nmatch++;
        }

        $match{spec} = $spec;

        # if we've come this far, we CANNOT match any further specs.  why?
        # well, because the person setting up the spec list is supposed to
        # ensure that!
        $max_match = $nmatch if $max_match < $nmatch;

        my $s_nmatch = $nmatch;
        my $s_iarg   = $iarg;

      ARGLIST:
        for my $argl ( @{$spec}[ 1 .. @{$spec} - 1 ] ) {

            # $log->debug( 'matching', $argl );

            # this may get adjusted if there's an attribute hash, and will
            # need to be reinitialized if this arglist doesn't match
            # and we do another ARGLIST goround
            my $nargs = @_ - @{ $spec->[0] };

            # have to reset pointer into passed arguments for each attempt
            # at matching another argument list
            $iarg = $s_iarg;

            $max_match = $nmatch if $max_match < $nmatch;
            $nmatch    = $s_nmatch;

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
            if ( exists $argl->{attrs} && is_hashref( $_[-1] ) ) {
                $found_attrs = 1;
                # so we don't stumble across 'em
                $nargs--;
            }

            # if we have no passed arguments, and the spec is query only or
            # query possible, we have a match!
            if ( !$nargs && $argl->{query} & ( QONLY | QYES ) ) {
                $match{argl} = $argl;

                # the number of returned values. set to number of possible
                # arguments if not explicitly specified.
                $match{query} = @{ $argl->{rvals} } || @{ $argl->{args} } || 1;
            }

            # correct number of arguments.
            elsif ( $nargs == @{ $argl->{args} } ) {
                $match{args} = [];

                foreach my $arg ( @{ $argl->{args} } ) {
                    # $extra is not yet supported for args
                    my $value = match( $_[ $iarg++ ], $arg );
                    next ARGLIST unless defined $value;

                    push @{ $match{args} }, $value;
                    $nmatch++;
                }

                $match{argl} = $argl;

                # the number of returned values. set to number of possible
                # arguments if not explicitly specified.
                $match{query} = $argl->{query} & QARGS ? @{ $argl->{rvals} } || @{ $argl->{args} } || 1 : 0;
            }

            else {
                next ARGLIST;
            }

            if ( $found_attrs ) {
                # we need to make a copy,
                $match{attrs} = parse_attr( $command, $_[-1], $argl->{attrs} );

                _croak( '%s: cannot specify attributes with this query', $command )
                  if $match{query} && !( $argl->{query} & QATTR );

            }

            # we found it, $match{argl} will have been set.
            last SPEC;
        }

        last SPEC;
    }

    $max_match += $nmatch + 1;

    _croak( '%s: missing, unexpected, or illegal value for argument #%d', $command, $max_match )
      unless defined $match{argl};
    # $log->debug( "matched:", $match{argl} );

    \%match;
}

sub parse_attr {
    my ( $command, $uattr, $specs ) = @_;

    my %attr;

    _parse_attr( $command, \%attr, $uattr, $specs );

    my @unknown = grep { !exists $attr{$_} } keys %$uattr;

    _croak( '%s: unknown attribute(s): %s', $command, join( ', ', @unknown ) ) if @unknown;

    \%attr;
}

sub _parse_attr {
    my ( $command, $attr, $uattr, $specs_ref ) = @_;

    my $nmatch;
    my @res;

    my @specs = @$specs_ref;

    while ( my $spec = shift @specs ) {
        if ( $spec =~ /^-([oa])/ ) {
            my $op = $1;

            my ( $sres, $smatch ) = _parse_attr( $command, $attr, $uattr, shift @specs );

            if ( 'a' eq $op ) {

                # no matches? record and continue
                unless ( $smatch ) {
                    push @res, { what => $sres, match => 0 };
                    next;
                }

                # number of matches should equal number of attrs
                unless ( $smatch == @$sres ) {
                    _croak(
                        '%s: missing attributes: %s',
                        $command, dump_attr_chk( [ { what => $sres, match => 1, op => $op } ] ),
                    );
                }

                push @res, { what => $sres, match => 1, op => $op };
                $nmatch++;
            }

            elsif ( 'o' eq $op ) {

                # no matches? record and continue
                unless ( $smatch ) {
                    push @res, { what => $sres, match => 0 };
                    next;
                }

                # only should have one match
                unless ( $smatch == 1 ) {
                    _croak(
                        '%s: too many attributes: %s',
                        $command, dump_attr_chk( [ { what => $sres, match => 1, op => $op } ] ),
                    );
                }

                push @res, { what => $sres, match => 1, op => $op };
                $nmatch++;
            }

        }
        else {
            my $match = chk_attr( $command, $spec, shift( @specs ), $attr, $uattr );
            $nmatch++ if $match;

            push @res,
              {
                what  => $spec,
                match => $match,
              };
        }
    }
    return \@res, $nmatch;
}

sub dump_attr_chk {
    my ( $chks, $sep ) = @_;

    $sep ||= ' , ';

    my $msg;

    for my $res ( @$chks ) {

        if ( is_arrayref( $res->{what} ) ) {
            my $msep
              = 'a' eq $res->{op} ? ' & '
              : 'o' eq $res->{op} ? ' | '
              :                     _croak( '%s::dump_attr_chk: internal error', __PACKAGE__ );

            my $nmsg = dump_attr_chk( $res->{what}, $msep );
            $msg .= "($nmsg)$sep";
        }
        else {
            $msg .= $res->{what} . ( $res->{match} ? q{} : q{?} ) . $sep;
        }
    }

    $sep =~ s/(\W)/\\$1/g;
    $msg =~ s/$sep$//;

    $msg;
}

sub chk_attr {
    my ( $command, $key, $type, $attr, $uattr ) = @_;

    if ( exists $uattr->{$key} ) {
        # $extra is not yet supported for attrs
        my $value = match( $uattr->{$key}, $type );
        _croak( q{%s: attribute `%s': illegal value. perhaps the wrong type or array length?},
            $command, $key )
          if !defined $value;

        $attr->{$key} = $value;

        return 1;
    }

    return 0;
}

sub match {
    # don't do this! we need to pass by reference to avoid copying tons
    # of data
    #  my ( $value, $type ) = @_;

    my $type = $_[1];

    if ( defined( my $match = $type->check( $_[0] ) ) ) {
        return Image::DS9::Parser::Value->new( $type, $match, $type->extra );
    }

    return undef;
}

#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory QARGS QATTR QNONE QONLY
QYES Subcommand XPASet attrs buf bufarg cvt retref

=head1 NAME

Image::DS9::Parser - Parser driver

=head1 VERSION

version v1.0.0

=for Pod::Coverate chk_attr
dump_attr_chk
match
parse_attr
parse_spec

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

=item QATTR

Query may have attributes.

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

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe::Arg;

use Carp;

use Moo;
use String::ShellQuote;

use Types::Standard qw[ Str ];

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has value => (
    is        => 'rwp',
    isa       => Str,
    predicate => 1,
);

use IPC::PrettyPipe::Arg::Format;

IPC::PrettyPipe::Arg::Format->shadow_attrs;

with 'MooX::Attributes::Shadow::Role';

shadowable_attrs( 'fmt',
		  values %{IPC::PrettyPipe::Arg::Format->shadowed_attrs }
		);

with 'IPC::PrettyPipe::Queue::Element';

has fmt => (
	    is => 'ro',
	    lazy => 1,
	    handles => [ keys %{IPC::PrettyPipe::Arg::Format->shadowed_attrs} ],
	    default => sub {
		IPC::PrettyPipe::Arg::Format->new_from_attrs( shift );
	    },
);


# accept full attribute interface, or
#  new( name );
#  new( [ name, value ] );

sub BUILDARGS {

    my $class = shift;

    if ( @_ == 1 ) {

        return $_[0] if 'HASH' eq ref( $_[0] );

        return { name => $_[0][0], value => $_[0][1] }
          if 'ARRAY' eq ref( $_[0] ) && @{ $_[0] } == 2;

        return { name => $_[0] };

    }

    return {@_};
}

sub quoted_name {  shell_quote( $_[0]->name )  }

sub quoted_value {  shell_quote( $_[0]->value )  }


# for render templates
sub has_blank_value {

    return $_[0]->has_value && $_[0]->value eq '';

}

sub render {

    my $self = shift;

    my $fmt = $self->fmt;

    my $name = ($fmt->has_pfx ? $fmt->pfx : '' ) . $self->name;

    if ( $self->has_value ) {

        if ( $fmt->has_sep ) {

	    return join( '', $name, $fmt->sep, $self->value );

        }
	else {

	    return $name, $self->value;
	}
    }

    else {

	return $name;
    }

}

sub valmatch {

    my $self    = shift;
    my $pattern = shift;

    return $self->has_value && $self->value =~ /$pattern/;
}

sub valsubst {

    my $self = shift;

    my ( $pattern, $rep ) = @_;

    if ( $self->has_value && ( my $value = $self->value ) =~ s/$pattern/$rep/ )
    {

        $self->_set_value( $value );

        return 1;

    }

    return 0;
}

1;

__END__

=head1 NAME

B<IPC::PrettyPipe::Arg> - An argument to an B<IPC::PrettyPipe::Cmd> command

=head1 SYNOPSIS

  use IPC::PrettyPipe::Arg;

  # standard constructor
  $arg = IPC::PrettyPipe::Arg->new( name  => $name,
                                    value => $value, %attr );

  # concise constructors
  $arg = IPC::PrettyPipe::Arg->new( $name );
  $arg = IPC::PrettyPipe::Arg->new( [ $name, $value ] );

  # perform value substitution
  $arg->valsubst( $pattern, $rep );

  # return a rendered argument
  $arg->render;

=head1 DESCRIPTION

B<IPC::PrettyPipe::Arg> objects are containers for arguments to
commands in an B<L<IPC::PrettyPipe::Cmd>> object.

=head1 METHODS

=over 8

=item B<new>

  # named parameters; may provide additional attributes
  $arg = IPC::PrettyPipe::Arg->new( \%attr );

  # concise interface
  $arg = IPC::PrettyPipe::Arg->new( $name );             # switch arg
  $arg = IPC::PrettyPipe::Arg->new( [ $name, $value ] ); # arg w/ value

The available attributes are:

=over

=item C<name>

I<Required>. The name of the argument.

=item C<value>

The value of the argument.  If an argument is a switch, no value is required.

=item C<pfx>

A string prefix to be applied to the argument name before being
rendered. This is often C<-> or C<-->.

A prefix is not required (the argument name may already have it). This
attribute is useful when creating arguments from hashes where the keys
do not contain a prefix.

=item C<sep>

A string to insert between the argument name and value when rendering.
In some cases arguments must be a single string where the name and
value are separated with an C<=> character; in other cases they
are treated as separate entities.  If C<sep> is C<undef> it indicates
that they are treated as separate entitites.  It defaults to C<undef>.

=back

=item B<pfx>

  $current_value = $self->pfx;
  $self->pfx( $new_value );

Get or set the value of the C<pfx> attribute.

=item B<sep>

  $current_value = $self->sep;
  $self->sep( $new_value );

Get or set the value of the C<sep> attribute.

=item B<name>

  $name = $self->name;

The argument's name;

=item B<quoted_name>

  $name = $self->quoted_name;

The argument's name, appropriately quoted for passing as a
single word to a Bourne compatible shell.

=item B<value>

  $value = $self->value;

The argument's value;

=item B<quoted_value>

  $value = $self->quoted_value;

The argument's value, appropriately quoted for passing as a
single word to a Bourne compatible shell.

=item B<has_value>

  $bool = $self->has_value

Returns true if the argument has been assigned a value.

=item B<has_blank_value>

  $bool = $self->has_blank_value

Returns true if the value is the empty string.

=item B<render>

  @rendered_arg = $arg->render;

Render the argument.  If the argument's C<sep> attribute is
defined, B<render> returns a string which looks like:

  $pfx . $name . $sep . $value

If C<sep> is not defined, it returns an array ref which looks like

  $pfx . $name, $value

=item B<valmatch>

  $bool = $arg->valmatch( $pattern );

Returns true if the argument has a value and it matches the passed
regular expression.

=item B<valsubst>

  $arg->valsubst( $pattern, $rep );

If the argument has a value, perform the equivalent to

  $value =~ s/$pattern/$rep/;

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

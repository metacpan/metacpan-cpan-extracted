package Gitosis::Config::Reader;
use Moose;
extends qw(Config::INI::Reader);

sub can_ignore {
    my ( $self, $line ) = @_;
    return $line =~ /\A\s*(?:;|$|#)/ ? 1 : 0;    # Skip comments and empty lines
}

has _current_key => ( isa => 'Str', is => 'rw', );

around parse_value_assignment => sub {
    my ( $next, $self ) = splice @_, 0, 2;       # pull these off @_
    if ( my ( $key, $value ) = $self->$next(@_) ) {
        $self->_current_key($key);
        return ( $key, $value );
    }
    elsif ( $_[0] =~ /^\s*(.+)\s*$/ ) {
        return $self->_current_key, $1;
    }
    return;
};

no Moose;
1;
__END__

=head1 NAME

Gitosis::Config::Reader - A class to read gitosis.conf files.

=head1 SYNOPSIS

    use Gitosis::Config::Reader;
    my $cfg = Gitosis::Config::Reader->read_file( $args->{file} );

=head1 DESCRIPTION

The Gitosis::Config::Reader class extends Config::INI::Reader. 

=head1 METHODS

All methods are exactly the same as Config::INI::Reader except as documented
below.

=head2 can_ignore

Overridden to include lines starting with ; or #

=head2 parse_value_assignment 

Overridden to allow for multiple lines per assignment. The current
implementation is very hackish and may be replaced in the future.

Overriden 

=head1 DEPENDENCIES

Moose, Config::INI::Reader

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut

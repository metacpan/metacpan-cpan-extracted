package MS::Reader::XML::Record;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use XML::Parser;

our $VERSION = 0.001;

sub new {

    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{__use_cache} = $args{use_cache} ? 1 : 0;

    # parse XML into object
    if (defined $args{xml}) {

        # initialize pointer
        $self->{_curr_ref} = $self;
        $self->{filter}    = $args{filter}; # may be undef

        $self->_pre_load();

        my $p = XML::Parser->new();
        $p->setHandlers(
            Start => sub{ $self->_handle_start( @_ ) },
            End   => sub{ $self->_handle_end(   @_ ) },
            Char  => sub{ $self->_handle_char(  @_ ) },
        );
        $p->parse($args{xml});

        $self->_post_load();

        delete $self->{_curr_ref}; # avoid circular reference mem leak
        delete $self->{filter};

        # strip toplevel
        my $toplevel = $self->{_toplevel};
        if (defined $toplevel) {
            $self->{$_} = $self->{$toplevel}->{$_}
                for (keys %{ $self->{$toplevel} });
            delete $self->{$toplevel};
        }

        # delete temporary entries (start with "_")
        for (keys %{$self}) {
            delete $self->{$_} if ($_ =~ /^_/);
        }

    }
    return $self;

}


sub _handle_start {

    my ($self, $p, $el, %attrs) = @_;

    my $new_ref = \%attrs;
    $new_ref->{back} = $self->{_curr_ref};
    
    # Elements that should be grouped by name/id
    if (defined $self->{_make_named_array}->{ $el }) {

        my $id_name = $self->{_make_named_array}->{ $el };
        my $id = $attrs{$id_name};
        delete $new_ref->{$id_name};
        push @{ $self->{_curr_ref}->{$el}->{$id} }, $new_ref;

        # filters are used to short-circuit parses that don't match a given
        # criteria. In some cases this can speed up sequential parsing
        # significantly
        if ($el eq 'cvParam' && defined $self->{filter}) {
            if ($id eq $self->{filter}->[0]
            && $attrs{value} != $self->{filter}->[1]) {
                $self->{filtered} = 1;

                # remove circular references
                delete $self->{_curr_ref}->{back};
                delete $new_ref->{back};

                $p->finish;
            }
        }

    }

    # Elements that should be grouped by name/id
    elsif (defined $self->{_make_named_hash}->{ $el }) {
        my $id_name = $self->{_make_named_hash}->{ $el };
        my $id = $attrs{$id_name};
        die "Colliding ID $id"
            if (defined $self->{_curr_ref}->{$el}->{$id});
        delete $new_ref->{$id_name};
        $self->{_curr_ref}->{$el}->{$id} = $new_ref;
    }

    # Elements that should be grouped with no name
    elsif (defined $self->{_make_anon_array}->{ $el } ) {
        push @{ $self->{_curr_ref}->{$el} }, $new_ref;
    }

    # Everything else
    else {  
        $self->{_curr_ref}->{$el} = $new_ref;
    }

    # Step up linked list
    $self->{_curr_ref} = $new_ref;

    return;

}

sub _handle_end {

    my ($self, $p, $el) = @_;

    # step back down linked list
    my $last_ref = $self->{_curr_ref}->{back};
    delete $self->{_curr_ref}->{back}; # avoid memory leak!
    $self->{_curr_ref} = $last_ref;

    return;

}

sub _handle_char {

    my ($self, $p, $data) = @_;
    $self->{_curr_ref}->{pcdata} .= $data
        if ($data =~ /\S/);
    return;

}

sub dump {

    my ($self) = @_;
    my $copy = {};
    %$copy = %$self;

    delete $copy->{$_} 
        for qw/count md5sum version fh offsets fn index fh pos lengths/;

    my $dump = '';

    {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $dump =  Dumper $copy;
    }

    return $dump;

}

sub _pre_load {} # can be defined by subclass
sub _post_load {} # can be defined by subclass

1;


__END__

=head1 NAME

MS::Reader::XML::Record - Base class for XML-based records

=head1 SYNOPSIS

    package MS::Reader::Foo::Record;

    use parent MS::Reader::XML::Record;

=head1 METHODS

=head2 dump

    my $dump = $spectrum->dump;

Returns a textual representation (via C<Data::Dumper>) of the data structure.
This can facilitate access to data parsed from the MGF record but not
accessible via an accessor method.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2019 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

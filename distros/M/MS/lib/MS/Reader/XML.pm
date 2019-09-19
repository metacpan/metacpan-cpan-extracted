package MS::Reader::XML;

use strict;
use warnings;

use parent qw/MS::Reader/;

use Carp;
use Data::Dumper;
use Data::Lock qw/dlock dunlock/;
use Storable qw/dclone/;
use XML::Parser;

our $VERSION = 0.001;


# this will be called at the end of the new() constructor (prior to parsing)
sub _post_load {

    my ($self) = @_;

    # clean toplevel
    dunlock($self) if ($self->{__lock});
    my $toplevel = $self->{_toplevel};
    if (defined $toplevel) {
        $self->{$_} = $self->{$toplevel}->{$_}
            for (keys %{ $self->{$toplevel} });
        delete $self->{$toplevel};
    }

    my @iterators = exists $self->{__iterators}
        ? @{ $self->{__iterators} }
        : ();

    # reset all record iterators
    $_->{__pos} = 0 for (@iterators);

    # delete temporary entries (start with "_")
    for (keys %{$self}) {
        delete $self->{$_} if ($_ =~ /^_[^_]/);
    }

    return;

}

sub _lock {

    my ($self) = @_;
    dlock($self);
    _iter_unlock($self);

}

sub _unlock {

    my ($self) = @_;
    dunlock($self);

}

sub _iter_unlock {

    my ($ref) = @_;
    return if (! ref $ref);
    if (ref($ref) ne 'ARRAY') {
        for ( grep {$_ =~ /^__/} keys %{$ref} ) {
            dunlock($ref->{$_});
        }
        _iter_unlock($ref->{$_}) for ( grep {$_ !~ /^__/} keys %{$ref} );
    }
    else {
        _iter_unlock($_) for @{$ref};
    }

}


sub _load_new {

    my ($self) = @_;

    my $fh = $self->{__fh};

    $self->{_curr_ref} = $self;

    my $p = XML::Parser->new();
    $p->setHandlers(
        Start => sub{ $self->_handle_start( @_) },
        End   => sub{ $self->_handle_end( @_) },
        Char  => sub{ $self->_handle_char( @_) },
    );

    $p->parse($fh);

    seek $fh, 0, 0;

    return;

}


# XML stream handlers
    
sub _handle_start {

    my ($self, $p, $el, %attrs) = @_;

    # track offsets of requested items
    if (defined $self->{_make_index}->{ $el }) {

        my $id = $attrs{ $self->{_make_index}->{$el} }
            or croak "ID attribute missing on indexed element";

        my $iter = defined $self->{_curr_ref}->{__offsets}
            ? scalar @{ $self->{_curr_ref}->{__offsets} }
            : 0;
        $self->{_curr_ref}->{__offsets}->[$iter] = $p->current_byte;
        $self->{_curr_ref}->{__index}->{$id} = $iter;
        $self->{_curr_ref}->{__count} = $iter + 1;
        if (! defined $self->{_curr_ref}->{__pos}) {
            $self->{_curr_ref}->{__pos} = 0;
            push @{ $self->{__iterators} }, $self->{_curr_ref}; # clean up after!
            $self->{_curr_ref}->{__record_type} = $el;
        }

    }

    # skip parsing inside certain elements
    if (defined $self->{_skip_inside}->{ $el }) {
        $p->setHandlers(
            Start => undef,
            End   => sub{ $self->_handle_end( @_) },
            Char  => undef,
        );
        $self->{_skip_parse} = 1;
        return;
    }

    my $new_ref = {%attrs};
    $new_ref->{_back} = $self->{_curr_ref};

    # Elements that should be grouped by name/id
    if (defined $self->{_make_named_array}->{ $el }) {

        my $id_name = $self->{_make_named_array}->{ $el };
        my $id = $attrs{$id_name};
        delete $new_ref->{$id_name};
        push @{ $self->{_curr_ref}->{$el}->{$id} }, $new_ref;

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

    # Track length of indexed elements
    if (defined $self->{_make_index}->{$el}) {
        my $iter = scalar @{ $self->{_curr_ref}->{__offsets} } - 1;
        my $offset = $self->{_curr_ref}->{__offsets}->[$iter];

        my $len = $p->current_byte - $offset;
        # Don't forget to add length of tag and "</>" chars
        # if an element is not empty (i.e. if it has a closing tag).
        # There may be a better way to deduce this based on the parser itself,
        # but current empty elements must be defined in the subclass itself.
        if (! defined $self->{_empty_el}->{$el}) {
            $len += length($el) + 3;
        }
        $self->{_curr_ref}->{__lengths}->[$iter] = $len;

    }

    # Reset handlers for skipped elements
    if (defined $self->{_skip_inside}->{$el}) {
        $p->setHandlers(
            Start => sub{ $self->_handle_start( @_) },
            End   => sub{ $self->_handle_end( @_) },
            Char  => sub{ $self->_handle_char( @_) },
        );
        delete $self->{_skip_parse};
        return;
    }

    # Don't do anything if inside skipped element
    return if ($self->{_skip_parse});

    # Step back down linked list
    my $last_ref = $self->{_curr_ref}->{_back};
    delete $self->{_curr_ref}->{_back};
    $self->{_curr_ref} = $last_ref;

    return;

}

sub _handle_char {

    my ($self, $p, $data) = @_;
    $self->{_curr_ref}->{pcdata} .= $data
        if ($data =~ /\S/);
    return;

}

sub goto {

    my ($self, $ref, $idx) = @_;
    croak "Bad list ref" if (! exists $ref->{__pos});
    croak "$idx not an integer" if ($idx =~ /\D/);
    # $idx allowed to be equal to count because this indicates end-of-records
    croak "$idx out of range" if ($idx < 0 || $idx > $ref->{__count});
    $ref->{__pos} = $idx;
    return;

}

sub fetch_record {

    my ($self, $ref, $idx, %args) = @_;

    croak "Bad list ref" if (! exists $ref->{__pos});
    
    # check record cache if used
    return $ref->{__memoized}->{$idx}
        if ($self->{__use_cache} && exists $ref->{__memoized}->{$idx});

    my $offset = $ref->{__offsets}->[ $idx ];
    croak "Record not found for $idx" if (! defined $offset);

    my $to_read = $ref->{__lengths}->[ $idx ];
    my $el   = $self->_read_element($offset,$to_read);

    my $type = $ref->{__record_type};
    my $class = $self->{__record_classes}->{$type};
    croak "No class defined for record type $type\n" if (! defined $class);
    my $record = $class->new( xml => $el,
        use_cache => $self->{__use_cache}, %args );

    # cache record if necessary
    if ($self->{__use_cache}) {
        #dunlock($ref);
        $ref->{__memoized}->{$idx} = $record;
        #dlock($ref);
    }
    
    return $record;

}

sub next_record {

    my ($self, $ref, %args) = @_;

    my $pos = $ref->{__pos};
    return if ($pos == $ref->{__count}); #EOF

    my $record;

    # There is a while loop here because a return value of -1 from
    # fetch_record() means the record was filtered out, in which case we
    # keep trying to find a valid record to return
    my $c = 0;
    while ($record = $self->fetch_record( $ref => $pos, %args)) {
        ++$pos;
        $ref->{__pos} = $pos;

        return $record if (! defined $record || ! $record->{filtered}); 
        return undef if ($pos == $ref->{__count}); #EOF
    }

    return $record;

}

sub record_count {

    my ($self, $ref) = @_;
    die "Bad list ref" if (! exists $ref->{__count});
    return $ref->{__count};

}

sub get_index_by_id {

    my ($self, $ref, $id) = @_;
    die "Bad list ref" if (! exists $ref->{__index});
    return $ref->{__index}->{$id};

}

sub curr_index {

    my ($self, $ref) = @_;
    die "Bad list ref" if (! exists $ref->{__pos});
    return $ref->{__pos};

}

sub _iter_del {

    my ($ref) = @_;
    return if (! ref $ref);
    if (ref($ref) ne 'ARRAY') {
        delete $ref->{$_} for ( grep {$_ =~ /^__/} keys %{$ref} );
        _iter_del($ref->{$_}) for keys %{$ref};
    }
    else {
        _iter_del($_) for @{$ref};
    }

}

sub dump {

    my ($self) = @_;

    my $fh = $self->{__fh};
    dunlock $self;
    _iter_del($self);

    my $dump = '';

    {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $dump = Dumper $self;
    }

    return $dump;

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::XML - Base class for XML-based parsers

=head1 SYNOPSIS

    package MS::Reader::Foo;

    use parent MS::Reader::XML;

    sub _init {}
    sub _finalize{}

    package main;

    use MS::Reader::Foo;

    my $run = MS::Reader::Foo->new('run.foo');

    while (my $record = $foo->next_record('bar') {
       
        # etc

    }

=head1 DESCRIPTION

C<MS::Reader::XML> is the base class for XML-based parsers in the package.
The class and its methods are not generally called directly, but publicly
available methods are documented below.

=head1 METHODS

=head2 fetch_record

    my $r = $parser->fetch_record($ref => $idx);

Takes two arguments (record reference and zero-based index) and returns a
record object. The types of records available and class of the object
returned depends on the subclass implementation. 

=head2 next_record

    while (my $r = $parser->next_record($ref);

Takes a single argument (record reference) and returns the next record in the
parser, or undef if the end of records has been reached. Types of records
available depend on the subclass implementation.

=head2 record_count

    my $n = $parser->record_count($ref);

Takes a single argument (record reference) and returns the number of records of
that type present. Types of records available depend on the subclass
implementation.

=head2 get_index_by_id

    my $i = $parser->get_index_by_id($ref => 'bar');

Takes two arguments (record reference and record ID) and returns the zero-based
index associated with that record ID, or undef if not found. Types of records
available and format of the ID string depend on the subclass implementation.

=head2 curr_index

    my $i = $parser->curr_index($ref);

Takes a single argument (record reference) and returns the zero-based index of the
"current" record. This is similar to the "tell" function on an iterable
filehandle and is generally used in conjuction with C<next_record>.

=head2 goto

    $parser->goto($ref => $i);

Takes two arguments (record reference and zero-based index) and sets the current
index position for that record reference. This is similar to the "seek" function on
an iterable filehandle and is generally used in conjuction with
C<next_record>.

=head2 dump

    $parser->dump();

Returns a textual serialization of the underlying data structure (via
L<Data::Dumper>) as a string. This is useful for developers who want to access
data details not available by accessor.

WARNING WARNING WARNING: This is a destructive process - don't try to use the
object after dumping its contents!!!

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

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

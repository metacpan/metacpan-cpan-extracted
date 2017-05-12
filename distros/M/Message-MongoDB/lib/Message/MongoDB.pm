package Message::MongoDB;

use 5.006;
use strict; use warnings FATAL => 'all';
use MongoDB;

=head1 NAME

Message::MongoDB - Message-oriented interface to MongoDB

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

    use Message::MongoDB;

    my $mongo = Message::MongoDB->new();

    $mongo->message({
        mongo_db => 'my_db',
        mongo_collection => 'my_collection',
        mongo_method => 'insert',
        mongo_write => { a => 'b' },
    });

    $mongo->message({
        mongo_db => 'my_db',
        mongo_collection => 'my_collection',
        mongo_method => 'find',
        mongo_search => { },
    });

    #the emit method will be called with an array reference that contains
    #{a => 'b'}


=head1 SUBROUTINES/METHODS

=head2 new

    my $mongo = Message::MongoDB->new();

Nothing too interesting at this point.

=cut

sub new {
    my $class = shift;
    die "Message::MongoDB::new: even number of argument required\n"
        if scalar @_ % 2;
    my $self = {
        connection => undef,
    };

    my %args = @_;
    bless ($self, $class);
    return $self;
}

sub _connect {
    my $self = shift;
    return if $self->{connection};
    return $self->{connection} = MongoDB::MongoClient->new($self->auth);
}

sub _collection {
    my $self = shift;
    my $db_name = shift;
    my $collection_name = shift;
    $self->_connect();
    my $db = $self->{connection}->get_database($db_name);
    return $db->get_collection($collection_name);
}

#this is for testing...probably should put it in Test.pm
sub _get_documents {
    my $self = shift;
    my $db_name = shift;
    my $collection_name = shift;
    my $collection = $self->_collection($db_name,$collection_name);
    my $ret = [];
    my $cursor = $collection->find;
    while(my $doc = $cursor->next) {
        push @$ret, $doc;
    }
    return $ret;
}


=head2 message

    $mongo->message({
        mongo_db => 'my_db',
        mongo_collection => 'my_collection',
        mongo_method => 'insert',
        mongo_write => { a => 'b' },
    });

Execute the specified mongo_method on the specified mongo_db and
mongo_collection.

=over 4

=item * message (first positional, required)

=over 4

=item * mongo_db (required)

Scalar referencing the mongo database to operate on.

=item * mongo_collection (required)

Scalar referencing the mongo collection to operate on.

=item * mongo_method (required)

Scalar indicating the mongo method to run.  One of

=over 4

=item * find

Requires C<mongo_search>

=item * insert

Requires C<mongo_write>

=item * update

Requires C<mongo_search> and C<mongo_write>

=item * remove

Requires C<mongo_search>

=back

=item * mongo_search

MongoDB search criteria.

 { a => 'b', c => { '$gt' => 99 } }

=item * mongo_write

MongoDB 'write' criteria, for update and insert.

 { a => 'b', x => [1,2,3] }  #for insert

 { a => 'b', c => { '$set' => 100 } }  #for update

=back

=back
=cut
sub message {
    my $self = shift or die "Message::MongoDB::message: must be called as a method\n";
    my $message = shift;
    die "Message::MongoDB::message: must have at least one argument, a HASH reference\n"
        if  not $message or
            not ref $message or
            ref $message ne 'HASH';
    die "Message::MongoDB::message: even number of argument required\n"
        if scalar @_ % 2;
    my %args = @_;
    my $mongo_db = $message->{mongo_db};
    my $mongo_collection = $message->{mongo_collection};
    my $mongo_method = $message->{mongo_method};
    my $mongo_write = $message->{mongo_write};
    my $mongo_search = $message->{mongo_search};
    my $coll = $self->_collection($mongo_db, $mongo_collection);
    if($mongo_method eq 'insert') {
        $coll->insert($mongo_write);
    } elsif($mongo_method eq 'remove') {
        $coll->remove($mongo_search);
    } elsif($mongo_method eq 'update') {
        $coll->update($mongo_search, { '$set' => $mongo_write }, {upsert => 1, multiple => 1});
    } elsif($mongo_method eq 'find') {
        my $cursor = $coll->find($mongo_search);
        my $ret;
        while(my $doc = $cursor->next) {
            push @$ret, $doc;
        }
        $self->emit(message => $ret);
    } else {
        die "unknown mongo_method passed: '$mongo_method'";
    }
}

=head2 auth

This returns the authentication bits necessary to talk to the desired
MongoDB.

Defaults to all defaults; localhost and port 27017.  Over-ride as
necessary.

=cut
sub auth {
    my $self = shift;
    return ();
}

=head2 emit

    $merge->emit(%args)

This method is designed to be over-ridden; the default implementation simply
adds the outbound message, which is an ARRAY reference of HASHrefs
which represents the MongoDB result set, to the package global
@Message::MongoDB::return_messages

=cut
our @return_messages = ();
sub emit {
    my $self = shift;
    my %args = @_;
    push @return_messages, $args{message};
    return \%args;
}




=head1 AUTHOR

Dana M. Diederich, C<< <diederich at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-message-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Message-MongoDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Message::MongoDB


You can also look for information at:

=over 4

=item * Report bugs and feature requests here

L<https://github.com/dana/perl-Message-MongoDB/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Message-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Message-MongoDB>

=item * Search CPAN

L<https://metacpan.org/module/Message::MongoDB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Message::MongoDB

# $Id$
package Handel::Iterator::RDBO;
use strict;
use warnings;
use overload
        '0+'     => \&count,
        'bool'   => \&count,
        '=='     => \&count,
        fallback => 1;

BEGIN {
    use base qw/Handel::Iterator::List/;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed/;
};

sub count {return shift->SUPER::count(@_)};

1;
__END__

=head1 NAME

Handel::Iterator::RDBO - Iterator class used for collection looping RDBO resultsets

=head1 SYNOPSIS

    my $resultset = Rose::DBO::Object::Manager->get_objects(
        object_class => 'MySchemaClass'
    );
    
    my $iterator = Handel::Iterator::RDBO->new({
        data         => $resultset,
        result_class => 'MyResult',
        storage      => $storage
    });
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 DESCRIPTION

Handel::Iterator::RDBO is a used to iterate through results stored in a
resultset returned from Rose::DB::Object::Manager queries.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new iterator object. The following options are available:

    my $resultset = Rose::DBO::Object::Manager->get_objects(
        object_class => 'MySchemaClass'
    );
    
    my $iterator = Handel::Iterator::RDBO->new({
        data         => $resultset,
        result_class => 'MyResult',
        storage      => $storage
    });

    my $result = $iterator->first;
    print ref $result; # MyResult

=over

=item data

The data to be iterated through. This should be an array ref returned from
Rose::DB::Object::Manager methods like C<get_objects>.

=item result_class

The name of the class that each result should be inflated into.

=item storage

The storage object that was used to create the results.

=back

=head1 METHODS

=head2 all

Returns all results from current iterator.

    foreach my $result ($iterator->all) {
        print $result->method;
    };

=head2 count

Returns the number of results in the current iterator.

    my $count = $iterator->count;

=head2 create_result

=over

=item Arguments: $result [, $storage]

=back

Returns a new result class object based on the specified result and storage
objects. If no storage object is specified, the storage object passed to C<new>
will be used instead.

This method is used by methods like C<first> and C<next> to to create storage
result objects. There is probably no good reason to use this method directly.

=head2 first

Returns the first result or undef if there are no results.

    my $first = $iterator->first;

=head2 last

Returns the last result or undef if there are no results.

    my $last = $iterator->last;

=head2 next

Returns the next result or undef if there are no results.

    while (my $result = $iterator->next) {
        print $result->method;
    };

=head2 reset

Resets the current result position back to the first result.

    while (my $result = $iterator->next) {
        print $result->method;
    };
    
    $iterator->reset;
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 SEE ALSO

L<Handel::Iterator::List>, L<Handel::Iterator>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/


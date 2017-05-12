package List::Analyse::Sequence;

use warnings;
use strict;

use Module::Pluggable (
    search      => [ "List::Analyse::Sequence::Analyser" ],
    sub_name    => 'analysers',
);
use List::MoreUtils qw(part);

our $VERSION = '0.01';

sub new {
    my $class   = shift;
    my $self    = bless {}, $class;

    return $self;
}

sub use_these_analysers {
    my $self    = shift;

    # Module::Pluggable does not give us the option of postponing
    # the require stage until we actually request the plugin be used.
    eval " CORE::require $_ " or warn $@ for @_; 
    $self->{analysers} = [map {$_->new} @_];
}

sub analyse {
    my $self    = shift;
    my @data    = @_;

    $self->add( $_ ) for @data;
}

sub add {
    my $self    = shift;
    my $datum   = shift;

    $self->{discard} ||= [];

    my ($discarded_analysers, $remaining_analysers)
        = part { $_->analyse( $datum ) ? 1 : 0 } @{ $self->{analysers} };

    $discarded_analysers ||= []; $remaining_analysers ||= [];

    $self->{analysers} = $remaining_analysers;
    push @{ $self->{discard} }, @$discarded_analysers;
}

sub result {
    my $self    = shift;

    # Some analysers may be lazy or may need to wait.
    $_->done for @{$self->{analysers}};

    return ($self->{analysers}, $self->{discard}) if wantarray;
    return $self->{analysers};
}

1;
__END__

=head1 NAME

List::Analyse::Sequence - Analyse a list for sequences.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Given a list, analyse it for sequences. Sequences are defined by
their Analyser classes, which are plugins to this module and are
found under L<List::Analyse::Sequence::Analyser>.

=head1 SYNOPSIS

    use List::Analyse::Sequence;

    my $analyser = List::Analyse::Sequence->new();

    $analyser->use_these_analysers( $analyser->analysers );

    $analyser->analyse( @list );
    my @($valid_sequences, $invalid_sequences) = $analyser->result;
    
    # ... OR ... #

    while ( my $list_item = $some_iterator->next ) {
        $analyser->add( $list_item );
    }

    my ($valid_sequences, $invalid_sequences) = $analyser->result;

=head1 CONSTRUCTOR

=head2 new

Creates a new sequence analyser.

=head1 METHODS

=head2 analysers

Returns a list of available analysers. You can create an analyser by putting
a module in somewhere that List::Analyse::Sequence::Analyser::* will find.

See L<List::Analyse::Sequence::Analyser> for info.

=head2 use_these_analysers

Pick a bunch of analysers from $obj->analysers and provide them here. These
will be used to analyse the list.

If you're feeling cocky then you should know that the list passed in is just
a bunch of class names whose constructors are expected to be new().

=head2 analyse

Pass in a list of things to analyse. Each of your analysers will look at the
list and decide whether or not the list adheres to its sequence definition.

=head2 add

An alternative to passing a list to analyse() is to pass a scalar to add. This
will run each analyser on the added element.

This is especially useful for when you are using an iterator, or some form of 
lasagne code, for example.

=head2 result

Get the result of the analysis, as two arrayrefs. The first will contain those
analysers whose sequence definitions were fulfilled by all items: the second
will contain those that were discarded.

=head1 AUTHOR

Alastair Douglas, C<< <altreus at perl.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-list-analyse-sequence at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=List-Analyse-Sequence>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Analyse::Sequence


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Analyse-Sequence>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Analyse-Sequence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-Analyse-Sequence>

=item * Search CPAN

L<http://search.cpan.org/dist/List-Analyse-Sequence/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Alastair Douglas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


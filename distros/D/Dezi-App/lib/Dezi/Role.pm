package Dezi::Role;
use Moose::Role;
use Dezi::Types qw( DeziLogLevel );

our $VERSION = '0.014';

has 'debug' => (
    is      => 'rw',
    isa     => DeziLogLevel,
    lazy    => 1,
    default => sub { $ENV{DEZI_DEBUG} || 0 },
    coerce  => 1,
);
has 'verbose' => (
    is      => 'rw',
    isa     => DeziLogLevel,
    lazy    => 1,
    default => sub { $ENV{DEZI_VERBOSE} || 0 },
    coerce  => 1,
);
has 'warnings' => (
    is      => 'rw',
    isa     => DeziLogLevel,
    lazy    => 1,
    default => sub {
        return 1 unless exists $ENV{DEZI_WARNINGS};
        $ENV{DEZI_WARNINGS} || 0;
    },
    coerce => 1,
);

=pod

=head1 NAME

Dezi::Role - common attributes for Dezi classes

=head1 SYNOPSIS

 package My::Class;
 use Moose;
 with 'Dezi::Role';
 # other stuff
 1;
 
 # see METHODS for what you get for free

=head1 DESCRIPTION

Dezi::Role isa Moose::Role. It creates a few attributes (see L<METHODS>)
common to most Dezi classes.

=head1 METHODS

=head2 BUILD

Initializes new object.

=head2 debug

Get/set the debug level. Default is C<DEZI_DEBUG> env var or 0.

=head2 warnings

Get/set the warnings level. Default is C<DEZI_WARNINGS> env var or 1.

=head2 verbose

Get/set flags affecting the verbosity of the program. Default is C<DEZI_VERBOSE> env var or 0.

=cut

sub BUILD {
    my $self = shift;
    $self->{_start} = time();
}

=head2 elapsed

Returns the elapsed time in seconds since object was created.

=cut

sub elapsed {
    return time() - shift->{_start};
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Class

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>


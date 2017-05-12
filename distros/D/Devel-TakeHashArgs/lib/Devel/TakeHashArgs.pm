package Devel::TakeHashArgs;

use warnings;
use strict;

our $VERSION = '0.006';

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(get_args_as_hash);
our @EXPORT_OK = qw(set_self_args_as_hash);

sub set_self_args_as_hash {
    my ( $in_args, $opts, $mandatory_opts, $valid_opts ) = @_;
    my $class = shift @$in_args;

    get_args_as_hash(
        $in_args, \ my %args, $opts, $mandatory_opts, $valid_opts
    ) or return 0; # $@ will be set with an error;

    my $self = bless {}, $class;

    $self->$_( $args{ $_ } ) for keys %args;

    return $self;
}

sub get_args_as_hash {
    my ( $in_args, $out_args, $opts, $mandatory_opts, $valid_opts ) = @_;

    $valid_opts = []
        unless defined $valid_opts;

    @$in_args & 1
        and $@ = "Must have correct number of arguments"
        and return 0;

    %$out_args = @$in_args;
    $out_args->{ +lc } = delete $out_args->{ $_ } for keys %$out_args;

    %$out_args = (
        %{ $opts || {} },

        %$out_args,
    );

    for ( @$mandatory_opts ) {
        unless ( exists $out_args->{$_} ) {
            $@ = "Missing mandatory argument `$_`";
            return 0;
        }
    }

    if ( @$valid_opts ) {
        my %valid;
        @valid{ @$valid_opts } = (1) x @$valid_opts;
        for ( keys %$out_args ) {
            unless ( $valid{$_} ) {
                $@ = "Invalid argument `$_`";
                return 0;
            }
        }
    }

    1;
}

1;
__END__

=encoding utf8

=head1 NAME

Devel::TakeHashArgs - make a hash from @_ and set defaults in subs while checking that all mandatory arguments are present

=head1 SYNOPSIS

    use Devel::TakeHashArgs;
    use Carp;
    sub foos {
        get_args_as_hash( \@_, \ my %args,
            { foos => 'bars' },     # these are optional with defaults
            [ qw(ber1 ber2) ],      # these are mandatory
            [ qw(ber1 ber2 foos) ], # only these args are valid ones
        )
            or croak $@;

        print map { "$_ => $args{$_}\n" } keys %args;
    }

=head1 DESCRIPTION

The module is a short utility I made after being sick and tired of writing
redundant code to make a hash out of args when they are passed as
key/value pairs including setting their defaults and checking for mandatory
arguments.

=head1 EXPORT DEFAULT

The module has only one sub and it's exported by default.

=head2 C<get_args_as_hash>

    sub foos {
        get_args_as_hash( \@_, \my %args, {
                some => 'defaults',
                more => 'defaults2!',
            },
            [ qw(mandatory1 mandatory2) ],
            [ qw(only these are valid arguments) ],
        )
            or croak $@;
    }

The sub makes out a hash out of C<@_>, checks that all mandatory arguments
were provided (if any), assigns optional defaults (if any) and fills
the passed hashref. B<Returns> C<1> for success and C<0> for failure,
upon failure the reason for it will be available in C<$@> variable...

The sub takes two mandatory arguments: the reference to an array
(the C<@_> but it can be any array) and a reference to a hash where you want
your args to go. The other three optional arguments are a hashref
which would contain
the defaults to assign unless the argument is present in the passed array.
Following the hashref is an arrayref of mandatory arguments. Following it
is an arrayref which lists valid arguments. If you want
to specify mandatory arguments without providing any defaults just pass in
an empty hashref as a third argument, i.e.
C<< get_args_as_hash( \@_, \ my %args, {}, [ qw(mandatory1 mandatory2) ]) >>

Same goes for "no defaults" and "no mandatory" but "only these are valid"
i.e.: C<< get_args_as_hash( \@_, \ my %args, {}, [], [ 'valid' ] ) >>

=head1 EXPORT OPTIONAL

=head2 C<set_self_args_as_hash>

    use Carp;
    use Devel::TakeHashArgs 'set_self_args_as_hash';

    sub new {
        my $self = set_self_args_as_hash( \@_, {
                default => 'value',
            },
            [ qw(these  are  mandatory) ],
            [ qw(only  these  are  valid  arguments) ],
    }

This sub is not exported by default. It is to be used in constructors.
The accepted arguments are the same as for C<get_args_as_hash> B<except>
for the "missing" second argument - just skip the C<\ my %args>.

Returns a blessed hashref with provieded arguments filled in using
accessors/mutators. In other words the following two snippets are
equivalent.

    # using get_args_as_hash()

    use Devel::TakeHashArgs;
    sub new {
        my $class = shift;
        get_args_as_hash( \@_, \ my %args, {
                optional => 'value',
            },
            [ 'mandatory' ],
            [ qw(optional mandatory) ],
        ) or croak $@;

        my $self = bless {}, $class;
        $self->$_( $args{ $_ } ) for keys %args;
        return $self;
    }

    # ...is the same as...

    use Devel::TakeHashArgs 'set_self_args_as_hash';
    sub new {
        my $self = set_self_args_as_hash( \@_, {
                optional => 'value',
            },
            [ 'mandatory' ],
            [ qw(optional mandatory) ],
        ) or croak $@;

        return $self;
    }

=head1 EXAMPLES

=head2 example 1

    sub foo {
        my $self = shift;
        get_args_as_hash( \@_, \ my %args, { foos => 'bars' } )
            or croak $@;

        if ( $args{foos} eq 'bars' ) {
            print "User did not specify anything for 'foos' argument\n";
        }
        else {
            print "User specified $args{foos} as value for 'foos'\n";
        }
    }

This subroutine will first remove the object which foo() is a method of.
Then it will stuff any key/value paired args into hash C<%args> and will
set key C<foo> to value C<bars> unless user specified that argument.

=head2 example 2

    sub foo {
        get_args_as_hash( \@_, \ my %args, {}, [ 'foos' ] )
            or croak $@;

        print "User specified $args{foos} as a mandatory argument\n";
    }

This subroutine will not set any default args but will make argument
C<foos> a mandatory one and will eat the user if he/she won't specify
that argument. Note: user may pass as many other arguments as he/she wants

=head2 example 3

    sub foo {
        get_args_as_hash( \@_, \ my %args, {}, [], [ 'foos' ] )
            or croak $@;

        if ( keys %args ) {
            print "User set `foos` to $args{foos} and that's the only argument\n";
        }
        else {
            print "User chose not to set any arguments\n";
        }
    }

This sub will not set any defaults and will not claim any arguments
mandatory B<but> the only argument it will allow is argument named C<foos>
(thus the assumption in the code that if C<%args> got any keys then it
must be C<foos> and no others)

=head2 example 4

    sub foo {
        get_args_as_hash( \@_, \ my %args,
            { foos  => 'bars' },
            [ qw(bar beer) ],
            [ qw(foos bar beer) ],
        ) or croak $@;
    }

This is full action: user may specify only C<foos>, C<bar> and C<beer>
arguments, out of which C<bar> and C<beer> and mandatory and argument
C<foos> will be set to value C<bars> if not specified. Note: setting
mandatory argument arrayref to C<[ qw(foos bar beer) ]> would have
the same effect, because we are setting default for C<foos> thus it will
always be present no matter what.

=head1 CAVEATS AND LIMITATIONS

All argument names (the hash keys) will be lowercased therefore when setting
defaults and mandatory arguments you can only use all lowercase names.
On a plus side, user can use whatever case they want :)

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-takehashargs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TakeHashArgs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::TakeHashArgs

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-TakeHashArgs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-TakeHashArgs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-TakeHashArgs>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-TakeHashArgs>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

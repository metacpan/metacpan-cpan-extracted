package Function::Version;
# Define and use different function versions
use strict; use warnings; use utf8; use 5.10.0;
our $VERSION = '0.0002';
use Carp;

# 2D Dispatch table
my $DISPATCH = {};

## CLASS CONSTRUCTORS
sub def {
    my ($class,$fname,$ver,$sub) = @_;

    # Create dispatch with $fname as key if needed
    $DISPATCH->{$fname} = {}
        unless exists $DISPATCH->{$fname};

    # Store the sub into the dispatch table
    $DISPATCH->{$fname}{$ver} = $sub;

    return $class;
}

sub new { bless _init(@_[1..$#_]), $_[0] }
sub _init {
    return {
        ver      => undef,      # Selected version
        fname    => undef,      # Selected function
        dispatch => $DISPATCH   # 2D Dispatch Table
    }
}
sub ver {
    my ($self,$ver) = @_;

    # Guard: Caller should be an object
    croak "Error. You have not selected a function."
        unless ref $self eq 'Function::Version';

    my ($fname) = ($self->{fname});

    # Guard: The selected version of the function must be defined
    croak "Error. Version '$ver' of '$fname' not in definition."
        unless exists $self->{dispatch}{$fname}{$ver};

    $self->{ver} = $ver;
    return $self;
}
sub func {
    my ($self,$fname) = @_;

    if ($self eq 'Function::Version') {
        $self = Function::Version->new;       # Convert the class into an object
    } else {
        croak "Error: Assigned to '".$self->{fname}."' already.";
    }

    # Guard: Selected function must be defined
    croak "Error. Selected function '$fname' not in definition."
        unless exists $self->{dispatch}{$fname};

    $self->{fname} = $fname;
    return $self;
}
sub with {
    my ($self,@args) = @_;

    # Guard: Caller should be an object
    croak "Error. You have not selected a function."
        unless ref $self eq 'Function::Version';

    my ($fname,$ver) = ($self->{fname},$self->{ver});

    $self->{dispatch}{$fname}{$ver}(@args);
}

1;

=encoding utf-8
=cut
=head1 NAME

Function::Version - Define and use different function versions

=cut
=head1 SYNOPSIS

  use Function::Version;

  # Define two versions of load() and dump()
  my $defn = Function::Version
               ->def('load', '1.5', sub { "load v1.5: $_[0]" })
               ->def('load', '1.6', sub { "load v1.6: $_[0]" })
               ->def('dump', '1.5', sub { "dump v1.5: $_[0]" })
               ->def('dump', '1.6', sub { "dump v1.6: $_[0]" })
               ;

  my $load = $defn->func('load')          # Select load() v1.5
                  ->ver('1.5');
  my $dump = $defn->func('dump')          # Select dump() v1.6
                  ->ver('1.6');

                                          # Call with arguments
  say $load->with('vista');               # load v1.5: vista
  say $dump->with('gems');                # dump v1.6: gems

  say $load->ver('1.6')                   # Use other versions
           ->with('hobbits');             # load v1.6: hobbits

                                          # Version does not revert
  say $load->with('ring');                # load v1.6: ring

  say $dump->func('load')                 # Using other function dies
           ->with('hobbits');             # Error: Assigned to dump()

=cut
=head1 DESCRIPTION

This module provides a simple way to define and use different function
versions.

One use case is when deploying changes to an application. Being able to
select the function based on a version number is useful to roll-back or
roll-forward changes.

=cut
=head1 AUTHOR

Hoe Kit CHEW E<lt>hoekit@gmail.comE<gt>

=cut
=head1 COPYRIGHT

Copyright 2021- Hoe Kit CHEW

=cut
=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


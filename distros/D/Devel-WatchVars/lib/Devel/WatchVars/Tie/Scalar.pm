package Devel::WatchVars::Tie::Scalar;

=encoding utf8

=cut

use utf8;
use strict;
use warnings;
no overloading;

use Carp qw(shortmess);

our $VERSION = "v1.0.5";

(my $PKG = __PACKAGE__) =~ s/::Tie::Scalar//;

push our @CARP_NOT => $PKG, qw(
    Data::Dump 
    Data::Dumper
);

use Devel::GlobalDestruction;

sub mycarp {
    local $\;
    print STDERR &mymess;
}

sub mymess {
    local $Carp::Verbose = $ENV{DEVEL_WATCHVARS_VERBOSE} ? 1 : 0;
    return &shortmess;
}

sub redef($) {
    return $_[0] // "undef";
}

use namespace::clean;

###########################################################

sub TIESCALAR {
    my($class, $name, $value) = @_;
    unless ($name) {
        $name = mymess "some scalar variable";
        $name =~ s/ at (\S.*) (line \d+)[.]?\n\z/ watched at $2 of $1/;
    }
    mycarp "WATCH $name = ", redef $value;
    return bless {
        name  => $name,
        value => $value,
    }, $class;
}

sub FETCH {
    my($self) = @_;
    mycarp "FETCH $$self{name} --> ", redef $$self{value};
    return $$self{value};
}

sub STORE {
    my($self, $new_value) = @_;
    mycarp "STORE $$self{name} <-- ", redef $new_value;
    return $$self{value} = $new_value;
}

sub DESTROY {
    my($self) = @_;
    my $action =
          in_global_destruction                      ? "DESTROY (during global destruction)"
        : ((caller 2)[3] // "") eq "${PKG}::unwatch" ? "UNWATCH"
        :                                              "DESTROY";
    mycarp "$action $$self{name} = ", redef $$self{value};
    if (my $sref = $$self{sref}) {
          $$sref = $$self{value} unless in_global_destruction;
    } 
    delete @$self{keys %$self};
}

1;

__END__

=head1 NAME

Devel::WatchVars::Tie::Scalar - scalar tie class internal to L<Devel::WatchVars>

=head1 SYNOPSIS

None. This is an internal class.

=head1 DESCRIPTION

This internal class contains the implementation used by L<Devel::WatchVars>
for watching scalars -- or, more precisely, for watching scalar L<I<lvalues>|perlglossary/lvalue>.

See L<the DEVEL_WATCHVARS_VERBOSE envariable|Devel::WatchVars/DEVEL_WATCHVARS_VERBOSE>
for how to control trace-message verbosity.

=head2 Internal Methods

=over

=item C<< TIESCALAR I<CLASS>, I<DESC>, I<VALUE> >>

Called when you tie a scalar variable to this package.

The L<C<watch> function|Devel::WatchVars/watch> takes care of this for you.

=item C<< FETCH I<INSTANCE> >>

Called when you fetch the old value from  a variable tied to this package.

=item C<< STORE I<INSTANCE>, I<VALUE> >>

Called when you store a new value into a variable tied to this package.

=item C<< DESTROY I<INSTANCE> >>

Called upon the backing object's destruction.

The L<C<unwatch> function|Devel::WatchVars/unwatch> normally takes care of this for you.

=back

=head1 CAVEATS

Because of internal bookkeeping on these objects in part maintained by
L<that other module|Devel::WatchVars>, it is critical that this internal
class be used B<only> from that module's public
L<C<watch>|Devel::WatchVars/watch> and
L<C<unwatch>|Devel::WatchVars/unwatch> functions.

=head1 TODO

Devise a subclassing mechanism.

=head1 AUTHOR

Tom Christiansen C<< <tchrist53147@gmail.com> >>. 

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020-2021 by Tom Christiansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


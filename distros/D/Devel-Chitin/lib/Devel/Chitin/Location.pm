package Devel::Chitin::Location;

use strict;
use warnings;

our $VERSION = '0.18';

use Carp;
use Scalar::Util qw(weaken reftype);

sub new {
    my $class = shift;
    my %props = @_;

    my @props = $class->_required_properties;
    foreach my $prop ( @props ) {
        unless (exists $props{$prop}) {
            Carp::croak("$prop is a required property");
        }
    }

    if (exists $props{subref}
        and
        ( !ref($props{subref}) or reftype($props{subref}) ne 'CODE' )
    ) {
        Carp::croak("'subref' attribute must be a coderef, not $props{subref}");
    }

    my $self = bless \%props, $class;
    return $self;
}

sub _required_properties {
    qw( package filename line subroutine );
}

sub _optional_properties {
    qw( callsite subref );
}

sub at_end {
    my $self = shift;
    return (($self->package eq 'Devel::Chitin::exiting')
            &&
            ($self->subroutine eq 'Devel::Chitin::exiting::at_exit'));
}

sub current {
    my $class = shift;
    my %props = @_;

    for (my $i = 0; ; $i++) {
        my @caller = caller($i);
        last unless @caller;
        if ($caller[3] eq 'DB::DB') {
            @props{'package','filename','line'} = @caller[0,1,2];
            $props{subroutine} = (caller($i+1))[3];
            $props{callsite} = get_callsite($i);

            my $subref = Devel::Chitin->current_sub;
            if (ref $subref) {
                $props{subref} = $subref;
            }

            last;
        }
    }
    return $class->new(%props);
}

sub _make_accessors {
    my $package = shift;
    my @accessor_names;
    @accessor_names = ( $package->_required_properties, $package->_optional_properties );
    if ($package ne __PACKAGE__) {
        # called as a class method by a subclass
        my %base_class_accessors = map { $_ => 1 } (_required_properties(), _optional_properties());
        @accessor_names = grep { ! $base_class_accessors{$_} } @accessor_names;
    }
 
    foreach my $acc ( @accessor_names ) {
        my $sub = sub { return shift->{$acc} };
        my $subname = "${package}::${acc}";
        no strict 'refs';
        *{$subname} = $sub;
    }
}

sub get_callsite { undef }

BEGIN {
    __PACKAGE__->_make_accessors();

    local $@;
    my $site = eval { require Devel::Callsite && Devel::Callsite::callsite() };
    if ($site) {
        my $get_callsite_name = join('::', __PACKAGE__, 'get_callsite');
        no strict 'refs';
        no warnings 'redefine';
        *$get_callsite_name = \&Devel::Callsite::callsite;
    }
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::Location - A class to represent an executable location

=head1 SYNOPSIS

  my $loc = Devel::Chitin::Location->new(
                package     => 'main',
                subroutine  => 'main::foo',
                filename    => '/usr/local/bin/program.pl',
                line        => 10);
  printf("On line %d of %s, subroutine %s\n",
        $loc->line,
        $loc->filename,
        $loc->subroutine);

=head1 DESCRIPTION

This class is used to represent a location in the debugged program.

=head1 METHODS

  Devel::Chitin::Location->new(%params)

Construct a new instance.  The following parameters are accepted.  The values
should be self-explanatory.  All parameters except callsite are required.

=over 4

=item package

=item filename

=item line

=item subroutine

=item callsite

Represents the opcode address of the location as reported by Devel::Callsite::callsite().
This value will only be valid if the optional module L<Devel::Callsite> is installed.

=item subref

A coderef to the currently executing subroutine.  This will only be a valid
value if this Location object was constructed through C<Devel::Chitin->current_location()>,
and the current subroutine is an anonymous function.

=back

Each construction parameter also has a read-only method to retrieve the value.

=over 4

=item at_end

Return true if the location refers not to any location in the program, but
after the program has ended.

=back

=head1 SEE ALSO

L<Devel::Chitin::Exception>, L<Devel::Chitin>, L<Devel::Callsite>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

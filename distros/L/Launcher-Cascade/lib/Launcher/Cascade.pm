package Launcher::Cascade;

=head1 NAME

Launcher::Cascade - a framework for launching processes that depend on one another

=head1 SYNOPSIS

    use Launcher::Cascade::Simple;
    use Launcher::Cascade::Container;

    my $launcher1 = Launcher::Cascade::Simple->new(
        -launch_hook  => sub { ... },    # what to do to launch
        -test_hook    => sub { ... },    # what to do to test that it succeeded
        );
    my $launcher2 = Launcher::Cascade::Simple->new(
        -launch_hook  => sub { ... },    # what to do to launch
        -test_hook    => sub { ... },    # what to do to test that it succeeded
        -dependencies => [ $launcher1 ], # second launcher depends on success of first
    );

    my $container = new Launcher::Cascade::Container
	-launchers => [ $launcher1, $launcher2 ];

    $container->run_session();

=head1 DESCRIPTION

This module provides a framework to launch processes, test whether they
succeeded or not and report on that. Each process is modeled as an object and
can depend on other processes to start, i.e., a process will not be started
until all the processes it depends upon have successfully been started.

Process launchers must be implemented as C<Launcher::Cascade::Base> objects (or
subclassses thereof). Their launch() method will actually launch the process,
and their test() method will check whether it succeeded or not. Each launcher
can be made to depend on one or more other launchers: it will then refuse to
launch() until the others have been test()ed successfully.

All the launchers should be given to a C<Launcher::Cascade::Container>, which will
run them in turn and test their status when applicable, until either all of the
Launchers have succeeded or one of them has failed.

The distribution provides C<Launcher::Cascade::FileReader> to ease the launching
of external (and possibly remote, by means of ssh) commands and the reading of
files. FileReaders should be used in launch() or test() methods of Launchers.

This base class provides a constructor for its subclasses that accepts named
arguments, as well as function to easily create attributes and their accessors.
All the real functionality has to be implemented in subclasses.

=cut

use strict;
use warnings;

=head2 Constructor

=over 4

=item B<new> I<LIST>

Creates and returns an instance. I<LIST> should be a list of named parameters.
The values will be passed to the accessors of the same name. Leading dashes
will be removed from the names, and they will be converted to lowercase before
invoking the accessor.

=back

=cut

sub new {

    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $self = bless {}, $class;

    while ( @_ ) {
        my ($key, $value) = (lc(shift), shift);
        $key =~ s/^-+//;
        $self->$key($value);
    }
    
    return $self;
}

=head2 Functions

=over 4

=item B<make_accessors> I<LIST>

Make accessors in the caller's namespace.

I<LIST> should contain names of accessors. make_accessors() will generate an
accessor for each name in I<LIST>, that will return the corresponding
attribute's value when called without argument, and set the attribute's value
when called with an argument (in that latter case, the former value is
returned). Example:

    package MyPackage;

    use Launcher::Cascade;
    our @ISA = qw/ Launcher::Cascade /; # inherits constructor

    Launcher::Cascade::make_accessors qw/ first_name last_name /;

    1;

Meanwhile, in a nearby piece of code:

    use MyPackage;

    my $object = new MyPackage -first_name => 'Zaphod';
    print $object->first_name(); # Zaphod

    print $object->last_name('Beeblebrox'); # undef
    print $object->last_name(); # Beeblebrox

=cut

sub make_accessors {

    my ($package) = caller();
    foreach my $name ( @_ ) {
        my $method = join '::', $package, $name;
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            my $old = $self->{"_$name"};
            $self->{"_$name"} = $_[0] if @_;
            return $old;
        };
    }
}

=item B<read_default_file> I<FILENAME>

Reads a file containing the definition of default values for subclasses
attributes.  The file should contain name, value pairs, one by line, separated
by an equal sign. Whitespace is ignored at the beginning or end of the line and
on either side of the equal sign. Lines starting with a hash sign are ignored,
as well as blank lines.

The name should be the fully qualified accessor method name, i.e., the package
and name of the accessor separated by a double colon.

    # This is an example

    MyPackage::first_name = Zaphod
    MyPackage::last_name  = Beeblebrox

=cut

my %default;
sub read_default_file {

    my $filename = shift;

    open my $fh, '<', $filename or die "Cannot read $filename: $!";
    while ( <$fh> ) {
        chomp;
        s/^\s+|\s+$//g;
        next if /^#/ || /^$/;
        my ($k, $v) = split /\s*=\s*/, $_, 2;
        $default{$k} = $v;
    }
    close $fh;
}

=item B<make_accessors_with_defaults> I<LIST>

Does the same as make_accessors(), but elements in I<LIST> should go in pairs,
accessor names together with their default values. If the attribute's value has
not explicitly been set, the accessor will return the default value as read
from the defaults file (see read_default_file()) or the default value provided
in I<LIST>. The defaults file overrides the value from I<LIST>.

    package MyPackage;

    use Launcher::Cascade;
    our @ISA = qw/ Launcher::Cascade /;

    Launcher::Cascade::make_accessors_with_defaults(
        first_name => 'Zaphod',
        last_name  => 'Beeblebrox',
    );

Meanwhile, in a nearby piece of code:

    use MyPackage;
    
    my $o = new MyPackage;
    print $o->first_name(); # Zaphod

=cut

sub make_accessors_with_defaults {

    my ($package) = caller();
    my %attr = @_;
    while ( my ($name, $default) = each %attr ) {
        my $method = join '::', $package, $name;
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            my $old = defined($self->{"_$name"}) ? $self->{"_$name"} : $default{$method} || $default;
            $self->{"_$name"} = $_[0] if @_;
            return $old;
        };
    }
}

=back

=head1 VERSION

0.02

=cut

our $VERSION = 0.02;

=head1 SEE ALSO

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade

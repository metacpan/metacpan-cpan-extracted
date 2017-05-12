package HackaMol::X::Roles::ExtensionRole;
$HackaMol::X::Roles::ExtensionRole::VERSION = '0.013';
# ABSTRACT: Role to assist writing HackaMol extensions to external programs
use 5.008;
use Moose::Role;
use Capture::Tiny ':all';
use File::chdir;
use Carp;

with qw(HackaMol::Roles::ExeRole HackaMol::Roles::PathRole);

requires qw(_build_map_in _build_map_out build_command);

has 'mol' => (
    is  => 'rw',
    isa => 'HackaMol::Molecule',
    predicate => 'has_mol',
    clearer   => 'clear_mol',
);

has 'map_in' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_map_in',
    builder   => '_build_map_in',
    lazy      => 1,
);
has 'map_out' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_map_out',
    builder   => '_build_map_out',
    lazy      => 1,
);

sub map_input {

    # pass everything and anything to map_in... i.e. keep @_ in tact
    my ($self) = @_;
    local $CWD = $self->scratch if ( $self->has_scratch );
    return ( &{ $self->map_in }(@_) );

}

sub map_output {

    # pass everything and anything to map_out... i.e. keep @_ in tact
    my ($self) = @_;
    local $CWD = $self->scratch if ( $self->has_scratch );
    return ( &{ $self->map_out }(@_) );

}

sub capture_sys_command {

    # run it and return all that is captured
    my $self    = shift;
    my $command = shift;
    unless ( defined($command) ) {
        return 0 unless $self->has_command;
        $command = $self->command;
    }

    local $CWD = $self->scratch if ( $self->has_scratch );
    my ( $stdout, $stderr, @exit ) = capture {
        system($command);
    };
    return ( $stdout, $stderr, @exit );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::X::Roles::ExtensionRole - Role to assist writing HackaMol extensions to external programs

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    package HackaMol::X::SomeExtension;
    use Moose;

    with qw(HackaMol::X::Roles::ExtensionRole);

    sub _build_map_in{
      my $sub_cr = sub { return (@_) };
      return $sub_cr;
    }

    sub _build_map_out{
      my $sub_cr = sub { return (@_) };
      return $sub_cr;
    }

    sub BUILD {
      my $self = shift;

      if ( $self->has_scratch ) {
          $self->scratch->mkpath unless ( $self->scratch->exists );
      }
    }

    no Moose;
    1;

=head1 DESCRIPTION

The HackaMol::X::Roles::ExtensionRole includes methods and attributes that are useful for building extensions
with code reuse.  This role will improve as extensions are written and needs arise.  This role is flexible
and can be encapsulated and rigidified in extensions.  Advanced use of extensions should still be able to 
access this flexibility to allow tinkering with internals!  Consumes HackaMol::Roles::ExeRole and HackaMol::Roles::PathRole
... ExeRole may be removed from core and wrapped in here.

=head1 METHODS

=head2 map_input

the main function is to change to scratch directory, if set, and pass all arguments (including self) to 
map_in CodeRef.

  $calc->map_input(@args);

will invoke,

  &{$calc->map_in}(@_);  #where @_ = ($self,@args)

and return anything returned by the map_in function. Thus, any input writing should take place in map_in 
inorder to actually write to the scratch directory.

=head2 map_output

completely analogous to map_input.  Thus, the output must be opened and processed in the
map_out function.

=head2 build_command 

builds the command from the attributes: exe, inputfn, exe_endops, if they exist, and returns
the command.

=head2 capture_sys_command

uses Capture::Tiny capture method to run a command using a system call. STDOUT, STDERR, are
captured and returned.

  my ($stdout, $stderr,@other) = capture { system($command) }

the $command is taken from $calc->command unless the $command is passed,

  $calc->capture_sys_command($some_command);

capture_sys_command returns ($stdout, $stderr,@other) or 0 if there is no command set.

=head1 ATTRIBUTES

=head2 scratch

Coerced to be 'Path::Tiny' via AbsPath. If scratch is set, map_input and map_output will local CWD to the
scratch to carry out operations. See HackaMol::PathRole for more information about the scratch attribute 
and other attributes available (such as in_fn and out_fn).

=head2 mol

isa HackaMol::Molecule that is ro

=head2 map_in

isa CodeRef that is ro.  The default builder is required for consuming classes.

intended for mapping input files from molecular information, but it is completely
flexible. Used in map_input method.  Can also be directly ivoked,

  &{$calc->map_in}(@args); 

as any other subroutine would be. Extensions can build the map_in function so that it returns 
the content of $input which can then be written within API methods.

=head2 map_out

isa CodeRef that is ro.  The default builder is required for consuming classes.

intended for mapping molecular information from output files, but it is completely
flexible and analogous to map_in. 

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::ExeRole>

=item * L<HackaMol::Roles::ExeRole|HackaMol::Roles::PathRole>

=item * L<HackaMol::Roles::PathRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

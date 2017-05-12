package IkiWiki::Plugin::syntax::X;
use strict;
use warnings;
use Carp;
use utf8;

use IkiWiki::Plugin::syntax::gettext;

our $VERSION = '0.1';

use Exception::Class (
    'Syntax::X',
    'Syntax::X::Parameters'   =>  {
        isa         =>  'Syntax::X',
        description =>  gettext(q(Missing parameters or wrong values)),
    },
    'Syntax::X::Parameters::None' => {
        isa         =>  'Syntax::X::Parameters',
        description =>  gettext(q(Missing all required parameters)),
    },
    'Syntax::X::Parameters::Source' => {
        isa         =>  'Syntax::X::Parameters',
        description =>  gettext(q(Missing source text)),
    },
    'Syntax::X::Parameters::Wrong' => {
        isa         =>  'Syntax::X::Parameters',
        description =>  gettext(q(Wrong value in parameter)),
        fields      =>  [ qw(parameter value) ],
    },
    'Syntax::X::Engine'   =>  {
        isa         =>  'Syntax::X',
        description =>  gettext(q(Exception found in the external engine)),
        fields      =>  [ qw(package) ],
    },
    'Syntax::X::Engine::Use'   =>  {
        isa         =>  'Syntax::X::Engine',
        description =>  gettext(q(Could not use the module)),
    },
    'Syntax::X::Engine::Language'   =>  {
        isa         =>  'Syntax::X::Engine',
        description =>  gettext(q(Unsupported syntax of language)),
        fields      =>  [ qw(language) ],
    },
    'Syntax::X::Template' =>  {
        isa         =>  'Syntax::X',
        description =>  gettext(q(Not access to or not found templates)),
    },
);

package Syntax::X;

sub full_message {
    my  $self   =   shift;
    my @ret = ();
    foreach my $m ( $self->__first_line(),
                    $self->__message(),
                    $self->__fields() ) {
        push(@ret, $m) if $m;
    }

    return join("", @ret);
}

sub __first_line {
    my $self = shift;
    my $program_name = $0 || $self->file();
    my $local_time = localtime($self->time());
    my $package = $self->package() || __PACKAGE__;
    my $file = $self->file();
    my $line = $self->line();
    my $pid = $self->pid();
    my $uid = sprintf("uid=%u,gid=%u,euid=%u,egid=%u",
                $self->uid(), $self->gid(), $self->euid(),
                $self->egid());
    $package = sprintf("package %s,", $package) if $package;

    return <<EOF;
${program_name}(${pid}): error fatal in ${package}
  file ${file}, line ${line} at ${local_time}
  with ${uid}
EOF
}

sub __message {
    my $self = shift;

    my $ret = $self->message() || ref($self)->description()
            || 'unknown error';

    return sprintf("\n%s\n\n", $ret);
}

sub __fields {
    my $self = shift;
    my @ret = ( );

    foreach my $f (ref($self)->Fields()) {
        my  $value = $self->{$f} || '';
        push(@ret, sprintf("    %s = %s\n", $f, $value));
    }

    return @ret ? ("  additional info:\n", @ret) : ();
}

## 
#   Before the version 1.23 of the Exception::Class package the method caught
#   is not inheritable by the Exception::Class::Base subpackages.
## 

sub caught {
    return Exception::Class->caught(@_);
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::X - Declare exceptions for the package

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::exceptions version 0.1

=head1 SYNOPSIS

    package IkiWiki::Plugin::syntax::MyEngine;
    use base qw(IkiWiki::Plugin::syntax::base);

    use IkiWiki::Plugin::syntax::X;

    if ($we_have_a_problem_with_a_external_module) {
        Syntax::X::Engine->throw( 'module not found' );
    }
        
=head1 DESCRIPTION

This module declare exception classes for the IkiWiki syntax hightligh plugin.

By laziness the exception root class is abbreviated as I<Syntax::X>. 

=head1 SUBROUTINES/METHODS

This package don't have any public methods nor subroutines.

=head1 DIAGNOSTICS

A list of every error and warning message that the module
can generate.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to <Maintainer name(s)> (<contact address>).
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 "Víctor Moral" <victor@taquiones.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.


This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US


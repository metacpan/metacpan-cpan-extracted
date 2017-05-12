package Dist::Zilla::Plugin::JSAN::InstallInstructions;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::InstallInstructions::VERSION = '0.06';
}

# ABSTRACT: build an INSTALL file

use Moose;

use Dist::Zilla::File::InMemory;

use Data::Section 0.004 -setup;

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';


has 'filename' => (
    is      => 'rw',
    isa     => 'Str',
    
    default => 'INSTALL'
);


sub gather_files {
    my ($self) = @_;
    
    my $zilla           = $self->zilla;

    $self->add_file(Dist::Zilla::File::InMemory->new({
        name    => $self->filename,
        
        content => $self->fill_in_string(${$self->section_data('INSTALL')}, {
            zilla   => \$zilla,
            dist    => \$zilla,
            plugin  => \$self
        })
    }));
}


sub dist_name {
    my ($self) = @_;
    
    my $name = $self->zilla->name;
    
    $name =~ s/-/\./g;
    
    return $name;
}


__PACKAGE__->meta->make_immutable;
no Moose;


1;





=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::InstallInstructions - build an INSTALL file

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

  [JSAN::InstallInstructions]
  filename       = INSTALL; this is a default

=head1 DESCRIPTION

This plugin adds an F<INSTALL> file to the distribution, which describes the installation
process with `npm`

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
__[ INSTALL ]__
The installation procedure for {{ $plugin->dist_name }}

NPM
===

`{{ $plugin->dist_name }}` is being distributed via NPM - [Node Package Manager][npm]. Obviously
it requires the NodeJS to be installed.  

To install `npm` please follow the instructions on its site. After that, run:

        > npm install {{ lc($zilla->name) }}

Thats all, `npm` will download and install `{{ $plugin->dist_name }}` for you. 

For the list of available commands, try `npm help`.  


CONFIGURING YOUR SYSTEM
=======================

If you are planning to use this module in the cross-platform fashion (interoperable between browsers
and NodeJS), you may want to perform this additional (optional) configuration steps:

- Add the `.jsan` subdirectory of the root of your `npm` installation to the NODE_PATH environment variable.

- Configure you local web server in the way, that the url `http://localhost/jsan` will point to the 
`.jsan` subdirectory of the root of your `npm` installation. 

To find the root of `npm` installation run:
    
    > npm config get root



AUTHOR
======

{{ $OUT .= $_ . "\n\n" foreach (@{$dist->authors})  }}


COPYRIGHT AND LICENSE
=====================

{{ $dist->license->notice }}

[npm]: http://npmjs.org/

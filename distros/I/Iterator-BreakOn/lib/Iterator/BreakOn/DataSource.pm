package Iterator::BreakOn::DataSource;
use strict;
use warnings;
use Carp;
use utf8;
use English;

our $VERSION = '0.1';

sub new {
    my  $class  =   shift;
    my  $self   =   {
        code_for_next   =>  undef,
        use_get_package =>  0,
    };

    bless $self,$class;

    return $self->_init(@_);
}

sub _init {
    my  $self   =   shift;
    my  %params =   @_;

    # copy the parameters
    foreach my $key (keys %{ $self }) {
        if (defined $params{$key}) {
            $self->{$key} = $params{$key};
        }
    }
    
    # and check the required parameter
    if (not ref($self->{code_for_next}) eq 'CODE') {
        Iterator::BreakOn::X->missing( parameter => 'code_for_next' );
    }

    return $self;
}

sub next {
    my  $self   =   shift;

    # call the user supply code 
    my $item = eval {
        $self->{code_for_next}->();
    };

    # checking errors 
    if (my $e = Iterator::BreakOn::X->caught()) {
        # if it's a reference
        if (ref($e)) {
            $e->rethrow();
        }
        else {
            # build a new exception for it
            Iterator::BreakOn::X::datasource->throw();
        }
    }
        
    if ($self->{use_get_package}) {
        return Iterator::BreakOn::DataSource::GetMethod->new( $item );
    }
    else {
        return $item;
    }
}

package Iterator::BreakOn::DataSource::GetMethod;

my $_singleton = undef;

sub new {
    my  $class          =   shift;
    my  $item_source    =   shift;

    if (not $_singleton) {
        bless $_singleton, $class;
    }

    $_singleton->{item} = $item;

    return $_singleton;
}

sub get {
}

sub getall {
}

1;
__END__

=head1 NAME

Iterator::BreakOn::DataSource - Wrapper for extensions of Iterator::BreakOn

=head1 SYNOPSIS

    package Iterator::BreakOn::MyFormat;
    use base qw(Iterator::BreakOn::Base);

    use Iterator::BreakOn::DataSource;

    sub new {
        my  $class  =   shift;
        my  %params =   @_;

        my $dh = Iterator::BreakOn::DataSource->new(
                      code_for_next => \&_my_next_item 
                      );
        my  $self   =   $class->SUPER::new( %params, datasource => $dh );

        return $self;                                
    }

    sub _my_next_item {
        my  $self   =   shift;      # discard or not

        # do something for get a next item

        # and return it
        return $my_next_item;       # object reference with a get method
    }


=head1 DESCRIPTION

B<WARNING> This is experimental code

This module provides an auxiliary mechanism for those data sources not object
oriented but we need use with Iterator::BreakOn.

=head1 SUBRUTINES/METHODS

=head2 new( )

=head2 next( )

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

Copyright (C) 2007 <Victor Moral>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


package Gapp::Actions;
{
  $Gapp::Actions::VERSION = '0.60';
}
use Moose;

use Gapp::Actions::Base;
use Gapp::Actions::Util;
use Carp::Clan qw( ^Gapp::Actions );
use Sub::Name;

use namespace::clean -except => [qw( meta )];

sub import {
    my ($class, %args) = @_;
    my  $callee = caller;

    strict->import;
    warnings->import;

    # inject base class into new library
    {   no strict 'refs';
        unshift @{ $callee . '::ISA' }, 'Gapp::Actions::Base';
    }

    # generate predeclared action helpers
    if (my @orig_declare = @{ $args{ -declare } || [] }) {
        my @to_export;
        
        for my $action (@orig_declare) {
            
            croak q[could not create action ($action): actions may not contain '::']
                if $action =~ /::/;
            
            # add action to library and remember to export
            $callee->declare_action( $action );
            push @to_export, $action;
        }
        
        $callee->import({ -full => 1, -into => $callee }, @to_export);
    }

    Gapp::Actions::Util->import({ into => $callee });

    1;
}


sub action_export_generator {
    my ( $class, $caller, $name ) = @_;
    
    return subname "__ACTION__::" . $caller . "::" . "$name" => sub {
        return ACTION_REGISTRY( $caller )->action( $name );
    };
}

sub perform_export_generator {
    my ( $class, $caller, $name ) = @_;
    
    return sub {
        my $action = ACTION_REGISTRY( $caller )->action( $name );
        return $action->code->( $action, @_ );
    };
}

1;


__END__

=pod

=head1 NAME

Gapp::Actions - Create Actions for Gapp Applications

=head1 SYNOPSIS

    package My::Actions;

    use Gapp::Actions -declare =>[qw( PrintStuff )];

    action PrintStuff => (

        label => 'Print',

        tooltip => 'Print',

        icon => 'gtk-print',

        code => sub {

            my ( $action, $widget, $gobject, $args, $gtk_args ) = @_;

            my ( $stuff ) = @$args;

        }

    );

    ... later ...

    package main;

    use My::Actions qw( PrintStuff );

    # assign to button
    Gapp::Button->new( action => [PrintStuff, 'stuff'] );

    # use as callback
    Gapp::Button->new->signal_connect( clicked => PrintStuff, 'stuff' );
    
    # call directly
    do_PrintStuff( undef, undef, ['stuff'], undef );
  
=head1 DESCRIPTION

Actions are chunks of code that know how to display themselves on buttons,
menus and other objects. They can be called directly, or used as callbacks.

=head1 SEE ALSO

L<MooseX::Types>

=head1 ACKNOWLEDGEMENTS

Many thanks to the C<#moose> cabal on C<irc.perl.org>, and all those who
contributed to the L<MooseX::Types> module, making L<Gapp::Actions> possible.

=head1 AUTHORS

Robert "phaylon" Sedlacek <rs@474.at>

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 CONTRIBUTORS

jnapiorkowski: John Napiorkowski <jjnapiork@cpan.org>

caelum: Rafael Kitover <rkitover@cpan.org>

rafl: Florian Ragwitz <rafl@debian.org>

hdp: Hans Dieter Pearcey <hdp@cpan.org>

autarch: Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2007-2009 Robert Sedlacek <rs@474.at>

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut



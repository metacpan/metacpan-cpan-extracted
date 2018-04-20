package JavaScript::Duktape::XS;

use strict;
use warnings;

use XSLoader;
use parent 'Exporter';

our $VERSION = '0.000048';
XSLoader::load( __PACKAGE__, $VERSION );

our @EXPORT_OK = qw[];

1;

__END__

=pod

=encoding utf8

=head1 NAME

JavaScript::Duktape::XS - Perl XS binding for the Duktape Javascript embeddable
engine

=head1 VERSION

Version 0.000048

=head1 SYNOPSIS

    my $duk = JavaScript::Duktape::XS->new();

    my %options = ( gather_stats => 1);
    my $duk = JavaScript::Duktape::XS->new(\%options);

    $duk->set('global_name', [1, 2, 3]);
    $duk->set('my.object.slot', { foo => [ 4, 5 ] });
    $duk->set('function_name', sub { my @args = @_; return \@args; });

    my $aref = $duk->get('global_name');

    my $returned = $duk->eval('function_name(my.object.slot)');

    $duk->dispatch_function_in_event_loop('function_name');

    my $stats = $duk->get_stats(); # returns a hashref

    my $msgs = $duk->get_msgs(); # returns a hashref

=head1 DESCRIPTION

This module provides an XS wrapper to call Duktape from Perl.

=head1 METHODS/ATTRIBUTES

=head2 new

=head2 set

=head2 get

=head2 eval

=head2 dispatch_function_in_event_loop

=head2 get_stats

=head2 get_msgs

=head1 SEE ALSO

L<< https://metacpan.org/pod/JavaScript::Duktape >>

=head1 LICENSE

Copyright (C) Gonzalo Diethelm.

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license.

=head1 AUTHOR

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * L<< Sami Vaarala|https://github.com/svaarala >> for creating the L<<
Duktape Javascript embeddable engine|http://duktape.org >>.

=back

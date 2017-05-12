package IPC::Run::SafeHandles;

use warnings;
use strict;
use IO::Handle ();
use List::MoreUtils 'any';

=head1 NAME

IPC::Run::SafeHandles - Use IPC::Run and IPC::Run3 safely

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use IPC::Run::SafeHandles;

=head1 DESCRIPTION

L<IPC::Run> and L<IPC::Run3> are both very upset when you try to use
them under environments where you have STDOUT and/or STDERR tied to
something else, such as under fastcgi.

The module adds safe-guarding code when you call L<IPC::Run> or
L<IPC::Run3> under such environment to make sure it always works.

If you intend to release your code to work under normal envionrment
as well as under fastcgi, simply use this module I<after> the C<IPC>
modules are loaded in your code.

=cut

my $wrapper_context = [];

sub _wrap_it {
    no strict 'refs';
    my $typeglob = shift;
    my $caller = shift;

    my $original = *$typeglob{CODE};
    my $unwrap = 0;

    my $wrapper = sub {

        goto &$original unless $ENV{FCGI_ROLE}
            || any { $_ eq 'via'} PerlIO::get_layers(*STDOUT), PerlIO::get_layers(*STDERR);

	my $stdout = IO::Handle->new;
	$stdout->fdopen( 1, 'w' );
	local *STDOUT = $stdout;

	my $stderr = IO::Handle->new;
	$stderr->fdopen( 2, 'w' );
	local *STDERR = $stderr;
	$original->(@_);
    };
    no warnings 'redefine';
    my $callerglob = $typeglob; $callerglob =~ s/IPC::Run3?/$caller/;
    *{$typeglob} = $wrapper;
    *{$callerglob} = $wrapper;
    push @$wrapper_context,
	bless(sub { no warnings 'redefine';
                    *{$callerglob} = $original;
		    *{$typeglob} = $original }, __PACKAGE__);
}

sub import {
    my $caller = caller();
    _wrap_it('IPC::Run::run', $caller)   if $INC{'IPC/Run.pm'};
    _wrap_it('IPC::Run3::run3', $caller) if $INC{'IPC/Run3.pm'};

    unless (@$wrapper_context) {
	Carp::carp "Use of IPC::Run::SafeHandles without using IPC::Run or IPC::Run3 first";
    }
}

=head2 unimport

When unimport, the original L<IPC::Run> and/or L<IPC::Run3> functions
are restored.

=cut

sub unimport {
    $wrapper_context = [];
}

sub DESTROY { $_[0]->() }

=head1 AUTHOR

Chia-liang Kao, C<< <clkao at bestpractical.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ipc-run-safehandles at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Run-SafeHandles>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Run::SafeHandles

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Run-SafeHandles>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Run-SafeHandles>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-Run-SafeHandles>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-Run-SafeHandles>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Chia-liang Kao, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPC::Run::SafeHandles

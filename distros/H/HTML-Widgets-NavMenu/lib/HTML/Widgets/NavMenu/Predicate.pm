package HTML::Widgets::NavMenu::Predicate;
$HTML::Widgets::NavMenu::Predicate::VERSION = '1.0902';
use strict;
use warnings;

use parent 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref( [qw(type bool regexp callback _capture)], );

use HTML::Widgets::NavMenu::ExpandVal;

sub _init
{
    my $self = shift;

    my %args = (@_);

    my $spec = $args{'spec'};

    $self->_process_spec($spec);

    return 0;
}

my %true_vals = ( map { $_ => 1 } (qw(1 yes true True)) );

sub _is_true_bool
{
    my $self = shift;
    my $val  = shift;
    return exists( $true_vals{$val} );
}

my %false_vals = ( map { $_ => 1 } (qw(0 no false False)) );

sub _is_false_bool
{
    my $self = shift;
    my $val  = shift;
    return exists( $false_vals{$val} );
}

sub _get_normalized_spec
{
    my $self = shift;
    my $spec = shift;

    if ( ref($spec) eq "HASH" )
    {
        return $spec;
    }
    if ( ref($spec) eq "CODE" )
    {
        return +{ 'cb' => $spec };
    }
    if ( $self->_is_true_bool($spec) )
    {
        return +{ 'bool' => 1, };
    }
    if ( $self->_is_false_bool($spec) )
    {
        return +{ 'bool' => 0, };
    }

    # Default to regular expression
    if ( ref($spec) eq "" )
    {
        return +{ 're' => $spec, };
    }
    die "Unknown spec type!";
}

sub _process_spec
{
    my $self = shift;
    my $spec = shift;

    # TODO: Replace me with the real logic.
    $self->_assign_spec( $self->_get_normalized_spec( $spec, ), );
}

sub _assign_spec
{
    my $self = shift;
    my $spec = shift;

    if ( exists( $spec->{'cb'} ) )
    {
        $self->type("callback");
        $self->callback( $spec->{'cb'} );
    }
    elsif ( exists( $spec->{'re'} ) )
    {
        $self->type("regexp");
        $self->regexp( $spec->{'re'} );
    }
    elsif ( exists( $spec->{'bool'} ) )
    {
        $self->type("bool");
        $self->bool( $spec->{'bool'} );
    }
    else
    {
        die "Neither 'cb' nor 're' nor 'bool' were specified in the spec.";
    }

    $self->_capture( ( ( !exists( $spec->{capt} ) ) ? 1 : $spec->{capt} ) );
}

sub _evaluate_bool
{
    my ( $self, $args ) = @_;

    my $path_info    = $args->{'path_info'};
    my $current_host = $args->{'current_host'};

    my $type = $self->type();

    if ( $type eq "callback" )
    {
        return $self->callback()->(%$args);
    }
    elsif ( $type eq "bool" )
    {
        return $self->bool();
    }
    else    # $type eq "regexp"
    {
        my $re = $self->regexp();
        return ( ( $re eq "" ) || ( $path_info =~ /$re/ ) );
    }
}

sub evaluate
{
    my $self = shift;

    my $bool = $self->_evaluate_bool( {@_} );

    if ( !$bool )
    {
        return $bool;
    }
    else
    {
        return HTML::Widgets::NavMenu::ExpandVal->new(
            {
                capture => $self->_capture()
            },
        );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Predicate - a predicate object for
HTML::Widgets::NavMenu

=head1 VERSION

version 1.0902

=head1 SYNOPSIS

    my $pred = HTML::Widgets::NavMenu::Predicate->new('spec' => $spec);

=head1 FUNCTIONS

=head2 my $pred = HTML::Widgets::NavMenu::Predicate->new('spec' => $spec)

Creates a new object.

=head2 $pred->evaluate( 'path_info' => $path_info, 'current_host' => $current_host )

Evaluates the predicate in the context of C<$path_info> and C<$current_host>
and returns the result.

=head2 $pred->type()

The type of the predicate.

=head2 $pred->bool()

Sets/gets the boolean value in case the type is a boolean.

=head2 $pred->callback()

Sets/gets the callback in case the type is callback.

=head2 $pred->regexp()

Sets/gets the regular expression in case the type is "regexp".

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Widgets-NavMenu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Widgets-NavMenu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Widgets-NavMenu>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Widgets-NavMenu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu>

  git clone git://github.com/shlomif/perl-HTML-Widgets-NavMenu.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut

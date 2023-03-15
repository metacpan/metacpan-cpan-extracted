package LibUI::ProgressBar 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiProgressBarValue', 'value' ],
        [ InstanceOf ['LibUI::ProgressBar'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiProgressBarSetValue',           'setValue' ],
        [ InstanceOf ['LibUI::ProgressBar'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiNewProgressBar', 'new' ],
        [Void] => InstanceOf ['LibUI::ProgressBar']
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::ProgressBar - Control that Visualizes the Progress of a Task

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::ProgressBar;
    Init && die;
    my $window   = LibUI::Window->new( 'Hang on a tick...', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box      = LibUI::VBox->new();
    my $progress = LibUI::ProgressBar->new();
    $progress->setValue(-1);
    $box->append( $progress, 1 );
    $window->setChild($box);
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();

=head1 DESCRIPTION

A LibUI::ProgressBar object represents a control that visualizes the progress
of a task via the fill level of a horizontal bar.

Indeterminate values are supported via an animated bar.

=head1 Functions

Not a lot here but... well, it's just a progress bar.

=head2 C<new( )>

    my $progress = LibUI::ProgressBar->new( );

Creates a new progress bar.

=head2 C<setValue( ... )>

    $progress->setValue( 32 );

Sets the progress bar value.

Valid values are C<[0, 100]> for displaying a solid bar imitating a percent
value.

Use a value of C<-1> to render an animated bar to convey an indeterminate
value.

=head2 C<value( )>

    my $complete = $progress->value( );

Returns the progress bar value.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut


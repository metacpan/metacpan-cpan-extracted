package LibUI::HSeparator 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiNewHorizontalSeparator', 'new' ],
        [Void] => InstanceOf ['LibUI::HSeparator']
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::HSeparator - Visually Separates Controls Horizontally

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::HBox;
    use LibUI::Window;
    use LibUI::MultilineEntry;
    use LibUI::HSeparator;
    Init && die;
    my $window = LibUI::Window->new( 'Left and Right', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::HBox->new();
    my $left   = LibUI::MultilineEntry->new();
    my $right  = LibUI::MultilineEntry->new();
    $box->append( $left,                             1 );
    $box->append( LibUI::HSeparator->new(), 0 );
    $box->append( $right,                            1 );
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

A LibUI::HSeparator object represents a control to visually separate controls
horizontally.

=head1 Functions

Not a lot here but... well, it's just a line.

=head2 C<new( )>

    my $sep = LibUI::HSeparator->new( );

Creates a new horizontal separator.

=head1 See Also

L<LibUI::VerticalSeparator>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut


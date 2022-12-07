package LibUI::HorizontalSeparator 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(), 'uiNewHorizontalSeparator',
        [Void] => InstanceOf ['LibUI::HorizontalSeparator'],
        'new'
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::HorizontalSeparator - Visually Separates Controls Horizontally

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::HBox;
    use LibUI::Window;
    use LibUI::MultilineEntry;
    use LibUI::HorizontalSeparator;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Left and Right', 320, 100, 0 );
    my $box    = LibUI::HBox->new();
    my $left   = LibUI::MultilineEntry->new();
    my $right  = LibUI::MultilineEntry->new();
    $box->append( $left,                             1 );
    $box->append( LibUI::HorizontalSeparator->new(), 0 );
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

A LibUI::HorizontalSeparator object represents a control to visually separate
controls horizontally.

=head1 Functions

Not a lot here but... well, it's just a line.

=head2 C<new( )>

    my $sep = LibUI::HorizontalSeparator->new( );

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


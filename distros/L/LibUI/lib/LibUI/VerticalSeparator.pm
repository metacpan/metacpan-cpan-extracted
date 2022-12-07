package LibUI::VerticalSeparator 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(), 'uiNewVerticalSeparator', [Void] => InstanceOf ['LibUI::VerticalSeparator'],
        'new'
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::VerticalSeparator - Visually Separates Controls Vertically

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::MultilineEntry;
    use LibUI::VerticalSeparator;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Top and Bottom', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $top    = LibUI::MultilineEntry->new();
    my $bot    = LibUI::MultilineEntry->new();
    $box->append( $top,                            1 );
    $box->append( LibUI::VerticalSeparator->new(), 0 );
    $box->append( $bot,                            1 );
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

A LibUI::VerticalSeparator object represents a control to visually separate
controls vertically.

=head1 Functions

Not a lot here but... well, it's just a line.

=head2 C<new( )>

    my $sep = LibUI::VerticalSeparator->new( );

Creates a new vertical separator.

=head1 See Also

L<LibUI::HorizontalSeparator>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut


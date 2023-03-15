package LibUI::Area::Modifiers 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Area::Modifiers' => Enum [
        [ ModifierCtrl  => 1 ],         # Control key
        [ ModifierAlt   => 1 << 1 ],    # Alternate/Option key
        [ ModifierShift => 1 << 2 ],    # Shift key
        [ ModifierSuper => 1 << 3 ]     # Super/Command/Windows key
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Area::Modifiers - LibUI::Area Modifier Key Enumeration

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A L<LibUI::Area::Handler> passes this when the C<keyEvent> or C<mouseEvent>
callback is triggered.

These values may be used as bitmasks.

=head1 Key Codes

Here's the current list of values:

=over

=item C<ModifierCtrl> - Control key

=item C<ModifierAlt> - Alternate/Option key

=item C<ModifierShift> - Shift key

=item C<ModifierSuper> - Super/Command/Windows key

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords bitmasks

=cut


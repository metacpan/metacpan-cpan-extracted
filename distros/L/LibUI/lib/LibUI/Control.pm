package LibUI::Control 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use lib '../lib', '../blib/arch', '../blib/lib';
    use Affix;
    use LibUI;
    $|++;
    #
    {
        typedef 'LibUI::Control' => Struct [
            Signature     => ULong,
            OSSignature   => ULong,
            TypeSignature => ULong,
            Destroy       => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ],
            Handle        =>
                CodeRef [ [ InstanceOf ['LibUI::Control'] ] => InstanceOf ['LibUI::Control'] ],
            Parent =>
                CodeRef [ [ InstanceOf ['LibUI::Control'] ] => InstanceOf ['LibUI::Control'] ],
            SetParent => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ],
            Toplevel  => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Int ],
            Visible   => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Int ],
            Show      => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ],
            Hide      => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ],
            Enabled   => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Int ],
            Enable    => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ],
            Disable   => CodeRef [ [ InstanceOf ['LibUI::Control'] ] => Void ]
        ];
        #
        affix(
            LibUI::lib(),
            [ 'uiControlDestroy', 'Destroy' ],
            [ InstanceOf ['LibUI::Control'] ] => Void
        );
        affix( LibUI::lib(), 'uiControlHandle',
            [ InstanceOf ['LibUI::Control'] ] => Pointer [UInt] );
        affix( LibUI::lib(), 'uiControlParent',
            [ InstanceOf ['LibUI::Control'] ] => InstanceOf ['LibUI::Control'] );
        affix( LibUI::lib(), 'uiControlSetParent',
            [ InstanceOf ['LibUI::Control'], InstanceOf ['LibUI::Control'] ] => Void );
        affix( LibUI::lib(), 'uiControlToplevel', [ InstanceOf ['LibUI::Control'] ] => Int );
        affix( LibUI::lib(), 'uiControlVisible',  [ InstanceOf ['LibUI::Control'] ] => Int );
        affix(
            LibUI::lib(),
            [ 'uiControlShow', 'show' ],
            [ InstanceOf ['LibUI::Control'] ] => Void
        );
        affix( LibUI::lib(), 'uiControlHide',    [ InstanceOf ['LibUI::Control'] ] => Void );
        affix( LibUI::lib(), 'uiControlEnabled', [ InstanceOf ['LibUI::Control'] ] => Int );
        affix( LibUI::lib(), 'uiControlEnable',  [ InstanceOf ['LibUI::Control'] ] => Void );
        affix( LibUI::lib(), 'uiControlDisable', [ InstanceOf ['LibUI::Control'] ] => Void );
        affix( LibUI::lib(), 'uiAllocControl',
            [ Size_t, ULong, ULong, Str ] => InstanceOf ['LibUI::Control'] );
        affix( LibUI::lib(), 'uiFreeControl', [ InstanceOf ['LibUI::Control'] ] => Void );
        #
        affix( LibUI::lib(), 'uiControlVerifySetParent',
            [ InstanceOf ['LibUI::Control'], InstanceOf ['LibUI::Control'] ] => Void );
        affix( LibUI::lib(), 'uiControlEnabledToUser', [ InstanceOf ['LibUI::Control'] ] => Int );

# Upstream TODO: Move this to private API? According to old/new.md this should be used by toplevel controls.
        affix( LibUI::lib(), 'uiUserBugCannotSetParentOnToplevel', [Str] => Void );
    }
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Control - Base Class for GUI Controls

=head1 SYNOPSIS

    use LibUI;
    use LibUI::Window;

=head1 DESCRIPTION

A LibUI::Control object represents the superclass for all GUI objects.

=head1 Functions

All subclasses of LibUI::Control have access to these methods.


=head3 C<uiControlDestroy( ... )>

    uiControlDestroy( $c );

Dispose and free all allocated resources.

=head3 C<uiControlHandle( ... )>

    my $handle = uiControlHandle( $c );

Returns the control's OS-level handle.

=head3 C<uiControlParent( ... )>

    my $parent = uiControlParent( $c );

Returns the parent control or C<undef> if detached.

=head3 C<uiControlSetParent( ... )>

    uiControlSetParent( $c, $parent );

Sets the control's parent. Pass C<undef> to detach.

=head3 C<uiControlToplevel( ... )>

    if ( uiControlToplevel( $c ) ) {
        ...;
    }

Returns whether or not the control is a top level control.


=head3 C<uiControlVisible( ... )>

    if ( uiControlVisible( $c ) ) {
        ...;
    }

Returns whether or not the control is visible.

=head3 C<uiControlShow( ... )>

    uiControlShow( $c );

Shows the control.

=head3 C<uiControlHide( ... )>

    uiControlHide( $c );

Hides the control. Hidden controls do not take up space within the layout.

=head3 C<uiControlEnabled( ... )>

    if ( uiControlEnabled( $c ) ) {
        ...;
    }

Returns whether or not the control is enabled.

=head3 C<uiControlEnable( ... )>

    uiControlEnable( $c );

Enables the control.

=head3 C<uiControlDisable( ... )>

    uiControlDisable( $c );

Disables the control.

=head3 C<uiAllocControl( ... )>

    my $control = uiAllocControl( $size, $OSsig, $type, $typename );

Helper to allocate new controls.

=head3 C<uiFreeControl( ... )>

    uiFreeControl( $c );

Frees the control.

=head3 C<uiControlVerifySetParent( ... )>

    uiControlVerifySetParent( $c, $parent );

Makes sure the control's parent can be set to C<$parent> and crashes the
application on failure.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut


package LibUI v1.0.0 {
    use v5.40;
    use Affix;
    use Alien::libui;
    my $lib = Alien::libui->dynamic_libs;
    use Exporter qw[import];
    our %EXPORT_TAGS = (
        default => [qw[uiInit uiUninit uiFreeInitError uiMain uiMainSteps uiMainStep uiQuit uiQueueMain uiTimer uiOnShouldQuit]],
        control => [
            qw[
                uiControlDestroy  uiControlHandle          uiControlParent        uiControlSetParent
                uiControlToplevel uiControlVisible         uiControlShow          uiControlHide
                uiControlEnabled  uiControlEnable          uiControlDisable       uiAllocControl
                uiFreeControl     uiControlVerifySetParent uiControlEnabledToUser uiUserBugCannotSetParentOnToplevel]
        ],
        window => [
            qw[
                uiWindowTitle             uiWindowSetTitle             uiWindowPosition       uiWindowSetPosition
                uiWindowOnPositionChanged uiWindowContentSize          uiWindowSetContentSize uiWindowFullscreen
                uiWindowSetFullscreen     uiWindowOnContentSizeChanged uiWindowOnClosing      uiWindowOnFocusChanged
                uiWindowFocused           uiWindowBorderless           uiWindowSetBorderless  uiWindowSetChild
                uiWindowMargined          uiWindowSetMargined          uiWindowResizeable     uiWindowSetResizeable
                uiNewWindow
            ]
        ],
        button   => [qw[uiButtonText uiButtonSetText  uiButtonOnClicked uiNewButton ]],
        box      => [qw[uiBoxAppend  uiBoxNumChildren uiBoxDelete uiBoxPadded uiBoxSetPadded uiNewHorizontalBox uiNewVerticalBox ]],
        checkbox => [qw[uiCheckboxText uiCheckboxSetText uiCheckboxOnToggled uiCheckboxChecked uiCheckboxSetChecked uiNewCheckbox ]],
        entry    => [
            qw[
                uiEntryText        uiEntrySetText uiEntryOnChanged   uiEntryReadOnly
                uiEntrySetReadOnly uiNewEntry     uiNewPasswordEntry uiNewSearchEntry
            ]
        ],
        label   => [qw[ uiLabelText    uiLabelSetText    uiNewLabel ]],
        tab     => [qw[ uiTabAppend    uiTabInsertAt     uiTabDelete        uiTabNumPages uiTabMargined uiTabSetMargined uiNewTab ]],
        group   => [qw[ uiGroupTitle   uiGroupSetTitle   uiGroupSetChild    uiGroupMargined uiGroupSetMargined uiNewGroup ]],
        spinbox => [qw[ uiSpinboxValue uiSpinboxSetValue uiSpinboxOnChanged uiNewSpinbox ]],
        slider  => [
            qw[
                uiSliderValue     uiSliderSetValue   uiSliderHasToolTip uiSliderSetHasToolTip
                uiSliderOnChanged uiSliderOnReleased uiSliderSetRange   uiNewSlider
            ]
        ],
        progressbar => [qw[uiProgressBarValue uiProgressBarSetValue uiNewProgressBar ]],
        separator   => [qw[uiNewHorizontalSeparator uiNewVerticalSeparator ]],
        combobox    => [
            qw[
                uiComboboxAppend   uiComboboxInsertAt uiComboboxDelete      uiComboboxClear
                uiComboboxNumItems uiComboboxSelected uiComboboxSetSelected uiComboboxOnSelected
                uiNewCombobox
            ]
        ],
        editablecombobox => [
            qw[
                uiEditableComboboxAppend uiEditableComboboxText uiEditableComboboxSetText uiEditableComboboxOnChanged
                uiNewEditableCombobox
            ]
        ],
        menu => [
            qw[
                uiNewMenu                   uiMenuAppendItem      uiMenuAppendCheckItem uiMenuAppendQuitItem
                uiMenuAppendPreferencesItem uiMenuAppendAboutItem uiMenuAppendSeparator uiMenuItemEnable
                uiMenuItemDisable           uiMenuItemOnClicked   uiMenuItemChecked     uiMenuItemSetChecked
            ]
        ],
        multilineentry => [
            qw[
                uiNewMultilineEntry    uiNewNonWrappingMultilineEntry uiMultilineEntryText     uiMultilineEntrySetText
                uiMultilineEntryAppend uiMultilineEntryOnChanged      uiMultilineEntryReadOnly uiMultilineEntrySetReadOnly
            ]
        ],
        radiobuttons   => [qw[ uiNewRadioButtons uiRadioButtonsAppend uiRadioButtonsSelected uiRadioButtonsSetSelected uiRadioButtonsOnSelected ]],
        grid           => [qw[ uiNewGrid        uiGridAppend       uiGridInsertAt uiGridPadded uiGridSetPadded ]],
        colorbutton    => [qw[ uiNewColorButton uiColorButtonColor uiColorButtonSetColor uiColorButtonOnChanged ]],
        filedialog     => [qw[ uiOpenFile       uiOpenFolder       uiSaveFile ]],
        msgbox         => [qw[ uiMsgBox         uiMsgBoxError ]],
        fontbutton     => [qw[ uiNewFontButton  uiFontButtonFont uiFreeFontButtonFont uiLoadControlFont uiFontButtonOnChanged ]],
        datetimepicker => [
            qw[
                uiNewDatePicker      uiNewTimePicker uiNewDateTimePicker uiDateTimePickerOnChanged
                uiDateTimePickerTime uiDateTimePickerSetTime
            ]
        ],
        tab_extra  => [qw[uiTabSelected uiTabSetSelected     uiTabOnSelected ]],
        form       => [qw[ uiNewForm     uiFormAppend         uiFormNumChildren uiFormDelete uiFormPadded uiFormSetPadded ]],
        area_extra => [qw[ uiAreaSetSize uiAreaQueueRedrawAll uiAreaScrollTo    uiAreaBeginUserWindowMove uiAreaBeginUserWindowResize ]],
        drawpath   => [
            qw[
                uiDrawNewPath          uiDrawFreePath  uiDrawPathNewFigure uiDrawPathNewFigureWithArc
                uiDrawPathLineTo       uiDrawPathArcTo uiDrawPathBezierTo  uiDrawPathCloseFigure
                uiDrawPathAddRectangle uiDrawPathEnded uiDrawPathEnd
            ]
        ],
        drawstroke => [qw[ uiDrawStroke uiDrawFill ]],
        drawmatrix => [
            qw[
                uiDrawMatrixSetIdentity    uiDrawMatrixTranslate uiDrawMatrixScale      uiDrawMatrixRotate
                uiDrawMatrixSkew           uiDrawMatrixMultiply  uiDrawMatrixInvertible uiDrawMatrixInvert
                uiDrawMatrixTransformPoint uiDrawMatrixTransformSize
            ]
        ],
        drawcontext => [qw[ uiDrawTransform uiDrawClip uiDrawSave uiDrawRestore ]],
        image       => [qw[ uiNewImage uiFreeImage uiImageAppend ]],
        attr        => [
            qw[
                uiFreeAttribute      uiAttributeGetType           uiNewFamilyAttribute     uiAttributeFamily
                uiNewSizeAttribute   uiAttributeSize              uiNewWeightAttribute     uiAttributeWeight
                uiNewItalicAttribute uiAttributeItalic            uiNewStretchAttribute    uiAttributeStretch
                uiNewColorAttribute  uiAttributeColor             uiNewBackgroundAttribute uiNewUnderlineAttribute
                uiAttributeUnderline uiNewUnderlineColorAttribute uiAttributeUnderlineColor
            ]
        ],
        opentype => [
            qw[
                uiNewOpenTypeFeatures    uiFreeOpenTypeFeatures uiOpenTypeFeaturesClone   uiOpenTypeFeaturesAdd
                uiOpenTypeFeaturesRemove uiOpenTypeFeaturesGet  uiOpenTypeFeaturesForEach uiNewFeaturesAttribute
                uiAttributeFeatures
            ]
        ],
        attrstr => [
            qw[ uiNewAttributedString                 uiFreeAttributedString
                uiAttributedStringString              uiAttributedStringLen
                uiAttributedStringAppendUnattributed  uiAttributedStringInsertAtUnattributed
                uiAttributedStringDelete              uiAttributedStringSetAttribute
                uiAttributedStringForEachAttribute    uiAttributedStringNumGraphemes
                uiAttributedStringByteIndexToGrapheme uiAttributedStringGraphemeToByteIndex
            ]
        ],
        textlayout => [qw[uiDrawNewTextLayout uiDrawFreeTextLayout uiDrawText uiDrawTextLayoutExtents]],
        table      => [
            qw[ uiFreeTableValue               uiTableValueGetType
                uiNewTableValueString          uiTableValueString
                uiNewTableValueImage           uiTableValueImage
                uiNewTableValueInt             uiTableValueInt
                uiNewTableValueColor           uiTableValueColor
                uiNewTableModel                uiFreeTableModel
                uiTableModelRowInserted        uiTableModelRowChanged
                uiTableModelRowDeleted         uiTableAppendTextColumn
                uiTableAppendImageColumn       uiTableAppendImageTextColumn
                uiTableAppendCheckboxColumn    uiTableAppendCheckboxTextColumn
                uiTableAppendProgressBarColumn uiTableAppendButtonColumn
                uiTableHeaderVisible           uiTableHeaderSetVisible
                uiNewTable                     uiTableOnRowClicked
                uiTableOnRowDoubleClicked      uiTableHeaderSetSortIndicator
                uiTableHeaderSortIndicator     uiTableHeaderOnClicked
                uiTableColumnWidth             uiTableColumnSetWidth
                uiTableGetSelectionMode        uiTableSetSelectionMode
                uiTableOnSelectionChanged      uiTableGetSelection
                uiTableSetSelection            uiFreeTableSelection]
        ],
        misc      => [qw[uiFreeText uiNewArea uiNewScrollingArea]],
        constants => [
            qw[ UI_FILL_WINDING   UI_FILL_ALTERNATE
                UI_BRUSH_SOLID       UI_BRUSH_LINEAR_GRADIENT UI_BRUSH_RADIAL_GRADIENT
                UI_LINE_CAP_FLAT     UI_LINE_CAP_ROUND   UI_LINE_JOIN_MITER
                UI_LINE_JOIN_ROUND   UI_LINE_JOIN_BEVEL  UI_TEXT_ALIGN_LEFT
                UI_TEXT_ALIGN_CENTER UI_TEXT_ALIGN_RIGHT
                UI_WEIGHT_THIN       UI_WEIGHT_EXTRA_LIGHT UI_WEIGHT_LIGHT
                UI_WEIGHT_BOOK
                UI_WEIGHT_NORMAL
                UI_WEIGHT_MEDIUM
                UI_WEIGHT_SEMI_BOLD UI_WEIGHT_BOLD    UI_WEIGHT_EXTRA_BOLD UI_WEIGHT_HEAVY
                UI_ITALIC_NORMAL    UI_ITALIC_OBLIQUE UI_ITALIC_ITALIC
                UI_STRETCH_ULTRA_CONDENSED UI_STRETCH_EXTRA_CONDENSED UI_STRETCH_CONDENSED
                UI_STRETCH_SEMI_CONDENSED  UI_STRETCH_NORMAL          UI_STRETCH_SEMI_EXPANDED
                UI_STRETCH_EXPANDED        UI_STRETCH_EXTRA_EXPANDED  UI_STRETCH_ULTRA_EXPANDED
                UI_UNDERLINE_NONE      UI_UNDERLINE_SINGLE   UI_UNDERLINE_DOUBLE UI_UNDERLINE_SQUIGGLE
                UI_TABLE_COLUMN_STRING UI_TABLE_COLUMN_IMAGE UI_TABLE_COLUMN_INT UI_TABLE_COLUMN_COLOR
                UI_SELECTION_NONE      UI_SELECTION_SINGLE   UI_SELECTION_MULTIPLE
                UI_SORT_NONE           UI_SORT_ASCENDING     UI_SORT_DESCENDING
                UI_ALIGN_FILL          UI_ALIGN_START        UI_ALIGN_CENTER       UI_ALIGN_END
            ]
        ],
        helpers => [qw[solid_brush draw_stroke format_tm]]
    );
    {
        my %seen;
        push @{ $EXPORT_TAGS{control} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} }
            for qw[area_extra attr attrstr box button checkbox colorbutton combobox constants datetimepicker
            drawcontext drawmatrix drawpath drawstroke editablecombobox entry filedialog fontbutton form
            grid group helpers image label menu misc msgbox multilineentry opentype progressbar radiobuttons
            separator slider spinbox tab tab_extra table textlayout window];
    }
    {
        my %seen;
        push @{ $EXPORT_TAGS{all} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} } for keys %EXPORT_TAGS;
    }
    our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

    #~ use Data::Dump;
    #~ ddx \@EXPORT_OK;
    #~ ddx \%EXPORT_TAGS;
    typedef 'LibUI::InitOptions' => Struct [ Size => Size_t ];
    affix $lib, 'uiInit',          [ Pointer [ Struct [ Size => Size_t ] ] ]                   => String;
    affix $lib, 'uiUninit',        []                                                          => Void;
    affix $lib, 'uiFreeInitError', [Char]                                                      => Void;
    affix $lib, 'uiMain',          []                                                          => Void;
    affix $lib, 'uiMainSteps',     []                                                          => Void;
    affix $lib, 'uiMainStep',      [Int]                                                       => Int;
    affix $lib, 'uiQuit',          []                                                          => Void;
    affix $lib, 'uiQueueMain',     [ Callback [ [ Pointer [SV] ] => Void ], Pointer [SV] ]     => Void;
    affix $lib, 'uiTimer',         [ Int, Callback [ [ Pointer [SV] ] => Int ], Pointer [SV] ] => Void;
    affix $lib, 'uiOnShouldQuit',  [ Callback [ [ Pointer [SV] ] => Int ], Pointer [SV] ]      => Void;
    affix $lib, 'uiFreeText',      [String]                                                    => Void;

    # Base class for GUI controls providing common methods.
    typedef 'LibUI::Control' => Pointer [
        Void

            #~ Struct [
            #~ signature      => UInt,
            #~ os_signature   => UInt,
            #~ type_signature => UInt,
            #~ destroy        => Pointer [Void],
            #~ handle         => Pointer [Void],
            #~ parent         => Pointer [Void],
            #~ set_parent     => Pointer [Void],
            #~ top_level      => Int,
            #~ visible        => Int,
            #~ show           => Pointer [Void],
            #~ hide           => Pointer [Void],
            #~ enabled        => Int,
            #~ enable         => Pointer [Void],
            #~ disable        => Pointer [Void]
            #~ ]
    ];
    affix $lib, 'uiControlDestroy',                   [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiControlHandle',                    [ Pointer [Void] ]                 => Pointer [Void];
    affix $lib, 'uiControlParent',                    [ Pointer [Void] ]                 => Pointer [Void];
    affix $lib, 'uiControlSetParent',                 [ Pointer [Void], Pointer [Void] ] => Void;
    affix $lib, 'uiControlToplevel',                  [ Pointer [Void] ]                 => Bool;
    affix $lib, 'uiControlVisible',                   [ Pointer [Void] ]                 => Bool;
    affix $lib, 'uiControlShow',                      [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiControlHide',                      [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiControlEnabled',                   [ Pointer [Void] ]                 => Bool;
    affix $lib, 'uiControlEnable',                    [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiControlDisable',                   [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiAllocControl',                     [ Size_t, UInt, UInt, String ]     => Pointer [Void];
    affix $lib, 'uiFreeControl',                      [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiControlVerifySetParent',           [ Pointer [Void], Pointer [Void] ] => Void;
    affix $lib, 'uiControlEnabledToUser',             [ Pointer [Void] ]                 => Bool;
    affix $lib, 'uiUserBugCannotSetParentOnToplevel', [String]                           => Void;
    typedef 'LibUI::Window' => Pointer [ Struct [ c => Pointer [Void], w => Pointer [Void], child => Pointer [Void], onClosing => Pointer [Void] ] ];
    affix $lib, 'uiWindowTitle',    [ Pointer [Void] ]         => String;
    affix $lib, 'uiWindowSetTitle', [ Pointer [Void], String ] => Void;

    sub uiWindowPosition ($window) {
        state $o //= wrap $lib, 'uiWindowPosition', [ Pointer [Void], Pointer [Int], Pointer [Int] ] => Void;
        my ( $x, $y ) = ( 0, 0 );
        $o->( $window, \$x, \$y );
        return ( $x, $y );
    }
    affix $lib, 'uiWindowSetPosition', [ Pointer [Void], Int, Int ] => Void;
    affix $lib, 'uiWindowOnPositionChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    sub uiWindowContentSize($window) {
        state $o //= wrap $lib, 'uiWindowContentSize', [ Pointer [Void], Pointer [Int], Pointer [Int] ] => Void;
        my ( $w, $h ) = ( 0, 0 );
        $o->( $window, \$w, \$h );
        return ( $w, $h );
    }
    affix $lib, 'uiWindowSetContentSize',       [ Pointer [Void], Int, Int ]                                                            => Void;
    affix $lib, 'uiWindowFullscreen',           [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiWindowSetFullscreen',        [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiWindowOnContentSizeChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiWindowOnClosing',            [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Bool ], Pointer [SV] ] => Void;
    affix $lib, 'uiWindowOnFocusChanged',       [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiWindowFocused',              [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiWindowBorderless',           [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiWindowSetBorderless',        [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiWindowSetChild',             [ Pointer [Void], Pointer [Void] ]                                                      => Void;
    affix $lib, 'uiWindowMargined',             [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiWindowSetMargined',          [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiWindowResizeable',           [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiWindowSetResizeable',        [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiNewWindow',                  [ String, Int, Int, Int ] => Pointer [Void];
    typedef 'LibUI::Button' => Pointer [Void];
    affix $lib, 'uiButtonText',      [ Pointer [Void] ]                                                                      => String;
    affix $lib, 'uiButtonSetText',   [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiButtonOnClicked', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiNewButton',       [String]                                                                                => Pointer [Void];
    typedef 'LibUI::Box' => Pointer [Void];
    affix $lib, 'uiBoxAppend',        [ Pointer [Void], Pointer [Void], Bool ] => Void;
    affix $lib, 'uiBoxNumChildren',   [ Pointer [Void] ]                       => Int;
    affix $lib, 'uiBoxDelete',        [ Pointer [Void], Int ]                  => Void;
    affix $lib, 'uiBoxPadded',        [ Pointer [Void] ]                       => Bool;
    affix $lib, 'uiBoxSetPadded',     [ Pointer [Void], Int ]                  => Void;
    affix $lib, 'uiNewHorizontalBox', []                                       => Pointer [Void];
    affix $lib, 'uiNewVerticalBox',   []                                       => Pointer [Void];
    typedef 'LibUI::Checkbox' => Pointer [Void];
    affix $lib, 'uiCheckboxText',       [ Pointer [Void] ]                                                                      => String;
    affix $lib, 'uiCheckboxSetText',    [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiCheckboxOnToggled',  [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiCheckboxChecked',    [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiCheckboxSetChecked', [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiNewCheckbox',        [String]                                                                                => Pointer [Void];
    typedef 'LibUI::Entry'         => Pointer [Void];
    typedef 'LibUI::PasswordEntry' => Pointer [Void];
    typedef 'LibUI::SearchEntry'   => Pointer [Void];
    affix $lib, 'uiEntryText',        [ Pointer [Void] ]                                                                      => String;
    affix $lib, 'uiEntrySetText',     [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiEntryOnChanged',   [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiEntryReadOnly',    [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiEntrySetReadOnly', [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiNewEntry',         []                                                                                      => Pointer [Void];
    affix $lib, 'uiNewPasswordEntry', []                                                                                      => Pointer [Void];
    affix $lib, 'uiNewSearchEntry',   []                                                                                      => Pointer [Void];
    typedef 'LibUI::Label' => Pointer [Void];
    affix $lib, 'uiLabelText',    [ Pointer [Void] ]         => String;
    affix $lib, 'uiLabelSetText', [ Pointer [Void], String ] => Void;
    affix $lib, 'uiNewLabel',     [String]                   => Pointer [Void];
    typedef 'LibUI::Tab' => Pointer [Void];
    affix $lib, 'uiTabAppend',      [ Pointer [Void], String, Pointer [Void] ]      => Void;
    affix $lib, 'uiTabInsertAt',    [ Pointer [Void], String, Int, Pointer [Void] ] => Void;
    affix $lib, 'uiTabDelete',      [ Pointer [Void], Int ]                         => Void;
    affix $lib, 'uiTabNumPages',    [ Pointer [Void] ]                              => Int;
    affix $lib, 'uiTabMargined',    [ Pointer [Void], Int ]                         => Int;
    affix $lib, 'uiTabSetMargined', [ Pointer [Void], Int, Int ]                    => Void;
    affix $lib, 'uiNewTab',         []                                              => Pointer [Void];
    typedef 'LibUI::Group' => Pointer [Void];
    affix $lib, 'uiGroupTitle',       [ Pointer [Void] ]                 => String;
    affix $lib, 'uiGroupSetTitle',    [ Pointer [Void], String ]         => Void;
    affix $lib, 'uiGroupSetChild',    [ Pointer [Void], Pointer [Void] ] => Void;
    affix $lib, 'uiGroupMargined',    [ Pointer [Void] ]                 => Bool;
    affix $lib, 'uiGroupSetMargined', [ Pointer [Void], Bool ]           => Void;
    affix $lib, 'uiNewGroup',         [String]                           => Pointer [Void];
    typedef 'LibUI::Spinbox' => Pointer [Void];
    affix $lib, 'uiSpinboxValue',     [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiSpinboxSetValue',  [ Pointer [Void], Int ]                                                                 => Void;
    affix $lib, 'uiSpinboxOnChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiNewSpinbox',       [ Int, Int ]                                                                            => Pointer [Void];
    typedef 'LibUI::Slider' => Pointer [Void];
    affix $lib, 'uiSliderValue',         [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiSliderSetValue',      [ Pointer [Void], Int ]                                                                 => Void;
    affix $lib, 'uiSliderHasToolTip',    [ Pointer [Void] ]                                                                      => Bool;
    affix $lib, 'uiSliderSetHasToolTip', [ Pointer [Void], Bool ]                                                                => Void;
    affix $lib, 'uiSliderOnChanged',     [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiSliderOnReleased',    [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiSliderSetRange',      [ Pointer [Void], Int, Int ]                                                            => Void;
    affix $lib, 'uiNewSlider',           [ Int, Int ]                                                                            => Pointer [Void];
    typedef 'LibUI::ProgressBar' => Pointer [Void];
    affix $lib, 'uiProgressBarValue',    [ Pointer [Void] ]      => Int;
    affix $lib, 'uiProgressBarSetValue', [ Pointer [Void], Int ] => Void;
    affix $lib, 'uiNewProgressBar',      []                      => Pointer [Void];
    typedef 'LibUI::HSeparator' => Pointer [Void];
    typedef 'LibUI::VSeparator' => Pointer [Void];
    affix $lib, 'uiNewHorizontalSeparator', [] => Pointer [Void];
    affix $lib, 'uiNewVerticalSeparator',   [] => Pointer [Void];
    typedef 'LibUI::Combobox' => Pointer [Void];
    affix $lib, 'uiComboboxAppend',      [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiComboboxInsertAt',    [ Pointer [Void], Int, String ]                                                         => Void;
    affix $lib, 'uiComboboxDelete',      [ Pointer [Void], Int ]                                                                 => Void;
    affix $lib, 'uiComboboxClear',       [ Pointer [Void] ]                                                                      => Void;
    affix $lib, 'uiComboboxNumItems',    [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiComboboxSelected',    [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiComboboxSetSelected', [ Pointer [Void], Int ]                                                                 => Void;
    affix $lib, 'uiComboboxOnSelected',  [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiNewCombobox',         []                                                                                      => Pointer [Void];
    typedef 'LibUI::EditableCombobox' => Pointer [Void];
    affix $lib, 'uiEditableComboboxAppend',    [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiEditableComboboxText',      [ Pointer [Void] ]                                                                      => String;
    affix $lib, 'uiEditableComboboxSetText',   [ Pointer [Void], String ]                                                              => Void;
    affix $lib, 'uiEditableComboboxOnChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiNewEditableCombobox',       [] => Pointer [Void];
    #
    typedef 'LibUI::Menu'           => Pointer [Void];
    typedef 'LibUI::MenuItem'       => Pointer [Void];
    typedef 'LibUI::Separator'      => Pointer [Void];
    typedef 'LibUI::DatePicker'     => Pointer [Void];
    typedef 'LibUI::TimePicker'     => Pointer [Void];
    typedef 'LibUI::DateTimePicker' => Pointer [Void];
    typedef 'LibUI::FontButton'     => Pointer [Void];
    typedef 'LibUI::ColorButton'    => Pointer [Void];
    typedef 'LibUI::RadioButtons'   => Pointer [Void];
    typedef 'LibUI::Area'           => Pointer [Void];
    typedef 'LibUI::DrawPath'       => Pointer [Void];
    typedef 'LibUI::TextFont'       => Pointer [Void];
    typedef 'LibUI::TextLayout'     => Pointer [Void];
    #
    typedef AreaDrawParams => Struct [
        Context    => Pointer [Void],
        AreaWidth  => Double,
        AreaHeight => Double,
        ClipX      => Double,
        ClipY      => Double,
        ClipWidth  => Double,
        ClipHeight => Double
    ];
    #
    typedef AreaHandler => Struct [
        Draw         => Callback [ [ Pointer [Void], Pointer [Void], Pointer [Void] ] => Void ],
        MouseEvent   => Callback [ [ Pointer [Void], Pointer [Void], Pointer [Void] ] => Void ],
        MouseCrossed => Callback [ [ Pointer [Void], Pointer [Void], Int ]            => Void ],
        DragBroken   => Callback [ [ Pointer [Void], Pointer [Void] ]                 => Void ],
        KeyEvent     => Callback [ [ Pointer [Void], Pointer [Void], Pointer [Void] ] => Int ]
    ];
    typedef AreaMouseEvent => Struct [
        X          => Double,
        Y          => Double,
        AreaWidth  => Double,
        AreaHeight => Double,
        Down       => Int,
        Up         => Int,
        Count      => Int,
        Modifiers  => UInt,
        Held1To64  => Int64
    ];
    typedef AreaKeyEvent => Struct [ Key => Char, ExtKey => Int, Modifier => UInt, Modifiers => UInt, Up => Int ];

    # Menu
    affix $lib, 'uiNewMenu',                   [String]                   => Pointer [Void];
    affix $lib, 'uiMenuAppendItem',            [ Pointer [Void], String ] => Pointer [Void];
    affix $lib, 'uiMenuAppendCheckItem',       [ Pointer [Void], String ] => Pointer [Void];
    affix $lib, 'uiMenuAppendQuitItem',        [ Pointer [Void] ]         => Pointer [Void];
    affix $lib, 'uiMenuAppendPreferencesItem', [ Pointer [Void] ]         => Pointer [Void];
    affix $lib, 'uiMenuAppendAboutItem',       [ Pointer [Void] ]         => Pointer [Void];
    affix $lib, 'uiMenuAppendSeparator',       [ Pointer [Void] ]         => Void;

    # MenuItem
    affix $lib, 'uiMenuItemEnable',  [ Pointer [Void] ] => Void;
    affix $lib, 'uiMenuItemDisable', [ Pointer [Void] ] => Void;
    affix $lib, 'uiMenuItemOnClicked',
        [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiMenuItemChecked',    [ Pointer [Void] ]      => Int;
    affix $lib, 'uiMenuItemSetChecked', [ Pointer [Void], Int ] => Void;

    # DateTimePicker (complete)
    affix $lib, 'uiNewDatePicker',           [] => Pointer [Void];
    affix $lib, 'uiNewTimePicker',           [] => Pointer [Void];
    affix $lib, 'uiNewDateTimePicker',       [] => Pointer [Void];
    affix $lib, 'uiDateTimePickerOnChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    # FontButton
    affix $lib, 'uiNewFontButton', [] => Pointer [Void];

    # ColorButton
    affix $lib, 'uiNewColorButton', [] => Pointer [Void];

    sub uiColorButtonColor ($btn) {
        state $o //= wrap $lib, 'uiColorButtonColor',
            [ Pointer [Void], Pointer [Double], Pointer [Double], Pointer [Double], Pointer [Double] ] => Void;
        my ( $r, $g, $b, $a ) = ( 0, 0, 0, 0 );
        $o->( $btn, \$r, \$g, \$b, \$a );
        return ( $r, $g, $b, $a );
    }
    affix $lib, 'uiColorButtonSetColor', [ Pointer [Void], Double, Double, Double, Double ] => Void;
    affix $lib, 'uiColorButtonOnChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    # MultilineEntry
    typedef 'LibUI::MultilineEntry' => Pointer [Void];
    affix $lib, 'uiNewMultilineEntry',            []                         => Pointer [Void];
    affix $lib, 'uiNewNonWrappingMultilineEntry', []                         => Pointer [Void];
    affix $lib, 'uiMultilineEntryText',           [ Pointer [Void] ]         => String;
    affix $lib, 'uiMultilineEntrySetText',        [ Pointer [Void], String ] => Void;
    affix $lib, 'uiMultilineEntryAppend',         [ Pointer [Void], String ] => Void;
    affix $lib, 'uiMultilineEntryOnChanged',      [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;
    affix $lib, 'uiMultilineEntryReadOnly',       [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiMultilineEntrySetReadOnly',    [ Pointer [Void], Int ]                                                                 => Void;

    # RadioButtons
    affix $lib, 'uiNewRadioButtons',         []                         => Pointer [Void];
    affix $lib, 'uiRadioButtonsAppend',      [ Pointer [Void], String ] => Void;
    affix $lib, 'uiRadioButtonsSelected',    [ Pointer [Void] ]         => Int;
    affix $lib, 'uiRadioButtonsSetSelected', [ Pointer [Void], Int ]    => Void;
    affix $lib, 'uiRadioButtonsOnSelected',  [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    # Tab enhancements
    affix $lib, 'uiTabSelected',    [ Pointer [Void] ]                                                                      => Int;
    affix $lib, 'uiTabSetSelected', [ Pointer [Void], Int ]                                                                 => Void;
    affix $lib, 'uiTabOnSelected',  [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    # Grid
    affix $lib, 'uiNewGrid',       []                                                                                         => Pointer [Void];
    affix $lib, 'uiGridAppend',    [ Pointer [Void], Pointer [Void], Int, Int, Int, Int, Int, Int, Int, Int ]                 => Void;
    affix $lib, 'uiGridInsertAt',  [ Pointer [Void], Pointer [Void], Pointer [Void], Int, Int, Int, Int, Int, Int, Int, Int ] => Void;
    affix $lib, 'uiGridPadded',    [ Pointer [Void] ]                                                                         => Int;
    affix $lib, 'uiGridSetPadded', [ Pointer [Void], Int ]                                                                    => Void;

    # File Chooser Dialogs
    affix $lib, 'uiOpenFile',   [ Pointer [Void] ] => String;
    affix $lib, 'uiOpenFolder', [ Pointer [Void] ] => String;
    affix $lib, 'uiSaveFile',   [ Pointer [Void] ] => String;

    # MsgBox
    affix $lib, 'uiMsgBox',      [ Pointer [Void], String, String ] => Void;
    affix $lib, 'uiMsgBoxError', [ Pointer [Void], String, String ] => Void;

    # Area
    sub _wrap_area_handler($handler) {
        {   Draw => (
                defined $handler->{Draw} ?
                    sub ( $a_h, $a, $e ) {
                    $handler->{Draw}->( $a_h, $a, ${ Affix::cast( $e, Pointer [ AreaDrawParams() ] ) } );
                    } :
                    sub { }
            ),
            MouseEvent => (
                defined $handler->{MouseEvent} ?
                    sub ( $a_h, $a, $e ) {
                    $handler->{MouseEvent}->( $a_h, $a, ${ Affix::cast( $e, Pointer [ AreaMouseEvent() ] ) } );
                    } :
                    sub { }
            ),
            MouseCrossed => (
                defined $handler->{MouseCrossed} ?
                    sub ( $a_h, $a, $left ) {
                    $handler->{MouseCrossed}->( $a_h, $a, $left );
                    } :
                    sub { }
            ),
            DragBroken => (
                defined $handler->{DragBroken} ?
                    sub ( $a_h, $a ) {
                    $handler->{DragBroken}->( $a_h, $a );
                    } :
                    sub { }
            ),
            KeyEvent => (
                defined $handler->{KeyEvent} ?
                    sub ( $a_h, $a, $e ) {
                    return $handler->{KeyEvent}->( $a_h, $a, ${ Affix::cast( $e, Pointer [ AreaKeyEvent() ] ) } );
                    } :
                    sub { }
            )
        }
    }

    sub uiNewArea {
        state $raw //= Affix::wrap( Alien::libui->dynamic_libs, 'uiNewArea', [ Pointer [ AreaHandler() ] ], Pointer [Void] );
        $raw->( _wrap_area_handler( $_[0] ) );
    }

    sub uiNewScrollingArea {
        state $raw //= Affix::wrap( Alien::libui->dynamic_libs, 'uiNewScrollingArea', [ Pointer [ AreaHandler() ], Int, Int ], Pointer [Void] );
        $raw->( _wrap_area_handler( $_[0] ), $_[1], $_[2] );
    }

    # Form
    affix $lib, 'uiNewForm',         []                                              => Pointer [Void];
    affix $lib, 'uiFormAppend',      [ Pointer [Void], String, Pointer [Void], Int ] => Void;
    affix $lib, 'uiFormNumChildren', [ Pointer [Void] ]                              => Int;
    affix $lib, 'uiFormDelete',      [ Pointer [Void], Int ]                         => Void;
    affix $lib, 'uiFormPadded',      [ Pointer [Void] ]                              => Int;
    affix $lib, 'uiFormSetPadded',   [ Pointer [Void], Int ]                         => Void;

    # Area operations
    affix $lib, 'uiAreaSetSize',               [ Pointer [Void], Int, Int ]                       => Void;
    affix $lib, 'uiAreaQueueRedrawAll',        [ Pointer [Void] ]                                 => Void;
    affix $lib, 'uiAreaScrollTo',              [ Pointer [Void], Double, Double, Double, Double ] => Void;
    affix $lib, 'uiAreaBeginUserWindowMove',   [ Pointer [Void] ]                                 => Void;
    affix $lib, 'uiAreaBeginUserWindowResize', [ Pointer [Void], Int ]                            => Void;

    # DateTimePicker get/set time
    typedef 'LibUI::TM' => Struct [
        tm_sec   => Int,
        tm_min   => Int,
        tm_hour  => Int,
        tm_mday  => Int,
        tm_mon   => Int,
        tm_year  => Int,
        tm_wday  => Int,
        tm_yday  => Int,
        tm_isdst => Int
    ];

    sub uiDateTimePickerTime($picker) {
        state $o //= wrap $lib, 'uiDateTimePickerTime', [ Pointer [Void], Pointer [Void] ] => Void;
        my $buf = "\0" x 36;
        $o->( $picker, $buf );
        my @t = unpack( 'i9', $buf );
        {   tm_sec   => $t[0],
            tm_min   => $t[1],
            tm_hour  => $t[2],
            tm_mday  => $t[3],
            tm_mon   => $t[4],
            tm_year  => $t[5],
            tm_wday  => $t[6],
            tm_yday  => $t[7],
            tm_isdst => $t[8]
        };
    }

    sub uiDateTimePickerSetTime( $picker, @args ) {
        state $o //= wrap $lib, 'uiDateTimePickerSetTime', [ Pointer [Void], Pointer [Void] ] => Void;
        my %tm;
        if ( @args == 1 && ref $args[0] eq 'HASH' ) {
            %tm = %{ $args[0] };
        }
        elsif ( @args == 1 && !ref $args[0] ) {
            my @lt = localtime( $args[0] );
            %tm = (
                tm_sec   => $lt[0],
                tm_min   => $lt[1],
                tm_hour  => $lt[2],
                tm_mday  => $lt[3],
                tm_mon   => $lt[4],
                tm_year  => $lt[5],
                tm_wday  => $lt[6],
                tm_yday  => $lt[7],
                tm_isdst => -1
            );
        }
        elsif ( @args >= 6 ) {
            %tm = (
                tm_sec   => $args[0],
                tm_min   => $args[1],
                tm_hour  => $args[2],
                tm_mday  => $args[3],
                tm_mon   => $args[4],
                tm_year  => $args[5],
                tm_wday  => $args[6] // 0,
                tm_yday  => $args[7] // 0,
                tm_isdst => $args[8] // -1
            );
        }
        else {
            die "uiDateTimePickerSetTime: expected hashref, epoch, or (sec,min,hour,mday,mon,year,...)";
        }
        $o->(
            $picker,
            pack 'i9',
            $tm{tm_sec}   // 0,
            $tm{tm_min}   // 0,
            $tm{tm_hour}  // 0,
            $tm{tm_mday}  // 1,
            $tm{tm_mon}   // 0,
            $tm{tm_year}  // 0,
            $tm{tm_wday}  // 0,
            $tm{tm_yday}  // 0,
            $tm{tm_isdst} // -1
        );
    }

    # FontDescriptor struct
    typedef FontDescriptor => Struct [ Family => Pointer [Char], Size => Double, Weight => UInt, Italic => UInt, Stretch => UInt ];

    # FontButton
    sub uiFontButtonFont ($btn) {
        state $o //= wrap $lib, 'uiFontButtonFont', [ Pointer [Void], Pointer [ FontDescriptor() ] ] => Void;
        my $desc = Affix::calloc( 1, Affix::sizeof( LibUI::FontDescriptor() ) );
        $o->( $btn, $desc );
        my $d      = Affix::cast( $desc, LibUI::FontDescriptor() );
        my %result = ( Family => $d->{Family} // '', Size => $d->{Size}, Weight => $d->{Weight}, Italic => $d->{Italic}, Stretch => $d->{Stretch} );
        uiFreeFontButtonFont($desc);
        return \%result;
    }

    sub uiLoadControlFont () {
        state $o //= wrap $lib, 'uiLoadControlFont', [ Pointer [ FontDescriptor() ] ] => Void;
        my $desc = Affix::calloc( 1, Affix::sizeof( LibUI::FontDescriptor() ) );
        $o->($desc);
        my $d      = Affix::cast( $desc, LibUI::FontDescriptor() );
        my %result = ( Family => $d->{Family} // '', Size => $d->{Size}, Weight => $d->{Weight}, Italic => $d->{Italic}, Stretch => $d->{Stretch} );
        Affix::free($desc);
        return \%result;
    }
    affix $lib, 'uiFreeFontButtonFont',  [ Pointer [ FontDescriptor() ] ]                                                        => Void;
    affix $lib, 'uiFreeFontDescriptor',  [ Pointer [Void] ]                                                                      => Void;
    affix $lib, 'uiFontButtonOnChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [SV] ] => Void ], Pointer [SV] ] => Void;

    # DrawPath
    affix $lib, 'uiDrawNewPath',              [Int]                                                              => Pointer [Void];
    affix $lib, 'uiDrawFreePath',             [ Pointer [Void] ]                                                 => Void;
    affix $lib, 'uiDrawPathNewFigure',        [ Pointer [Void], Double, Double ]                                 => Void;
    affix $lib, 'uiDrawPathNewFigureWithArc', [ Pointer [Void], Double, Double, Double, Double, Double, Int ]    => Void;
    affix $lib, 'uiDrawPathLineTo',           [ Pointer [Void], Double, Double ]                                 => Void;
    affix $lib, 'uiDrawPathArcTo',            [ Pointer [Void], Double, Double, Double, Double, Double, Int ]    => Void;
    affix $lib, 'uiDrawPathBezierTo',         [ Pointer [Void], Double, Double, Double, Double, Double, Double ] => Void;
    affix $lib, 'uiDrawPathCloseFigure',      [ Pointer [Void] ]                                                 => Void;
    affix $lib, 'uiDrawPathAddRectangle',     [ Pointer [Void], Double, Double, Double, Double ]                 => Void;
    affix $lib, 'uiDrawPathEnded',            [ Pointer [Void] ]                                                 => Int;
    affix $lib, 'uiDrawPathEnd',              [ Pointer [Void] ]                                                 => Void;

    # DrawStroke / DrawFill
    typedef DrawBrush => Struct [
        Type        => UInt,
        R           => Double,
        G           => Double,
        B           => Double,
        A           => Double,
        X0          => Double,
        Y0          => Double,
        X1          => Double,
        Y1          => Double,
        OuterRadius => Double,
        Stops       => Pointer [Void],
        NumStops    => Size_t
    ];
    typedef DrawStrokeParams => Struct [
        Cap        => UInt,
        Join       => UInt,
        Thickness  => Double,
        MiterLimit => Double,
        Dashes     => Pointer [Double],
        NumDashes  => Size_t,
        DashPhase  => Double
    ];
    typedef 'LibUI::DrawBrushGradientStop' => Struct [ Pos => Double, R => Double, G => Double, B => Double, A => Double ];
    affix $lib, 'uiDrawStroke', [ Pointer [Void], Pointer [Void], Pointer [ DrawBrush() ], Pointer [ DrawStrokeParams() ] ] => Void;
    affix $lib, 'uiDrawFill', [ Pointer [Void], Pointer [Void], Pointer [ DrawBrush() ] ] => Void;

    # Transform Matrices
    # uiDrawMatrix: 6 doubles (M11,M12,M21,M22,M31,M32) = 48 bytes
    typedef DrawMatrix => Struct [ M11 => Double, M12 => Double, M21 => Double, M22 => Double, M31 => Double, M32 => Double ];
    affix $lib, 'uiDrawMatrixSetIdentity', [ Pointer [ DrawMatrix() ] ]                                 => Void;
    affix $lib, 'uiDrawMatrixTranslate',   [ Pointer [ DrawMatrix() ], Double, Double ]                 => Void;
    affix $lib, 'uiDrawMatrixScale',       [ Pointer [ DrawMatrix() ], Double, Double, Double, Double ] => Void;
    affix $lib, 'uiDrawMatrixRotate',      [ Pointer [ DrawMatrix() ], Double, Double, Double ]         => Void;
    affix $lib, 'uiDrawMatrixSkew',        [ Pointer [ DrawMatrix() ], Double, Double, Double, Double ] => Void;
    affix $lib, 'uiDrawMatrixMultiply',    [ Pointer [ DrawMatrix() ], Pointer [ DrawMatrix() ] ]       => Void;
    affix $lib, 'uiDrawMatrixInvertible',  [ Pointer [ DrawMatrix() ] ]                                 => Int;
    affix $lib, 'uiDrawMatrixInvert',      [ Pointer [ DrawMatrix() ] ]                                 => Int;

    sub uiDrawMatrixTransformPoint( $matrix, $x, $y ) {
        state $o //= wrap $lib, 'uiDrawMatrixTransformPoint', [ Pointer [ DrawMatrix() ], Pointer [Double], Pointer [Double] ] => Void;
        my ( $rx, $ry ) = ( $x, $y );
        $o->( $matrix, \$rx, \$ry );
        return ( $rx, $ry );
    }

    sub uiDrawMatrixTransformSize ( $matrix, $w, $h ) {
        state $o //= wrap $lib, 'uiDrawMatrixTransformSize', [ Pointer [ DrawMatrix() ], Pointer [Double], Pointer [Double] ] => Void;
        my ( $rw, $rh ) = ( $w, $h );
        $o->( $matrix, \$rw, \$rh );
        return ( $rw, $rh );
    }

    # Drawing Context Operations
    affix $lib, 'uiDrawTransform', [ Pointer [Void], Pointer [ DrawMatrix() ] ] => Void;
    affix $lib, 'uiDrawClip',      [ Pointer [Void], Pointer [Void] ]           => Void;
    affix $lib, 'uiDrawSave',      [ Pointer [Void] ]                           => Void;
    affix $lib, 'uiDrawRestore',   [ Pointer [Void] ]                           => Void;

    # Image
    affix $lib, 'uiNewImage',    [ Double, Double ]                                => Pointer [Void];
    affix $lib, 'uiFreeImage',   [ Pointer [Void] ]                                => Void;
    affix $lib, 'uiImageAppend', [ Pointer [Void], Pointer [Void], Int, Int, Int ] => Void;

    # Text Attributes
    affix $lib, 'uiFreeAttribute',       [ Pointer [Void] ]                 => Void;
    affix $lib, 'uiAttributeGetType',    [ Pointer [Void] ]                 => Int;
    affix $lib, 'uiNewFamilyAttribute',  [String]                           => Pointer [Void];
    affix $lib, 'uiAttributeFamily',     [ Pointer [Void] ]                 => String;
    affix $lib, 'uiNewSizeAttribute',    [Double]                           => Pointer [Void];
    affix $lib, 'uiAttributeSize',       [ Pointer [Void] ]                 => Double;
    affix $lib, 'uiNewWeightAttribute',  [Int]                              => Pointer [Void];
    affix $lib, 'uiAttributeWeight',     [ Pointer [Void] ]                 => Int;
    affix $lib, 'uiNewItalicAttribute',  [Int]                              => Pointer [Void];
    affix $lib, 'uiAttributeItalic',     [ Pointer [Void] ]                 => Int;
    affix $lib, 'uiNewStretchAttribute', [Int]                              => Pointer [Void];
    affix $lib, 'uiAttributeStretch',    [ Pointer [Void] ]                 => Int;
    affix $lib, 'uiNewColorAttribute',   [ Double, Double, Double, Double ] => Pointer [Void];

    sub uiAttributeColor ($attr) {
        state $o //= wrap $lib, 'uiAttributeColor',
            [ Pointer [Void], Pointer [Double], Pointer [Double], Pointer [Double], Pointer [Double] ] => Void;
        my ( $r, $g, $b, $a ) = ( 0, 0, 0, 0 );
        $o->( $attr, \$r, \$g, \$b, \$a );
        return ( $r, $g, $b, $a );
    }
    affix $lib, 'uiNewBackgroundAttribute',     [ Double, Double, Double, Double ]      => Pointer [Void];
    affix $lib, 'uiNewUnderlineAttribute',      [Int]                                   => Pointer [Void];
    affix $lib, 'uiAttributeUnderline',         [ Pointer [Void] ]                      => Int;
    affix $lib, 'uiNewUnderlineColorAttribute', [ Int, Double, Double, Double, Double ] => Pointer [Void];

    sub uiAttributeUnderlineColor ($attr) {
        state $o //= wrap $lib, 'uiAttributeUnderlineColor',
            [ Pointer [Void], Pointer [Int], Pointer [Double], Pointer [Double], Pointer [Double], Pointer [Double] ] => Void;
        my ( $ul, $r, $g, $b, $a ) = ( 0, 0, 0, 0, 0 );
        $o->( $attr, \$ul, \$r, \$g, \$b, \$a );
        return ( $ul, $r, $g, $b, $a );
    }

    # OpenType Features
    affix $lib, 'uiNewOpenTypeFeatures',     []                                                           => Pointer [Void];
    affix $lib, 'uiFreeOpenTypeFeatures',    [ Pointer [Void] ]                                           => Void;
    affix $lib, 'uiOpenTypeFeaturesClone',   [ Pointer [Void] ]                                           => Pointer [Void];
    affix $lib, 'uiOpenTypeFeaturesAdd',     [ Pointer [Void], Char, Char, Char, Char, UInt32 ]           => Void;
    affix $lib, 'uiOpenTypeFeaturesRemove',  [ Pointer [Void], Char, Char, Char, Char ]                   => Void;
    affix $lib, 'uiOpenTypeFeaturesGet',     [ Pointer [Void], Char, Char, Char, Char, Pointer [UInt32] ] => Int;
    affix $lib, 'uiOpenTypeFeaturesForEach', [ Pointer [Void], Pointer [Void], Pointer [Void] ]           => Void;
    affix $lib, 'uiNewFeaturesAttribute',    [ Pointer [Void] ]                                           => Pointer [Void];
    affix $lib, 'uiAttributeFeatures',       [ Pointer [Void] ]                                           => Pointer [Void];

    # Attributed Strings
    affix $lib, 'uiNewAttributedString',                  [String]                                           => Pointer [Void];
    affix $lib, 'uiFreeAttributedString',                 [ Pointer [Void] ]                                 => Void;
    affix $lib, 'uiAttributedStringString',               [ Pointer [Void] ]                                 => String;
    affix $lib, 'uiAttributedStringLen',                  [ Pointer [Void] ]                                 => Size_t;
    affix $lib, 'uiAttributedStringAppendUnattributed',   [ Pointer [Void], String ]                         => Void;
    affix $lib, 'uiAttributedStringInsertAtUnattributed', [ Pointer [Void], String, Size_t ]                 => Void;
    affix $lib, 'uiAttributedStringDelete',               [ Pointer [Void], Size_t, Size_t ]                 => Void;
    affix $lib, 'uiAttributedStringSetAttribute',         [ Pointer [Void], Pointer [Void], Size_t, Size_t ] => Void;
    affix $lib, 'uiAttributedStringForEachAttribute',     [ Pointer [Void], Pointer [Void], Pointer [Void] ] => Void;
    affix $lib, 'uiAttributedStringNumGraphemes',         [ Pointer [Void] ]                                 => Size_t;
    affix $lib, 'uiAttributedStringByteIndexToGrapheme',  [ Pointer [Void], Size_t ]                         => Size_t;
    affix $lib, 'uiAttributedStringGraphemeToByteIndex',  [ Pointer [Void], Size_t ]                         => Size_t;

    # Text Layout Drawing
    typedef DrawTextLayoutParams => Struct [ String => Pointer [Void], DefaultFont => Pointer [Void], Width => Double, Align => Int ];
    affix $lib, 'uiDrawNewTextLayout',  [ Pointer [Void] ]                                 => Pointer [Void];
    affix $lib, 'uiDrawFreeTextLayout', [ Pointer [Void] ]                                 => Void;
    affix $lib, 'uiDrawText',           [ Pointer [Void], Pointer [Void], Double, Double ] => Void;

    sub uiDrawTextLayoutExtents($layout) {
        state $o //= wrap $lib, 'uiDrawTextLayoutExtents', [ Pointer [Void], Pointer [Double], Pointer [Double] ] => Void;
        my ( $w, $h ) = ( 0, 0 );
        $o->( $layout, \$w, \$h );
        return ( $w, $h );
    }

    # Table System
    typedef 'LibUI::TableSelection'                => Struct [ NumRows          => Int, Rows => Pointer [Int] ];
    typedef 'LibUI::TableTextColumnOptionalParams' => Struct [ ColorModelColumn => Int ];

    # TableValue functions
    affix $lib, 'uiFreeTableValue',      [ Pointer [Void] ]                                                                         => Void;
    affix $lib, 'uiTableValueGetType',   [ Pointer [Void] ]                                                                         => Int;
    affix $lib, 'uiNewTableValueString', [String]                                                                                   => Pointer [Void];
    affix $lib, 'uiTableValueString',    [ Pointer [Void] ]                                                                         => String;
    affix $lib, 'uiNewTableValueImage',  [ Pointer [Void] ]                                                                         => Pointer [Void];
    affix $lib, 'uiTableValueImage',     [ Pointer [Void] ]                                                                         => Pointer [Void];
    affix $lib, 'uiNewTableValueInt',    [Int]                                                                                      => Pointer [Void];
    affix $lib, 'uiTableValueInt',       [ Pointer [Void] ]                                                                         => Int;
    affix $lib, 'uiNewTableValueColor',  [ Double, Double, Double, Double ]                                                         => Pointer [Void];
    affix $lib, 'uiTableValueColor',     [ Pointer [Void], Pointer [Double], Pointer [Double], Pointer [Double], Pointer [Double] ] => Void;

    # Table struct typedefs
    typedef TableModelHandler => Struct [
        NumColumns   => Callback [ [ Pointer [Void], Pointer [Void] ]                           => Int ],
        ColumnType   => Callback [ [ Pointer [Void], Pointer [Void], Int ]                      => Int ],
        NumRows      => Callback [ [ Pointer [Void], Pointer [Void] ]                           => Int ],
        CellValue    => Callback [ [ Pointer [Void], Pointer [Void], Int, Int ]                 => Pointer [Void] ],
        SetCellValue => Callback [ [ Pointer [Void], Pointer [Void], Int, Int, Pointer [Void] ] => Void ]
    ];
    typedef TableParams => Struct [ Model => Pointer [Void], RowBackgroundColorModelColumn => Int ];

    # TableModel functions
    affix $lib, 'uiNewTableModel',         [ Pointer [ TableModelHandler() ] ] => Pointer [Void];
    affix $lib, 'uiFreeTableModel',        [ Pointer [Void] ]                  => Void;
    affix $lib, 'uiTableModelRowInserted', [ Pointer [Void], Int ]             => Void;
    affix $lib, 'uiTableModelRowChanged',  [ Pointer [Void], Int ]             => Void;
    affix $lib, 'uiTableModelRowDeleted',  [ Pointer [Void], Int ]             => Void;

    # Table column functions
    affix $lib, 'uiTableAppendTextColumn',         [ Pointer [Void], String, Int, Int, Pointer [Void] ]           => Void;
    affix $lib, 'uiTableAppendImageColumn',        [ Pointer [Void], String, Int ]                                => Void;
    affix $lib, 'uiTableAppendImageTextColumn',    [ Pointer [Void], String, Int, Int, Int, Pointer [Void] ]      => Void;
    affix $lib, 'uiTableAppendCheckboxColumn',     [ Pointer [Void], String, Int, Int ]                           => Void;
    affix $lib, 'uiTableAppendCheckboxTextColumn', [ Pointer [Void], String, Int, Int, Int, Int, Pointer [Void] ] => Void;
    affix $lib, 'uiTableAppendProgressBarColumn',  [ Pointer [Void], String, Int ]                                => Void;
    affix $lib, 'uiTableAppendButtonColumn',       [ Pointer [Void], String, Int, Int ]                           => Void;

    # Table view functions
    sub uiNewTable ($params) {
        state $o //= wrap $lib, 'uiNewTable', [ Pointer [ TableParams() ] ] => Pointer [Void];
        if ( ref $params eq 'HASH' ) {
            $params->{RowBackgroundColorModelColumn} //= -1;
            return $o->($params);
        }
        $o->( { Model => $params, RowBackgroundColorModelColumn => -1 } );
    }
    affix $lib, 'uiTableHeaderVisible',      [ Pointer [Void] ]                                                                               => Int;
    affix $lib, 'uiTableHeaderSetVisible',   [ Pointer [Void], Int ]                                                                          => Void;
    affix $lib, 'uiTableOnRowClicked',       [ Pointer [Void], Callback [ [ Pointer [Void], Int, Pointer [Void] ] => Void ], Pointer [Void] ] => Void;
    affix $lib, 'uiTableOnRowDoubleClicked', [ Pointer [Void], Callback [ [ Pointer [Void], Int, Pointer [Void] ] => Void ], Pointer [Void] ] => Void;
    affix $lib, 'uiTableHeaderSetSortIndicator', [ Pointer [Void], Int, Int ]                                                                 => Void;
    affix $lib, 'uiTableHeaderSortIndicator',    [ Pointer [Void], Int ]                                                                      => Int;
    affix $lib, 'uiTableHeaderOnClicked',    [ Pointer [Void], Callback [ [ Pointer [Void], Int, Pointer [Void] ] => Void ], Pointer [Void] ] => Void;
    affix $lib, 'uiTableColumnWidth',        [ Pointer [Void], Int ]                                                                          => Int;
    affix $lib, 'uiTableColumnSetWidth',     [ Pointer [Void], Int, Int ]                                                                     => Void;
    affix $lib, 'uiTableGetSelectionMode',   [ Pointer [Void] ]                                                                               => Int;
    affix $lib, 'uiTableSetSelectionMode',   [ Pointer [Void], Int ]                                                                          => Void;
    affix $lib, 'uiTableOnSelectionChanged', [ Pointer [Void], Callback [ [ Pointer [Void], Pointer [Void] ] => Void ], Pointer [Void] ]      => Void;
    affix $lib, 'uiTableGetSelection',       [ Pointer [Void] ]                 => Pointer [Void];
    affix $lib, 'uiTableSetSelection',       [ Pointer [Void], Pointer [Void] ] => Void;
    affix $lib, 'uiFreeTableSelection',      [ Pointer [Void] ]                 => Void;

    # Named Constants
    use constant { UI_FILL_WINDING    => 0, UI_FILL_ALTERNATE        => 1 };
    use constant { UI_BRUSH_SOLID     => 0, UI_BRUSH_LINEAR_GRADIENT => 1, UI_BRUSH_RADIAL_GRADIENT => 2 };
    use constant { UI_LINE_CAP_FLAT   => 0, UI_LINE_CAP_ROUND        => 1 };
    use constant { UI_LINE_JOIN_MITER => 0, UI_LINE_JOIN_ROUND       => 1, UI_LINE_JOIN_BEVEL  => 2 };
    use constant { UI_TEXT_ALIGN_LEFT => 0, UI_TEXT_ALIGN_CENTER     => 1, UI_TEXT_ALIGN_RIGHT => 2 };
    use constant {
        UI_WEIGHT_THIN        => 100,
        UI_WEIGHT_EXTRA_LIGHT => 200,
        UI_WEIGHT_LIGHT       => 300,
        UI_WEIGHT_BOOK        => 350,
        UI_WEIGHT_NORMAL      => 400,
        UI_WEIGHT_MEDIUM      => 500,
        UI_WEIGHT_SEMI_BOLD   => 600,
        UI_WEIGHT_BOLD        => 700,
        UI_WEIGHT_EXTRA_BOLD  => 800,
        UI_WEIGHT_HEAVY       => 900
    };
    use constant { UI_ITALIC_NORMAL => 0, UI_ITALIC_OBLIQUE => 1, UI_ITALIC_ITALIC => 2 };
    use constant {
        UI_STRETCH_ULTRA_CONDENSED => 0,
        UI_STRETCH_EXTRA_CONDENSED => 1,
        UI_STRETCH_CONDENSED       => 2,
        UI_STRETCH_SEMI_CONDENSED  => 3,
        UI_STRETCH_NORMAL          => 4,
        UI_STRETCH_SEMI_EXPANDED   => 5,
        UI_STRETCH_EXPANDED        => 6,
        UI_STRETCH_EXTRA_EXPANDED  => 7,
        UI_STRETCH_ULTRA_EXPANDED  => 8
    };
    use constant { UI_UNDERLINE_NONE      => 0, UI_UNDERLINE_SINGLE   => 1, UI_UNDERLINE_DOUBLE   => 2, UI_UNDERLINE_SQUIGGLE => 3 };
    use constant { UI_TABLE_COLUMN_STRING => 0, UI_TABLE_COLUMN_IMAGE => 1, UI_TABLE_COLUMN_INT   => 2, UI_TABLE_COLUMN_COLOR => 3 };
    use constant { UI_SELECTION_NONE      => 0, UI_SELECTION_SINGLE   => 1, UI_SELECTION_MULTIPLE => 2 };
    use constant { UI_SORT_NONE           => 0, UI_SORT_ASCENDING     => 1, UI_SORT_DESCENDING    => 2 };
    use constant { UI_ALIGN_FILL          => 0, UI_ALIGN_START        => 1, UI_ALIGN_CENTER       => 2, UI_ALIGN_END => 3 };

    # DrawBrush helpers
    sub solid_brush ( $r, $g, $b, $a //= 1.0 ) {
        {   Type        => UI_BRUSH_SOLID,
            R           => $r,
            G           => $g,
            B           => $b,
            A           => $a,
            X0          => 0,
            Y0          => 0,
            X1          => 0,
            Y1          => 0,
            OuterRadius => 0,
            Stops       => undef,
            NumStops    => 0
        };
    }

    # DrawStroke helper
    sub draw_stroke (%p) {
        {   Cap        => $p{cap}         // UI_LINE_CAP_FLAT,
            Join       => $p{join}        // UI_LINE_JOIN_MITER,
            Thickness  => $p{thickness}   // 1.0,
            MiterLimit => $p{miter_limit} // 10.0,
            Dashes     => $p{dashes}      // undef,
            NumDashes  => $p{num_dashes}  // 0,
            DashPhase  => $p{dash_phase}  // 0.0
        };
    }

    # DrawMatrix OO wrapper
    package LibUI::Matrix v1.0.0 {

        sub new ( $class, %opts ) {
            return bless {
                M11 => $opts{m11} // 1,
                M12 => $opts{m12} // 0,
                M21 => $opts{m21} // 0,
                M22 => $opts{m22} // 1,
                M31 => $opts{m31} // 0,
                M32 => $opts{m32} // 0
            }, $class;
        }
        sub identity ($class) { $class->new() }

        sub set_identity ($self) {
            $self->{M11} = 1;
            $self->{M12} = 0;
            $self->{M21} = 0;
            $self->{M22} = 1;
            $self->{M31} = 0;
            $self->{M32} = 0;
            return $self;
        }

        sub translate ( $self, $x, $y ) {
            LibUI::uiDrawMatrixTranslate( $self, $x, $y );
            return $self;
        }

        sub scale ( $self, $x, $y, $w, $h ) {
            LibUI::uiDrawMatrixScale( $self, $x, $y, $w, $h );
            return $self;
        }

        sub rotate ( $self, $x, $y, $angle ) {
            LibUI::uiDrawMatrixRotate( $self, $x, $y, $angle );
            return $self;
        }

        sub skew ( $self, $x, $y, $xamount, $yamount ) {
            LibUI::uiDrawMatrixSkew( $self, $x, $y, $xamount, $yamount );
            return $self;
        }

        sub multiply ( $self, $other ) {
            LibUI::uiDrawMatrixMultiply( $self, $other );
            return $self;
        }
        sub invertible      ($self)           { LibUI::uiDrawMatrixInvertible($self) }
        sub invert          ($self)           { LibUI::uiDrawMatrixInvert($self) }
        sub transform_point ( $self, $x, $y ) { LibUI::uiDrawMatrixTransformPoint( $self, $x, $y ) }

        sub transform_size ( $self, $w, $h ) {
            LibUI::uiDrawMatrixTransformSize( $self, $w, $h );
        }

        sub apply( $self, $dc ) {
            LibUI::uiDrawTransform( $dc, $self );
            return $self;
        }
    }

    # Utility to format struct tm as a localized string
    sub format_tm ( $tm, $format //= '%A, %B %d, %Y', $locale //= () ) {    # Time::tm is core but...
        use POSIX qw[setlocale strftime LC_TIME];
        setlocale LC_TIME, $locale if defined $locale;
        strftime $format, $tm->{tm_sec}, $tm->{tm_min}, $tm->{tm_hour}, $tm->{tm_mday}, $tm->{tm_mon}, $tm->{tm_year}, $tm->{tm_wday};
    }
}
1;

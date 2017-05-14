extern HV * pGtkType[];
extern char * pGtkTypeName[];
extern HV * pG_EnumHash;
extern HV * pG_FlagsHash;
extern AV * gtk_typecasts;
extern int type_name(char * name);

extern void add_typecast(int type, char * perlName);
extern SV * GtkGetArg(GtkArg * a);
extern void GtkSetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);
extern void GtkSetRetArg(GtkArg * a, SV * v, SV * Class, GtkObject * Object);

/*extern SV * newSVOptsHash(long value, char * name, HV * hash);
extern long SvOptsHash(SV * value, char * name, HV * hash);
extern SV * newSVFlagsHash(long value, char * name, HV * hash, int);
extern long SvFlagsHash(SV * value, char * name, HV * hash);*/

#define pGE_GdkAxisUse pGtkType[0]
#define pGEName_GdkAxisUse pGtkTypeName[0]
#define newSVGdkAxisUse(v) newSVOptsHash(v, pGEName_GdkAxisUse, pGE_GdkAxisUse)
#define SvGdkAxisUse(v) SvOptsHash(v, pGEName_GdkAxisUse, pGE_GdkAxisUse)
typedef GdkAxisUse Gtk__Gdk__AxisUse;
#define pGE_GdkByteOrder pGtkType[1]
#define pGEName_GdkByteOrder pGtkTypeName[1]
#define newSVGdkByteOrder(v) newSVOptsHash(v, pGEName_GdkByteOrder, pGE_GdkByteOrder)
#define SvGdkByteOrder(v) SvOptsHash(v, pGEName_GdkByteOrder, pGE_GdkByteOrder)
typedef GdkByteOrder Gtk__Gdk__ByteOrder;
#define pGE_GdkCapStyle pGtkType[2]
#define pGEName_GdkCapStyle pGtkTypeName[2]
#define newSVGdkCapStyle(v) newSVOptsHash(v, pGEName_GdkCapStyle, pGE_GdkCapStyle)
#define SvGdkCapStyle(v) SvOptsHash(v, pGEName_GdkCapStyle, pGE_GdkCapStyle)
typedef GdkCapStyle Gtk__Gdk__CapStyle;
#define pGE_GdkCursorType pGtkType[3]
#define pGEName_GdkCursorType pGtkTypeName[3]
#define newSVGdkCursorType(v) newSVOptsHash(v, pGEName_GdkCursorType, pGE_GdkCursorType)
#define SvGdkCursorType(v) SvOptsHash(v, pGEName_GdkCursorType, pGE_GdkCursorType)
typedef GdkCursorType Gtk__Gdk__CursorType;
#define pGE_GdkEventType pGtkType[4]
#define pGEName_GdkEventType pGtkTypeName[4]
#define newSVGdkEventType(v) newSVOptsHash(v, pGEName_GdkEventType, pGE_GdkEventType)
#define SvGdkEventType(v) SvOptsHash(v, pGEName_GdkEventType, pGE_GdkEventType)
typedef GdkEventType Gtk__Gdk__EventType;
#define pGE_GdkFill pGtkType[5]
#define pGEName_GdkFill pGtkTypeName[5]
#define newSVGdkFill(v) newSVOptsHash(v, pGEName_GdkFill, pGE_GdkFill)
#define SvGdkFill(v) SvOptsHash(v, pGEName_GdkFill, pGE_GdkFill)
typedef GdkFill Gtk__Gdk__Fill;
#define pGE_GdkFunction pGtkType[6]
#define pGEName_GdkFunction pGtkTypeName[6]
#define newSVGdkFunction(v) newSVOptsHash(v, pGEName_GdkFunction, pGE_GdkFunction)
#define SvGdkFunction(v) SvOptsHash(v, pGEName_GdkFunction, pGE_GdkFunction)
typedef GdkFunction Gtk__Gdk__Function;
#define pGE_GdkImageType pGtkType[7]
#define pGEName_GdkImageType pGtkTypeName[7]
#define newSVGdkImageType(v) newSVOptsHash(v, pGEName_GdkImageType, pGE_GdkImageType)
#define SvGdkImageType(v) SvOptsHash(v, pGEName_GdkImageType, pGE_GdkImageType)
typedef GdkImageType Gtk__Gdk__ImageType;
#define pGE_GdkInputMode pGtkType[8]
#define pGEName_GdkInputMode pGtkTypeName[8]
#define newSVGdkInputMode(v) newSVOptsHash(v, pGEName_GdkInputMode, pGE_GdkInputMode)
#define SvGdkInputMode(v) SvOptsHash(v, pGEName_GdkInputMode, pGE_GdkInputMode)
typedef GdkInputMode Gtk__Gdk__InputMode;
#define pGE_GdkInputSource pGtkType[9]
#define pGEName_GdkInputSource pGtkTypeName[9]
#define newSVGdkInputSource(v) newSVOptsHash(v, pGEName_GdkInputSource, pGE_GdkInputSource)
#define SvGdkInputSource(v) SvOptsHash(v, pGEName_GdkInputSource, pGE_GdkInputSource)
typedef GdkInputSource Gtk__Gdk__InputSource;
#define pGE_GdkJoinStyle pGtkType[10]
#define pGEName_GdkJoinStyle pGtkTypeName[10]
#define newSVGdkJoinStyle(v) newSVOptsHash(v, pGEName_GdkJoinStyle, pGE_GdkJoinStyle)
#define SvGdkJoinStyle(v) SvOptsHash(v, pGEName_GdkJoinStyle, pGE_GdkJoinStyle)
typedef GdkJoinStyle Gtk__Gdk__JoinStyle;
#define pGE_GdkLineStyle pGtkType[11]
#define pGEName_GdkLineStyle pGtkTypeName[11]
#define newSVGdkLineStyle(v) newSVOptsHash(v, pGEName_GdkLineStyle, pGE_GdkLineStyle)
#define SvGdkLineStyle(v) SvOptsHash(v, pGEName_GdkLineStyle, pGE_GdkLineStyle)
typedef GdkLineStyle Gtk__Gdk__LineStyle;
#define pGE_GdkNotifyType pGtkType[12]
#define pGEName_GdkNotifyType pGtkTypeName[12]
#define newSVGdkNotifyType(v) newSVOptsHash(v, pGEName_GdkNotifyType, pGE_GdkNotifyType)
#define SvGdkNotifyType(v) SvOptsHash(v, pGEName_GdkNotifyType, pGE_GdkNotifyType)
typedef GdkNotifyType Gtk__Gdk__NotifyType;
#define pGE_GdkOverlapType pGtkType[13]
#define pGEName_GdkOverlapType pGtkTypeName[13]
#define newSVGdkOverlapType(v) newSVOptsHash(v, pGEName_GdkOverlapType, pGE_GdkOverlapType)
#define SvGdkOverlapType(v) SvOptsHash(v, pGEName_GdkOverlapType, pGE_GdkOverlapType)
typedef GdkOverlapType Gtk__Gdk__OverlapType;
#define pGE_GdkPropMode pGtkType[14]
#define pGEName_GdkPropMode pGtkTypeName[14]
#define newSVGdkPropMode(v) newSVOptsHash(v, pGEName_GdkPropMode, pGE_GdkPropMode)
#define SvGdkPropMode(v) SvOptsHash(v, pGEName_GdkPropMode, pGE_GdkPropMode)
typedef GdkPropMode Gtk__Gdk__PropMode;
#define pGE_GdkPropertyState pGtkType[15]
#define pGEName_GdkPropertyState pGtkTypeName[15]
#define newSVGdkPropertyState(v) newSVOptsHash(v, pGEName_GdkPropertyState, pGE_GdkPropertyState)
#define SvGdkPropertyState(v) SvOptsHash(v, pGEName_GdkPropertyState, pGE_GdkPropertyState)
typedef GdkPropertyState Gtk__Gdk__PropertyState;
#define pGE_GdkSelection pGtkType[16]
#define pGEName_GdkSelection pGtkTypeName[16]
#define newSVGdkSelection(v) newSVOptsHash(v, pGEName_GdkSelection, pGE_GdkSelection)
#define SvGdkSelection(v) SvOptsHash(v, pGEName_GdkSelection, pGE_GdkSelection)
typedef GdkSelection Gtk__Gdk__Selection;
#define pGE_GdkStatus pGtkType[17]
#define pGEName_GdkStatus pGtkTypeName[17]
#define newSVGdkStatus(v) newSVOptsHash(v, pGEName_GdkStatus, pGE_GdkStatus)
#define SvGdkStatus(v) SvOptsHash(v, pGEName_GdkStatus, pGE_GdkStatus)
typedef GdkStatus Gtk__Gdk__Status;
#define pGE_GdkSubwindowMode pGtkType[18]
#define pGEName_GdkSubwindowMode pGtkTypeName[18]
#define newSVGdkSubwindowMode(v) newSVOptsHash(v, pGEName_GdkSubwindowMode, pGE_GdkSubwindowMode)
#define SvGdkSubwindowMode(v) SvOptsHash(v, pGEName_GdkSubwindowMode, pGE_GdkSubwindowMode)
typedef GdkSubwindowMode Gtk__Gdk__SubwindowMode;
#define pGE_GdkVisualType pGtkType[19]
#define pGEName_GdkVisualType pGtkTypeName[19]
#define newSVGdkVisualType(v) newSVOptsHash(v, pGEName_GdkVisualType, pGE_GdkVisualType)
#define SvGdkVisualType(v) SvOptsHash(v, pGEName_GdkVisualType, pGE_GdkVisualType)
typedef GdkVisualType Gtk__Gdk__VisualType;
#define pGE_GdkWindowClass pGtkType[20]
#define pGEName_GdkWindowClass pGtkTypeName[20]
#define newSVGdkWindowClass(v) newSVOptsHash(v, pGEName_GdkWindowClass, pGE_GdkWindowClass)
#define SvGdkWindowClass(v) SvOptsHash(v, pGEName_GdkWindowClass, pGE_GdkWindowClass)
typedef GdkWindowClass Gtk__Gdk__WindowClass;
#define pGE_GdkWindowType pGtkType[21]
#define pGEName_GdkWindowType pGtkTypeName[21]
#define newSVGdkWindowType(v) newSVOptsHash(v, pGEName_GdkWindowType, pGE_GdkWindowType)
#define SvGdkWindowType(v) SvOptsHash(v, pGEName_GdkWindowType, pGE_GdkWindowType)
typedef GdkWindowType Gtk__Gdk__WindowType;
#define pGE_GtkArrowType pGtkType[22]
#define pGEName_GtkArrowType pGtkTypeName[22]
#define newSVGtkArrowType(v) newSVOptsHash(v, pGEName_GtkArrowType, pGE_GtkArrowType)
#define SvGtkArrowType(v) SvOptsHash(v, pGEName_GtkArrowType, pGE_GtkArrowType)
typedef GtkArrowType Gtk__ArrowType;
#define pGE_GtkButtonBoxStyle pGtkType[23]
#define pGEName_GtkButtonBoxStyle pGtkTypeName[23]
#define newSVGtkButtonBoxStyle(v) newSVOptsHash(v, pGEName_GtkButtonBoxStyle, pGE_GtkButtonBoxStyle)
#define SvGtkButtonBoxStyle(v) SvOptsHash(v, pGEName_GtkButtonBoxStyle, pGE_GtkButtonBoxStyle)
typedef GtkButtonBoxStyle Gtk__ButtonBoxStyle;
#define pGE_GtkCellType pGtkType[24]
#define pGEName_GtkCellType pGtkTypeName[24]
#define newSVGtkCellType(v) newSVOptsHash(v, pGEName_GtkCellType, pGE_GtkCellType)
#define SvGtkCellType(v) SvOptsHash(v, pGEName_GtkCellType, pGE_GtkCellType)
typedef GtkCellType Gtk__CellType;
#define pGE_GtkCurveType pGtkType[25]
#define pGEName_GtkCurveType pGtkTypeName[25]
#define newSVGtkCurveType(v) newSVOptsHash(v, pGEName_GtkCurveType, pGE_GtkCurveType)
#define SvGtkCurveType(v) SvOptsHash(v, pGEName_GtkCurveType, pGE_GtkCurveType)
typedef GtkCurveType Gtk__CurveType;
#define pGE_GtkDirectionType pGtkType[26]
#define pGEName_GtkDirectionType pGtkTypeName[26]
#define newSVGtkDirectionType(v) newSVOptsHash(v, pGEName_GtkDirectionType, pGE_GtkDirectionType)
#define SvGtkDirectionType(v) SvOptsHash(v, pGEName_GtkDirectionType, pGE_GtkDirectionType)
typedef GtkDirectionType Gtk__DirectionType;
#define pGE_GtkFundamentalType pGtkType[27]
#define pGEName_GtkFundamentalType pGtkTypeName[27]
#define newSVGtkFundamentalType(v) newSVOptsHash(v, pGEName_GtkFundamentalType, pGE_GtkFundamentalType)
#define SvGtkFundamentalType(v) SvOptsHash(v, pGEName_GtkFundamentalType, pGE_GtkFundamentalType)
typedef GtkFundamentalType Gtk__FundamentalType;
#define pGE_GtkJustification pGtkType[28]
#define pGEName_GtkJustification pGtkTypeName[28]
#define newSVGtkJustification(v) newSVOptsHash(v, pGEName_GtkJustification, pGE_GtkJustification)
#define SvGtkJustification(v) SvOptsHash(v, pGEName_GtkJustification, pGE_GtkJustification)
typedef GtkJustification Gtk__Justification;
#define pGE_GtkMenuFactoryType pGtkType[29]
#define pGEName_GtkMenuFactoryType pGtkTypeName[29]
#define newSVGtkMenuFactoryType(v) newSVOptsHash(v, pGEName_GtkMenuFactoryType, pGE_GtkMenuFactoryType)
#define SvGtkMenuFactoryType(v) SvOptsHash(v, pGEName_GtkMenuFactoryType, pGE_GtkMenuFactoryType)
typedef GtkMenuFactoryType Gtk__MenuFactoryType;
#define pGE_GtkMetricType pGtkType[30]
#define pGEName_GtkMetricType pGtkTypeName[30]
#define newSVGtkMetricType(v) newSVOptsHash(v, pGEName_GtkMetricType, pGE_GtkMetricType)
#define SvGtkMetricType(v) SvOptsHash(v, pGEName_GtkMetricType, pGE_GtkMetricType)
typedef GtkMetricType Gtk__MetricType;
#define pGE_GtkOrientation pGtkType[31]
#define pGEName_GtkOrientation pGtkTypeName[31]
#define newSVGtkOrientation(v) newSVOptsHash(v, pGEName_GtkOrientation, pGE_GtkOrientation)
#define SvGtkOrientation(v) SvOptsHash(v, pGEName_GtkOrientation, pGE_GtkOrientation)
typedef GtkOrientation Gtk__Orientation;
#define pGE_GtkPackType pGtkType[32]
#define pGEName_GtkPackType pGtkTypeName[32]
#define newSVGtkPackType(v) newSVOptsHash(v, pGEName_GtkPackType, pGE_GtkPackType)
#define SvGtkPackType(v) SvOptsHash(v, pGEName_GtkPackType, pGE_GtkPackType)
typedef GtkPackType Gtk__PackType;
#define pGE_GtkPolicyType pGtkType[33]
#define pGEName_GtkPolicyType pGtkTypeName[33]
#define newSVGtkPolicyType(v) newSVOptsHash(v, pGEName_GtkPolicyType, pGE_GtkPolicyType)
#define SvGtkPolicyType(v) SvOptsHash(v, pGEName_GtkPolicyType, pGE_GtkPolicyType)
typedef GtkPolicyType Gtk__PolicyType;
#define pGE_GtkPositionType pGtkType[34]
#define pGEName_GtkPositionType pGtkTypeName[34]
#define newSVGtkPositionType(v) newSVOptsHash(v, pGEName_GtkPositionType, pGE_GtkPositionType)
#define SvGtkPositionType(v) SvOptsHash(v, pGEName_GtkPositionType, pGE_GtkPositionType)
typedef GtkPositionType Gtk__PositionType;
#define pGE_GtkPreviewType pGtkType[35]
#define pGEName_GtkPreviewType pGtkTypeName[35]
#define newSVGtkPreviewType(v) newSVOptsHash(v, pGEName_GtkPreviewType, pGE_GtkPreviewType)
#define SvGtkPreviewType(v) SvOptsHash(v, pGEName_GtkPreviewType, pGE_GtkPreviewType)
typedef GtkPreviewType Gtk__PreviewType;
#define pGE_GtkScrollType pGtkType[36]
#define pGEName_GtkScrollType pGtkTypeName[36]
#define newSVGtkScrollType(v) newSVOptsHash(v, pGEName_GtkScrollType, pGE_GtkScrollType)
#define SvGtkScrollType(v) SvOptsHash(v, pGEName_GtkScrollType, pGE_GtkScrollType)
typedef GtkScrollType Gtk__ScrollType;
#define pGE_GtkSelectionMode pGtkType[37]
#define pGEName_GtkSelectionMode pGtkTypeName[37]
#define newSVGtkSelectionMode(v) newSVOptsHash(v, pGEName_GtkSelectionMode, pGE_GtkSelectionMode)
#define SvGtkSelectionMode(v) SvOptsHash(v, pGEName_GtkSelectionMode, pGE_GtkSelectionMode)
typedef GtkSelectionMode Gtk__SelectionMode;
#define pGE_GtkShadowType pGtkType[38]
#define pGEName_GtkShadowType pGtkTypeName[38]
#define newSVGtkShadowType(v) newSVOptsHash(v, pGEName_GtkShadowType, pGE_GtkShadowType)
#define SvGtkShadowType(v) SvOptsHash(v, pGEName_GtkShadowType, pGE_GtkShadowType)
typedef GtkShadowType Gtk__ShadowType;
#define pGE_GtkStateType pGtkType[39]
#define pGEName_GtkStateType pGtkTypeName[39]
#define newSVGtkStateType(v) newSVOptsHash(v, pGEName_GtkStateType, pGE_GtkStateType)
#define SvGtkStateType(v) SvOptsHash(v, pGEName_GtkStateType, pGE_GtkStateType)
typedef GtkStateType Gtk__StateType;
#define pGE_GtkSubmenuDirection pGtkType[40]
#define pGEName_GtkSubmenuDirection pGtkTypeName[40]
#define newSVGtkSubmenuDirection(v) newSVOptsHash(v, pGEName_GtkSubmenuDirection, pGE_GtkSubmenuDirection)
#define SvGtkSubmenuDirection(v) SvOptsHash(v, pGEName_GtkSubmenuDirection, pGE_GtkSubmenuDirection)
typedef GtkSubmenuDirection Gtk__SubmenuDirection;
#define pGE_GtkSubmenuPlacement pGtkType[41]
#define pGEName_GtkSubmenuPlacement pGtkTypeName[41]
#define newSVGtkSubmenuPlacement(v) newSVOptsHash(v, pGEName_GtkSubmenuPlacement, pGE_GtkSubmenuPlacement)
#define SvGtkSubmenuPlacement(v) SvOptsHash(v, pGEName_GtkSubmenuPlacement, pGE_GtkSubmenuPlacement)
typedef GtkSubmenuPlacement Gtk__SubmenuPlacement;
#define pGE_GtkToolbarChildType pGtkType[42]
#define pGEName_GtkToolbarChildType pGtkTypeName[42]
#define newSVGtkToolbarChildType(v) newSVOptsHash(v, pGEName_GtkToolbarChildType, pGE_GtkToolbarChildType)
#define SvGtkToolbarChildType(v) SvOptsHash(v, pGEName_GtkToolbarChildType, pGE_GtkToolbarChildType)
typedef GtkToolbarChildType Gtk__ToolbarChildType;
#define pGE_GtkToolbarStyle pGtkType[43]
#define pGEName_GtkToolbarStyle pGtkTypeName[43]
#define newSVGtkToolbarStyle(v) newSVOptsHash(v, pGEName_GtkToolbarStyle, pGE_GtkToolbarStyle)
#define SvGtkToolbarStyle(v) SvOptsHash(v, pGEName_GtkToolbarStyle, pGE_GtkToolbarStyle)
typedef GtkToolbarStyle Gtk__ToolbarStyle;
#define pGE_GtkTreeViewMode pGtkType[44]
#define pGEName_GtkTreeViewMode pGtkTypeName[44]
#define newSVGtkTreeViewMode(v) newSVOptsHash(v, pGEName_GtkTreeViewMode, pGE_GtkTreeViewMode)
#define SvGtkTreeViewMode(v) SvOptsHash(v, pGEName_GtkTreeViewMode, pGE_GtkTreeViewMode)
typedef GtkTreeViewMode Gtk__TreeViewMode;
#define pGE_GtkTroughType pGtkType[45]
#define pGEName_GtkTroughType pGtkTypeName[45]
#define newSVGtkTroughType(v) newSVOptsHash(v, pGEName_GtkTroughType, pGE_GtkTroughType)
#define SvGtkTroughType(v) SvOptsHash(v, pGEName_GtkTroughType, pGE_GtkTroughType)
typedef GtkTroughType Gtk__TroughType;
#define pGE_GtkUpdateType pGtkType[46]
#define pGEName_GtkUpdateType pGtkTypeName[46]
#define newSVGtkUpdateType(v) newSVOptsHash(v, pGEName_GtkUpdateType, pGE_GtkUpdateType)
#define SvGtkUpdateType(v) SvOptsHash(v, pGEName_GtkUpdateType, pGE_GtkUpdateType)
typedef GtkUpdateType Gtk__UpdateType;
#define pGE_GtkWindowPosition pGtkType[47]
#define pGEName_GtkWindowPosition pGtkTypeName[47]
#define newSVGtkWindowPosition(v) newSVOptsHash(v, pGEName_GtkWindowPosition, pGE_GtkWindowPosition)
#define SvGtkWindowPosition(v) SvOptsHash(v, pGEName_GtkWindowPosition, pGE_GtkWindowPosition)
typedef GtkWindowPosition Gtk__WindowPosition;
#define pGE_GtkWindowType pGtkType[48]
#define pGEName_GtkWindowType pGtkTypeName[48]
#define newSVGtkWindowType(v) newSVOptsHash(v, pGEName_GtkWindowType, pGE_GtkWindowType)
#define SvGtkWindowType(v) SvOptsHash(v, pGEName_GtkWindowType, pGE_GtkWindowType)
typedef GtkWindowType Gtk__WindowType;
#define pGF_GdkEventMask pGtkType[49]
#define pGFName_GdkEventMask pGtkTypeName[49]
#define newSVGdkEventMask(v) newSVFlagsHash(v, pGFName_GdkEventMask, pGF_GdkEventMask, 1)
#define SvGdkEventMask(v) SvFlagsHash(v, pGFName_GdkEventMask, pGF_GdkEventMask)
typedef GdkEventMask Gtk__Gdk__EventMask;
#define pGF_GdkGCValuesMask pGtkType[50]
#define pGFName_GdkGCValuesMask pGtkTypeName[50]
#define newSVGdkGCValuesMask(v) newSVFlagsHash(v, pGFName_GdkGCValuesMask, pGF_GdkGCValuesMask, 1)
#define SvGdkGCValuesMask(v) SvFlagsHash(v, pGFName_GdkGCValuesMask, pGF_GdkGCValuesMask)
typedef GdkGCValuesMask Gtk__Gdk__GCValuesMask;
#define pGF_GdkInputCondition pGtkType[51]
#define pGFName_GdkInputCondition pGtkTypeName[51]
#define newSVGdkInputCondition(v) newSVFlagsHash(v, pGFName_GdkInputCondition, pGF_GdkInputCondition, 1)
#define SvGdkInputCondition(v) SvFlagsHash(v, pGFName_GdkInputCondition, pGF_GdkInputCondition)
typedef GdkInputCondition Gtk__Gdk__InputCondition;
#define pGF_GdkModifierType pGtkType[52]
#define pGFName_GdkModifierType pGtkTypeName[52]
#define newSVGdkModifierType(v) newSVFlagsHash(v, pGFName_GdkModifierType, pGF_GdkModifierType, 1)
#define SvGdkModifierType(v) SvFlagsHash(v, pGFName_GdkModifierType, pGF_GdkModifierType)
typedef GdkModifierType Gtk__Gdk__ModifierType;
#define pGF_GdkWMDecoration pGtkType[53]
#define pGFName_GdkWMDecoration pGtkTypeName[53]
#define newSVGdkWMDecoration(v) newSVFlagsHash(v, pGFName_GdkWMDecoration, pGF_GdkWMDecoration, 1)
#define SvGdkWMDecoration(v) SvFlagsHash(v, pGFName_GdkWMDecoration, pGF_GdkWMDecoration)
typedef GdkWMDecoration Gtk__Gdk__WMDecoration;
#define pGF_GdkWMFunction pGtkType[54]
#define pGFName_GdkWMFunction pGtkTypeName[54]
#define newSVGdkWMFunction(v) newSVFlagsHash(v, pGFName_GdkWMFunction, pGF_GdkWMFunction, 1)
#define SvGdkWMFunction(v) SvFlagsHash(v, pGFName_GdkWMFunction, pGF_GdkWMFunction)
typedef GdkWMFunction Gtk__Gdk__WMFunction;
#define pGF_GdkWindowAttributesType pGtkType[55]
#define pGFName_GdkWindowAttributesType pGtkTypeName[55]
#define newSVGdkWindowAttributesType(v) newSVFlagsHash(v, pGFName_GdkWindowAttributesType, pGF_GdkWindowAttributesType, 1)
#define SvGdkWindowAttributesType(v) SvFlagsHash(v, pGFName_GdkWindowAttributesType, pGF_GdkWindowAttributesType)
typedef GdkWindowAttributesType Gtk__Gdk__WindowAttributesType;
#define pGF_GdkWindowHints pGtkType[56]
#define pGFName_GdkWindowHints pGtkTypeName[56]
#define newSVGdkWindowHints(v) newSVFlagsHash(v, pGFName_GdkWindowHints, pGF_GdkWindowHints, 1)
#define SvGdkWindowHints(v) SvFlagsHash(v, pGFName_GdkWindowHints, pGF_GdkWindowHints)
typedef GdkWindowHints Gtk__Gdk__WindowHints;
#define pGF_GtkAttachOptions pGtkType[57]
#define pGFName_GtkAttachOptions pGtkTypeName[57]
#define newSVGtkAttachOptions(v) newSVFlagsHash(v, pGFName_GtkAttachOptions, pGF_GtkAttachOptions, 1)
#define SvGtkAttachOptions(v) SvFlagsHash(v, pGFName_GtkAttachOptions, pGF_GtkAttachOptions)
typedef GtkAttachOptions Gtk__AttachOptions;
#define pGF_GtkSignalRunType pGtkType[58]
#define pGFName_GtkSignalRunType pGtkTypeName[58]
#define newSVGtkSignalRunType(v) newSVFlagsHash(v, pGFName_GtkSignalRunType, pGF_GtkSignalRunType, 1)
#define SvGtkSignalRunType(v) SvFlagsHash(v, pGFName_GtkSignalRunType, pGF_GtkSignalRunType)
typedef GtkSignalRunType Gtk__SignalRunType;
#define pGF_GtkSpinButtonUpdatePolicy pGtkType[59]
#define pGFName_GtkSpinButtonUpdatePolicy pGtkTypeName[59]
#define newSVGtkSpinButtonUpdatePolicy(v) newSVFlagsHash(v, pGFName_GtkSpinButtonUpdatePolicy, pGF_GtkSpinButtonUpdatePolicy, 1)
#define SvGtkSpinButtonUpdatePolicy(v) SvFlagsHash(v, pGFName_GtkSpinButtonUpdatePolicy, pGF_GtkSpinButtonUpdatePolicy)
typedef GtkSpinButtonUpdatePolicy Gtk__SpinButtonUpdatePolicy;
extern SV * newSVGdkBitmap(GdkBitmap * value);
extern GdkBitmap * SvGdkBitmap(SV * value);
typedef GdkBitmap * Gtk__Gdk__Bitmap;
extern SV * newSVGdkColormap(GdkColormap * value);
extern GdkColormap * SvGdkColormap(SV * value);
typedef GdkColormap * Gtk__Gdk__Colormap;
extern SV * newSVGdkFont(GdkFont * value);
extern GdkFont * SvGdkFont(SV * value);
typedef GdkFont * Gtk__Gdk__Font;
extern SV * newSVGdkPixmap(GdkPixmap * value);
extern GdkPixmap * SvGdkPixmap(SV * value);
typedef GdkPixmap * Gtk__Gdk__Pixmap;
extern SV * newSVGdkVisual(GdkVisual * value);
extern GdkVisual * SvGdkVisual(SV * value);
typedef GdkVisual * Gtk__Gdk__Visual;
extern SV * newSVGdkWindow(GdkWindow * value);
extern GdkWindow * SvGdkWindow(SV * value);
typedef GdkWindow * Gtk__Gdk__Window;
extern SV * newSVGtkAcceleratorTable(GtkAcceleratorTable * value);
extern GtkAcceleratorTable * SvGtkAcceleratorTable(SV * value);
typedef GtkAcceleratorTable * Gtk__AcceleratorTable;
extern SV * newSVGtkStyle(GtkStyle * value);
extern GtkStyle * SvGtkStyle(SV * value);
typedef GtkStyle * Gtk__Style;
#ifdef GTK_ADJUSTMENT
typedef GtkAdjustment * Gtk__Adjustment;
typedef GtkAdjustment * Gtk__AdjustmentOrNULL;
#define CastGtk__Adjustment GTK_ADJUSTMENT
#define CastGtk__AdjustmentOrNULL GTK_ADJUSTMENT
#endif
#ifdef GTK_ALIGNMENT
typedef GtkAlignment * Gtk__Alignment;
typedef GtkAlignment * Gtk__AlignmentOrNULL;
#define CastGtk__Alignment GTK_ALIGNMENT
#define CastGtk__AlignmentOrNULL GTK_ALIGNMENT
#endif
#ifdef GTK_ARROW
typedef GtkArrow * Gtk__Arrow;
typedef GtkArrow * Gtk__ArrowOrNULL;
#define CastGtk__Arrow GTK_ARROW
#define CastGtk__ArrowOrNULL GTK_ARROW
#endif
#ifdef GTK_ASPECT_FRAME
typedef GtkAspectFrame * Gtk__AspectFrame;
typedef GtkAspectFrame * Gtk__AspectFrameOrNULL;
#define CastGtk__AspectFrame GTK_ASPECT_FRAME
#define CastGtk__AspectFrameOrNULL GTK_ASPECT_FRAME
#endif
#ifdef GTK_BIN
typedef GtkBin * Gtk__Bin;
typedef GtkBin * Gtk__BinOrNULL;
#define CastGtk__Bin GTK_BIN
#define CastGtk__BinOrNULL GTK_BIN
#endif
#ifdef GTK_BOX
typedef GtkBox * Gtk__Box;
typedef GtkBox * Gtk__BoxOrNULL;
#define CastGtk__Box GTK_BOX
#define CastGtk__BoxOrNULL GTK_BOX
#endif
#ifdef GTK_BUTTON
typedef GtkButton * Gtk__Button;
typedef GtkButton * Gtk__ButtonOrNULL;
#define CastGtk__Button GTK_BUTTON
#define CastGtk__ButtonOrNULL GTK_BUTTON
#endif
#ifdef GTK_BUTTON_BOX
typedef GtkButtonBox * Gtk__ButtonBox;
typedef GtkButtonBox * Gtk__ButtonBoxOrNULL;
#define CastGtk__ButtonBox GTK_BUTTON_BOX
#define CastGtk__ButtonBoxOrNULL GTK_BUTTON_BOX
#endif
#ifdef GTK_CLIST
typedef GtkCList * Gtk__CList;
typedef GtkCList * Gtk__CListOrNULL;
#define CastGtk__CList GTK_CLIST
#define CastGtk__CListOrNULL GTK_CLIST
#endif
#ifdef GTK_CHECK_BUTTON
typedef GtkCheckButton * Gtk__CheckButton;
typedef GtkCheckButton * Gtk__CheckButtonOrNULL;
#define CastGtk__CheckButton GTK_CHECK_BUTTON
#define CastGtk__CheckButtonOrNULL GTK_CHECK_BUTTON
#endif
#ifdef GTK_CHECK_MENU_ITEM
typedef GtkCheckMenuItem * Gtk__CheckMenuItem;
typedef GtkCheckMenuItem * Gtk__CheckMenuItemOrNULL;
#define CastGtk__CheckMenuItem GTK_CHECK_MENU_ITEM
#define CastGtk__CheckMenuItemOrNULL GTK_CHECK_MENU_ITEM
#endif
#ifdef GTK_COLOR_SELECTION
typedef GtkColorSelection * Gtk__ColorSelection;
typedef GtkColorSelection * Gtk__ColorSelectionOrNULL;
#define CastGtk__ColorSelection GTK_COLOR_SELECTION
#define CastGtk__ColorSelectionOrNULL GTK_COLOR_SELECTION
#endif
#ifdef GTK_COLOR_SELECTION_DIALOG
typedef GtkColorSelectionDialog * Gtk__ColorSelectionDialog;
typedef GtkColorSelectionDialog * Gtk__ColorSelectionDialogOrNULL;
#define CastGtk__ColorSelectionDialog GTK_COLOR_SELECTION_DIALOG
#define CastGtk__ColorSelectionDialogOrNULL GTK_COLOR_SELECTION_DIALOG
#endif
#ifdef GTK_COMBO
typedef GtkCombo * Gtk__Combo;
typedef GtkCombo * Gtk__ComboOrNULL;
#define CastGtk__Combo GTK_COMBO
#define CastGtk__ComboOrNULL GTK_COMBO
#endif
#ifdef GTK_CONTAINER
typedef GtkContainer * Gtk__Container;
typedef GtkContainer * Gtk__ContainerOrNULL;
#define CastGtk__Container GTK_CONTAINER
#define CastGtk__ContainerOrNULL GTK_CONTAINER
#endif
#ifdef GTK_CURVE
typedef GtkCurve * Gtk__Curve;
typedef GtkCurve * Gtk__CurveOrNULL;
#define CastGtk__Curve GTK_CURVE
#define CastGtk__CurveOrNULL GTK_CURVE
#endif
#ifdef GTK_DATA
typedef GtkData * Gtk__Data;
typedef GtkData * Gtk__DataOrNULL;
#define CastGtk__Data GTK_DATA
#define CastGtk__DataOrNULL GTK_DATA
#endif
#ifdef GTK_DIALOG
typedef GtkDialog * Gtk__Dialog;
typedef GtkDialog * Gtk__DialogOrNULL;
#define CastGtk__Dialog GTK_DIALOG
#define CastGtk__DialogOrNULL GTK_DIALOG
#endif
#ifdef GTK_DRAWING_AREA
typedef GtkDrawingArea * Gtk__DrawingArea;
typedef GtkDrawingArea * Gtk__DrawingAreaOrNULL;
#define CastGtk__DrawingArea GTK_DRAWING_AREA
#define CastGtk__DrawingAreaOrNULL GTK_DRAWING_AREA
#endif
#ifdef GTK_EDITABLE
typedef GtkEditable * Gtk__Editable;
typedef GtkEditable * Gtk__EditableOrNULL;
#define CastGtk__Editable GTK_EDITABLE
#define CastGtk__EditableOrNULL GTK_EDITABLE
#endif
#ifdef GTK_ENTRY
typedef GtkEntry * Gtk__Entry;
typedef GtkEntry * Gtk__EntryOrNULL;
#define CastGtk__Entry GTK_ENTRY
#define CastGtk__EntryOrNULL GTK_ENTRY
#endif
#ifdef GTK_EVENT_BOX
typedef GtkEventBox * Gtk__EventBox;
typedef GtkEventBox * Gtk__EventBoxOrNULL;
#define CastGtk__EventBox GTK_EVENT_BOX
#define CastGtk__EventBoxOrNULL GTK_EVENT_BOX
#endif
#ifdef GTK_FILE_SELECTION
typedef GtkFileSelection * Gtk__FileSelection;
typedef GtkFileSelection * Gtk__FileSelectionOrNULL;
#define CastGtk__FileSelection GTK_FILE_SELECTION
#define CastGtk__FileSelectionOrNULL GTK_FILE_SELECTION
#endif
#ifdef GTK_FIXED
typedef GtkFixed * Gtk__Fixed;
typedef GtkFixed * Gtk__FixedOrNULL;
#define CastGtk__Fixed GTK_FIXED
#define CastGtk__FixedOrNULL GTK_FIXED
#endif
#ifdef GTK_FRAME
typedef GtkFrame * Gtk__Frame;
typedef GtkFrame * Gtk__FrameOrNULL;
#define CastGtk__Frame GTK_FRAME
#define CastGtk__FrameOrNULL GTK_FRAME
#endif
#ifdef GTK_GAMMA_CURVE
typedef GtkGammaCurve * Gtk__GammaCurve;
typedef GtkGammaCurve * Gtk__GammaCurveOrNULL;
#define CastGtk__GammaCurve GTK_GAMMA_CURVE
#define CastGtk__GammaCurveOrNULL GTK_GAMMA_CURVE
#endif
#ifdef GTK_HBOX
typedef GtkHBox * Gtk__HBox;
typedef GtkHBox * Gtk__HBoxOrNULL;
#define CastGtk__HBox GTK_HBOX
#define CastGtk__HBoxOrNULL GTK_HBOX
#endif
#ifdef GTK_HBUTTON_BOX
typedef GtkHButtonBox * Gtk__HButtonBox;
typedef GtkHButtonBox * Gtk__HButtonBoxOrNULL;
#define CastGtk__HButtonBox GTK_HBUTTON_BOX
#define CastGtk__HButtonBoxOrNULL GTK_HBUTTON_BOX
#endif
#ifdef GTK_HPANED
typedef GtkHPaned * Gtk__HPaned;
typedef GtkHPaned * Gtk__HPanedOrNULL;
#define CastGtk__HPaned GTK_HPANED
#define CastGtk__HPanedOrNULL GTK_HPANED
#endif
#ifdef GTK_HRULER
typedef GtkHRuler * Gtk__HRuler;
typedef GtkHRuler * Gtk__HRulerOrNULL;
#define CastGtk__HRuler GTK_HRULER
#define CastGtk__HRulerOrNULL GTK_HRULER
#endif
#ifdef GTK_HSCALE
typedef GtkHScale * Gtk__HScale;
typedef GtkHScale * Gtk__HScaleOrNULL;
#define CastGtk__HScale GTK_HSCALE
#define CastGtk__HScaleOrNULL GTK_HSCALE
#endif
#ifdef GTK_HSCROLLBAR
typedef GtkHScrollbar * Gtk__HScrollbar;
typedef GtkHScrollbar * Gtk__HScrollbarOrNULL;
#define CastGtk__HScrollbar GTK_HSCROLLBAR
#define CastGtk__HScrollbarOrNULL GTK_HSCROLLBAR
#endif
#ifdef GTK_HSEPARATOR
typedef GtkHSeparator * Gtk__HSeparator;
typedef GtkHSeparator * Gtk__HSeparatorOrNULL;
#define CastGtk__HSeparator GTK_HSEPARATOR
#define CastGtk__HSeparatorOrNULL GTK_HSEPARATOR
#endif
#ifdef GTK_HANDLE_BOX
typedef GtkHandleBox * Gtk__HandleBox;
typedef GtkHandleBox * Gtk__HandleBoxOrNULL;
#define CastGtk__HandleBox GTK_HANDLE_BOX
#define CastGtk__HandleBoxOrNULL GTK_HANDLE_BOX
#endif
#ifdef GTK_IMAGE
typedef GtkImage * Gtk__Image;
typedef GtkImage * Gtk__ImageOrNULL;
#define CastGtk__Image GTK_IMAGE
#define CastGtk__ImageOrNULL GTK_IMAGE
#endif
#ifdef GTK_INPUT_DIALOG
typedef GtkInputDialog * Gtk__InputDialog;
typedef GtkInputDialog * Gtk__InputDialogOrNULL;
#define CastGtk__InputDialog GTK_INPUT_DIALOG
#define CastGtk__InputDialogOrNULL GTK_INPUT_DIALOG
#endif
#ifdef GTK_ITEM
typedef GtkItem * Gtk__Item;
typedef GtkItem * Gtk__ItemOrNULL;
#define CastGtk__Item GTK_ITEM
#define CastGtk__ItemOrNULL GTK_ITEM
#endif
#ifdef GTK_LABEL
typedef GtkLabel * Gtk__Label;
typedef GtkLabel * Gtk__LabelOrNULL;
#define CastGtk__Label GTK_LABEL
#define CastGtk__LabelOrNULL GTK_LABEL
#endif
#ifdef GTK_LIST
typedef GtkList * Gtk__List;
typedef GtkList * Gtk__ListOrNULL;
#define CastGtk__List GTK_LIST
#define CastGtk__ListOrNULL GTK_LIST
#endif
#ifdef GTK_LIST_ITEM
typedef GtkListItem * Gtk__ListItem;
typedef GtkListItem * Gtk__ListItemOrNULL;
#define CastGtk__ListItem GTK_LIST_ITEM
#define CastGtk__ListItemOrNULL GTK_LIST_ITEM
#endif
#ifdef GTK_MENU
typedef GtkMenu * Gtk__Menu;
typedef GtkMenu * Gtk__MenuOrNULL;
#define CastGtk__Menu GTK_MENU
#define CastGtk__MenuOrNULL GTK_MENU
#endif
#ifdef GTK_MENU_BAR
typedef GtkMenuBar * Gtk__MenuBar;
typedef GtkMenuBar * Gtk__MenuBarOrNULL;
#define CastGtk__MenuBar GTK_MENU_BAR
#define CastGtk__MenuBarOrNULL GTK_MENU_BAR
#endif
#ifdef GTK_MENU_ITEM
typedef GtkMenuItem * Gtk__MenuItem;
typedef GtkMenuItem * Gtk__MenuItemOrNULL;
#define CastGtk__MenuItem GTK_MENU_ITEM
#define CastGtk__MenuItemOrNULL GTK_MENU_ITEM
#endif
#ifdef GTK_MENU_SHELL
typedef GtkMenuShell * Gtk__MenuShell;
typedef GtkMenuShell * Gtk__MenuShellOrNULL;
#define CastGtk__MenuShell GTK_MENU_SHELL
#define CastGtk__MenuShellOrNULL GTK_MENU_SHELL
#endif
#ifdef GTK_MISC
typedef GtkMisc * Gtk__Misc;
typedef GtkMisc * Gtk__MiscOrNULL;
#define CastGtk__Misc GTK_MISC
#define CastGtk__MiscOrNULL GTK_MISC
#endif
#ifdef GTK_NOTEBOOK
typedef GtkNotebook * Gtk__Notebook;
typedef GtkNotebook * Gtk__NotebookOrNULL;
#define CastGtk__Notebook GTK_NOTEBOOK
#define CastGtk__NotebookOrNULL GTK_NOTEBOOK
#endif
#ifdef GTK_OBJECT
typedef GtkObject * Gtk__Object;
typedef GtkObject * Gtk__ObjectOrNULL;
#define CastGtk__Object GTK_OBJECT
#define CastGtk__ObjectOrNULL GTK_OBJECT
#endif
#ifdef GTK_OPTION_MENU
typedef GtkOptionMenu * Gtk__OptionMenu;
typedef GtkOptionMenu * Gtk__OptionMenuOrNULL;
#define CastGtk__OptionMenu GTK_OPTION_MENU
#define CastGtk__OptionMenuOrNULL GTK_OPTION_MENU
#endif
#ifdef GTK_PANED
typedef GtkPaned * Gtk__Paned;
typedef GtkPaned * Gtk__PanedOrNULL;
#define CastGtk__Paned GTK_PANED
#define CastGtk__PanedOrNULL GTK_PANED
#endif
#ifdef GTK_PIXMAP
typedef GtkPixmap * Gtk__Pixmap;
typedef GtkPixmap * Gtk__PixmapOrNULL;
#define CastGtk__Pixmap GTK_PIXMAP
#define CastGtk__PixmapOrNULL GTK_PIXMAP
#endif
#ifdef GTK_PREVIEW
typedef GtkPreview * Gtk__Preview;
typedef GtkPreview * Gtk__PreviewOrNULL;
#define CastGtk__Preview GTK_PREVIEW
#define CastGtk__PreviewOrNULL GTK_PREVIEW
#endif
#ifdef GTK_PROGRESS_BAR
typedef GtkProgressBar * Gtk__ProgressBar;
typedef GtkProgressBar * Gtk__ProgressBarOrNULL;
#define CastGtk__ProgressBar GTK_PROGRESS_BAR
#define CastGtk__ProgressBarOrNULL GTK_PROGRESS_BAR
#endif
#ifdef GTK_RADIO_BUTTON
typedef GtkRadioButton * Gtk__RadioButton;
typedef GtkRadioButton * Gtk__RadioButtonOrNULL;
#define CastGtk__RadioButton GTK_RADIO_BUTTON
#define CastGtk__RadioButtonOrNULL GTK_RADIO_BUTTON
#endif
#ifdef GTK_RADIO_MENU_ITEM
typedef GtkRadioMenuItem * Gtk__RadioMenuItem;
typedef GtkRadioMenuItem * Gtk__RadioMenuItemOrNULL;
#define CastGtk__RadioMenuItem GTK_RADIO_MENU_ITEM
#define CastGtk__RadioMenuItemOrNULL GTK_RADIO_MENU_ITEM
#endif
#ifdef GTK_RANGE
typedef GtkRange * Gtk__Range;
typedef GtkRange * Gtk__RangeOrNULL;
#define CastGtk__Range GTK_RANGE
#define CastGtk__RangeOrNULL GTK_RANGE
#endif
#ifdef GTK_RULER
typedef GtkRuler * Gtk__Ruler;
typedef GtkRuler * Gtk__RulerOrNULL;
#define CastGtk__Ruler GTK_RULER
#define CastGtk__RulerOrNULL GTK_RULER
#endif
#ifdef GTK_SCALE
typedef GtkScale * Gtk__Scale;
typedef GtkScale * Gtk__ScaleOrNULL;
#define CastGtk__Scale GTK_SCALE
#define CastGtk__ScaleOrNULL GTK_SCALE
#endif
#ifdef GTK_SCROLLBAR
typedef GtkScrollbar * Gtk__Scrollbar;
typedef GtkScrollbar * Gtk__ScrollbarOrNULL;
#define CastGtk__Scrollbar GTK_SCROLLBAR
#define CastGtk__ScrollbarOrNULL GTK_SCROLLBAR
#endif
#ifdef GTK_SCROLLED_WINDOW
typedef GtkScrolledWindow * Gtk__ScrolledWindow;
typedef GtkScrolledWindow * Gtk__ScrolledWindowOrNULL;
#define CastGtk__ScrolledWindow GTK_SCROLLED_WINDOW
#define CastGtk__ScrolledWindowOrNULL GTK_SCROLLED_WINDOW
#endif
#ifdef GTK_SEPARATOR
typedef GtkSeparator * Gtk__Separator;
typedef GtkSeparator * Gtk__SeparatorOrNULL;
#define CastGtk__Separator GTK_SEPARATOR
#define CastGtk__SeparatorOrNULL GTK_SEPARATOR
#endif
#ifdef GTK_SPIN_BUTTON
typedef GtkSpinButton * Gtk__SpinButton;
typedef GtkSpinButton * Gtk__SpinButtonOrNULL;
#define CastGtk__SpinButton GTK_SPIN_BUTTON
#define CastGtk__SpinButtonOrNULL GTK_SPIN_BUTTON
#endif
#ifdef GTK_STATUSBAR
typedef GtkStatusbar * Gtk__Statusbar;
typedef GtkStatusbar * Gtk__StatusbarOrNULL;
#define CastGtk__Statusbar GTK_STATUSBAR
#define CastGtk__StatusbarOrNULL GTK_STATUSBAR
#endif
#ifdef GTK_TABLE
typedef GtkTable * Gtk__Table;
typedef GtkTable * Gtk__TableOrNULL;
#define CastGtk__Table GTK_TABLE
#define CastGtk__TableOrNULL GTK_TABLE
#endif
#ifdef GTK_TEXT
typedef GtkText * Gtk__Text;
typedef GtkText * Gtk__TextOrNULL;
#define CastGtk__Text GTK_TEXT
#define CastGtk__TextOrNULL GTK_TEXT
#endif
#ifdef GTK_TIPS_QUERY
typedef GtkTipsQuery * Gtk__TipsQuery;
typedef GtkTipsQuery * Gtk__TipsQueryOrNULL;
#define CastGtk__TipsQuery GTK_TIPS_QUERY
#define CastGtk__TipsQueryOrNULL GTK_TIPS_QUERY
#endif
#ifdef GTK_TOGGLE_BUTTON
typedef GtkToggleButton * Gtk__ToggleButton;
typedef GtkToggleButton * Gtk__ToggleButtonOrNULL;
#define CastGtk__ToggleButton GTK_TOGGLE_BUTTON
#define CastGtk__ToggleButtonOrNULL GTK_TOGGLE_BUTTON
#endif
#ifdef GTK_TOOLBAR
typedef GtkToolbar * Gtk__Toolbar;
typedef GtkToolbar * Gtk__ToolbarOrNULL;
#define CastGtk__Toolbar GTK_TOOLBAR
#define CastGtk__ToolbarOrNULL GTK_TOOLBAR
#endif
#ifdef GTK_TOOLTIPS
typedef GtkTooltips * Gtk__Tooltips;
typedef GtkTooltips * Gtk__TooltipsOrNULL;
#define CastGtk__Tooltips GTK_TOOLTIPS
#define CastGtk__TooltipsOrNULL GTK_TOOLTIPS
#endif
#ifdef GTK_TREE
typedef GtkTree * Gtk__Tree;
typedef GtkTree * Gtk__TreeOrNULL;
#define CastGtk__Tree GTK_TREE
#define CastGtk__TreeOrNULL GTK_TREE
#endif
#ifdef GTK_TREE_ITEM
typedef GtkTreeItem * Gtk__TreeItem;
typedef GtkTreeItem * Gtk__TreeItemOrNULL;
#define CastGtk__TreeItem GTK_TREE_ITEM
#define CastGtk__TreeItemOrNULL GTK_TREE_ITEM
#endif
#ifdef GTK_VBOX
typedef GtkVBox * Gtk__VBox;
typedef GtkVBox * Gtk__VBoxOrNULL;
#define CastGtk__VBox GTK_VBOX
#define CastGtk__VBoxOrNULL GTK_VBOX
#endif
#ifdef GTK_VBUTTON_BOX
typedef GtkVButtonBox * Gtk__VButtonBox;
typedef GtkVButtonBox * Gtk__VButtonBoxOrNULL;
#define CastGtk__VButtonBox GTK_VBUTTON_BOX
#define CastGtk__VButtonBoxOrNULL GTK_VBUTTON_BOX
#endif
#ifdef GTK_VPANED
typedef GtkVPaned * Gtk__VPaned;
typedef GtkVPaned * Gtk__VPanedOrNULL;
#define CastGtk__VPaned GTK_VPANED
#define CastGtk__VPanedOrNULL GTK_VPANED
#endif
#ifdef GTK_VRULER
typedef GtkVRuler * Gtk__VRuler;
typedef GtkVRuler * Gtk__VRulerOrNULL;
#define CastGtk__VRuler GTK_VRULER
#define CastGtk__VRulerOrNULL GTK_VRULER
#endif
#ifdef GTK_VSCALE
typedef GtkVScale * Gtk__VScale;
typedef GtkVScale * Gtk__VScaleOrNULL;
#define CastGtk__VScale GTK_VSCALE
#define CastGtk__VScaleOrNULL GTK_VSCALE
#endif
#ifdef GTK_VSCROLLBAR
typedef GtkVScrollbar * Gtk__VScrollbar;
typedef GtkVScrollbar * Gtk__VScrollbarOrNULL;
#define CastGtk__VScrollbar GTK_VSCROLLBAR
#define CastGtk__VScrollbarOrNULL GTK_VSCROLLBAR
#endif
#ifdef GTK_VSEPARATOR
typedef GtkVSeparator * Gtk__VSeparator;
typedef GtkVSeparator * Gtk__VSeparatorOrNULL;
#define CastGtk__VSeparator GTK_VSEPARATOR
#define CastGtk__VSeparatorOrNULL GTK_VSEPARATOR
#endif
#ifdef GTK_VIEWPORT
typedef GtkViewport * Gtk__Viewport;
typedef GtkViewport * Gtk__ViewportOrNULL;
#define CastGtk__Viewport GTK_VIEWPORT
#define CastGtk__ViewportOrNULL GTK_VIEWPORT
#endif
#ifdef GTK_WIDGET
typedef GtkWidget * Gtk__Widget;
typedef GtkWidget * Gtk__WidgetOrNULL;
#define CastGtk__Widget GTK_WIDGET
#define CastGtk__WidgetOrNULL GTK_WIDGET
#endif
#ifdef GTK_WINDOW
typedef GtkWindow * Gtk__Window;
typedef GtkWindow * Gtk__WindowOrNULL;
#define CastGtk__Window GTK_WINDOW
#define CastGtk__WindowOrNULL GTK_WINDOW
#endif

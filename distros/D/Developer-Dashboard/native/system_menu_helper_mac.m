#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <unistd.h>

@class DDSystemMenuController;

@interface DDStayMenuItemView : NSView
@property(nonatomic, copy) NSString *itemName;
@property(nonatomic, copy) NSString *displayTitle;
@property(nonatomic, weak) DDSystemMenuController *controller;
@property(nonatomic, assign) BOOL highlighted;
@property(nonatomic, strong) NSTrackingArea *trackingArea;
- (instancetype)initWithName:(NSString *)name
                       title:(NSString *)title
                  controller:(DDSystemMenuController *)controller;
- (void)setMenuTitle:(NSString *)title;
@end

@interface DDSystemMenuController : NSObject
@property(nonatomic, strong) NSMutableData *inputBuffer;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *objectsByName;
@property(nonatomic, strong) NSMutableSet<NSString *> *topLevelNames;
- (void)emitClick:(NSString *)name;
@end

static const void *DDSystemMenuNameKey = &DDSystemMenuNameKey;
static DDSystemMenuController *DDSystemMenuControllerInstance = nil;

@implementation DDStayMenuItemView

- (instancetype)initWithName:(NSString *)name
                       title:(NSString *)title
                  controller:(DDSystemMenuController *)controller
{
    NSFont *font = [NSFont menuFontOfSize:0.0];
    NSDictionary *attrs = @{ NSFontAttributeName: font };
    CGFloat textWidth = ceil([title sizeWithAttributes:attrs].width);
    CGFloat width = MAX(120.0, textWidth + 34.0);

    self = [super initWithFrame:NSMakeRect(0.0, 0.0, width, 22.0)];
    if (!self) return nil;

    _itemName = [name copy];
    _displayTitle = [title copy];
    _controller = controller;
    _highlighted = NO;
    return self;
}

- (BOOL)isFlipped { return YES; }

- (void)updateTrackingAreas
{
    if (self.trackingArea) [self removeTrackingArea:self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc]
        initWithRect:NSZeroRect
             options:(NSTrackingMouseEnteredAndExited |
                      NSTrackingActiveAlways |
                      NSTrackingInVisibleRect)
               owner:self
            userInfo:nil];
    [self addTrackingArea:self.trackingArea];
    [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)event
{
    (void)event;
    self.highlighted = YES;
    self.needsDisplay = YES;
}

- (void)mouseExited:(NSEvent *)event
{
    (void)event;
    self.highlighted = NO;
    self.needsDisplay = YES;
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    if (NSPointInRect(p, self.bounds)) {
        [self.controller emitClick:self.itemName];
    }
}

- (void)setMenuTitle:(NSString *)title
{
    self.displayTitle = title ?: @"";
    NSFont *font = [NSFont menuFontOfSize:0.0];
    NSDictionary *attrs = @{ NSFontAttributeName: font };
    CGFloat textWidth = ceil([self.displayTitle sizeWithAttributes:attrs].width);
    NSRect frame = self.frame;
    frame.size.width = MAX(120.0, textWidth + 34.0);
    self.frame = frame;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if (self.highlighted) {
        [[NSColor selectedContentBackgroundColor] setFill];
        NSRectFill(self.bounds);
    }

    NSColor *textColor = self.highlighted
        ? [NSColor selectedMenuItemTextColor]
        : [NSColor textColor];

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont menuFontOfSize:0.0],
        NSForegroundColorAttributeName: textColor,
    };

    NSSize textSize = [self.displayTitle sizeWithAttributes:attrs];
    CGFloat y = floor((NSHeight(self.bounds) - textSize.height) / 2.0);
    [self.displayTitle drawAtPoint:NSMakePoint(22.0, y)
                    withAttributes:attrs];
}

@end

@implementation DDSystemMenuController

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;
    _inputBuffer = [NSMutableData data];
    _objectsByName = [NSMutableDictionary dictionary];
    _topLevelNames = [NSMutableSet set];
    return self;
}

- (void)emitClick:(NSString *)name
{
    if (!name.length) return;

    NSDictionary *event = @{ @"event": @"click", @"name": name };
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:0 error:&error];
    if (error || !data) return;

    (void)write(STDOUT_FILENO, data.bytes, data.length);
    (void)write(STDOUT_FILENO, "\n", 1);
}

- (void)setVisibleText:(NSString *)text onStatusButton:(NSStatusBarButton *)button
{
    button.image = nil;
    button.font = [NSFont menuBarFontOfSize:0.0];
    button.title = text ?: @"";
}

- (void)statusItemButtonClicked:(NSStatusBarButton *)sender
{
    NSString *name = objc_getAssociatedObject(sender, DDSystemMenuNameKey);
    [self emitClick:name];
}

- (void)menuItemClicked:(NSMenuItem *)sender
{
    NSString *name = [sender.representedObject isKindOfClass:[NSString class]]
        ? sender.representedObject : nil;
    [self emitClick:name];
}

- (void)removeAllStatusItems
{
    for (NSString *name in [self.topLevelNames allObjects]) {
        id object = self.objectsByName[name];
        if ([object isKindOfClass:[NSStatusItem class]]) {
            [[NSStatusBar systemStatusBar] removeStatusItem:(NSStatusItem *)object];
        }
    }
    [self.objectsByName removeAllObjects];
    [self.topLevelNames removeAllObjects];
}

- (NSMenu *)buildMenu:(NSArray *)specs
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    menu.autoenablesItems = NO;

    for (id raw in specs) {
        if (![raw isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *spec = (NSDictionary *)raw;

        NSString *name = [spec[@"name"] isKindOfClass:[NSString class]] ? spec[@"name"] : nil;
        NSString *icon = [spec[@"icon"] isKindOfClass:[NSString class]] ? spec[@"icon"] : @"";
        BOOL clickStay = [spec[@"click_stay"] boolValue];
        if (!name.length) continue;

        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:icon action:nil keyEquivalent:@""];
        self.objectsByName[name] = item;

        NSArray *children = [spec[@"menu"] isKindOfClass:[NSArray class]] ? spec[@"menu"] : nil;
        if (children) {
            item.submenu = [self buildMenu:children];
            item.enabled = YES;
        }
        else if ([spec[@"click"] isKindOfClass:[NSString class]]) {
            item.enabled = YES;
            if (clickStay) {
                DDStayMenuItemView *view = [[DDStayMenuItemView alloc]
                    initWithName:name title:icon controller:self];
                item.view = view;
            }
            else {
                item.target = self;
                item.action = @selector(menuItemClicked:);
                item.representedObject = name;
            }
        }
        else {
            item.enabled = NO;
        }

        [menu addItem:item];
    }

    return menu;
}

- (void)installSettings:(NSArray *)specs
{
    [self removeAllStatusItems];

    for (NSInteger i = (NSInteger)specs.count - 1; i >= 0; i--) {
        id raw = specs[(NSUInteger)i];
        if (![raw isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *spec = (NSDictionary *)raw;

        NSString *name = [spec[@"name"] isKindOfClass:[NSString class]] ? spec[@"name"] : nil;
        NSString *icon = [spec[@"icon"] isKindOfClass:[NSString class]] ? spec[@"icon"] : @"";
        if (!name.length) continue;

        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar]
            statusItemWithLength:NSVariableStatusItemLength];
        NSStatusBarButton *button = statusItem.button;
        [self setVisibleText:icon onStatusButton:button];
        objc_setAssociatedObject(button, DDSystemMenuNameKey, name, OBJC_ASSOCIATION_COPY_NONATOMIC);

        self.objectsByName[name] = statusItem;
        [self.topLevelNames addObject:name];

        NSArray *children = [spec[@"menu"] isKindOfClass:[NSArray class]] ? spec[@"menu"] : nil;
        if (children) {
            statusItem.menu = [self buildMenu:children];
        }
        else if ([spec[@"click"] isKindOfClass:[NSString class]]) {
            button.enabled = YES;
            button.target = self;
            button.action = @selector(statusItemButtonClicked:);
            [button sendActionOn:NSEventMaskLeftMouseUp];
        }
    }
}

- (void)setIcon:(NSString *)icon forName:(NSString *)name
{
    id object = self.objectsByName[name];
    if ([object isKindOfClass:[NSStatusItem class]]) {
        [self setVisibleText:(icon ?: @"") onStatusButton:((NSStatusItem *)object).button];
    }
    else if ([object isKindOfClass:[NSMenuItem class]]) {
        NSMenuItem *item = (NSMenuItem *)object;
        if ([item.view isKindOfClass:[DDStayMenuItemView class]]) {
            [(DDStayMenuItemView *)item.view setMenuTitle:(icon ?: @"")];
        }
        else {
            item.title = icon ?: @"";
        }
    }
}

- (void)removeName:(NSString *)name
{
    id object = self.objectsByName[name];
    if (!object) return;

    if ([object isKindOfClass:[NSStatusItem class]]) {
        [[NSStatusBar systemStatusBar] removeStatusItem:(NSStatusItem *)object];
        [self.topLevelNames removeObject:name];
    }
    else if ([object isKindOfClass:[NSMenuItem class]]) {
        NSMenuItem *item = (NSMenuItem *)object;
        if (item.menu) [item.menu removeItem:item];
    }
    [self.objectsByName removeObjectForKey:name];
}

- (void)handleCommand:(NSDictionary *)command
{
    NSString *op = [command[@"op"] isKindOfClass:[NSString class]] ? command[@"op"] : @"";

    if ([op isEqualToString:@"run"]) {
        NSArray *items = [command[@"items"] isKindOfClass:[NSArray class]] ? command[@"items"] : @[];
        [self installSettings:items];
        return;
    }
    if ([op isEqualToString:@"icon"]) {
        NSString *name = [command[@"name"] isKindOfClass:[NSString class]] ? command[@"name"] : nil;
        NSString *icon = [command[@"icon"] isKindOfClass:[NSString class]] ? command[@"icon"] : @"";
        if (name.length) [self setIcon:icon forName:name];
        return;
    }
    if ([op isEqualToString:@"remove"]) {
        NSString *name = [command[@"name"] isKindOfClass:[NSString class]] ? command[@"name"] : nil;
        if (name.length) [self removeName:name];
        return;
    }
    if ([op isEqualToString:@"stop"]) {
        [self removeAllStatusItems];
        [NSApp terminate:nil];
        return;
    }
}

- (void)consumeInputData:(NSData *)data
{
    if (data.length == 0) {
        [NSApp terminate:nil];
        return;
    }

    [self.inputBuffer appendData:data];
    while (YES) {
        const unsigned char *bytes = self.inputBuffer.bytes;
        NSUInteger length = self.inputBuffer.length;
        NSUInteger newline = NSNotFound;
        for (NSUInteger i = 0; i < length; i++) {
            if (bytes[i] == '\n') { newline = i; break; }
        }
        if (newline == NSNotFound) break;

        NSData *lineData = [self.inputBuffer subdataWithRange:NSMakeRange(0, newline)];
        [self.inputBuffer replaceBytesInRange:NSMakeRange(0, newline + 1) withBytes:NULL length:0];

        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:lineData options:0 error:&error];
        if (error || ![json isKindOfClass:[NSDictionary class]]) continue;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleCommand:(NSDictionary *)json];
        });
    }
}

- (void)start
{
    NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
    __weak typeof(self) weakSelf = self;
    stdinHandle.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = handle.availableData;
        [weakSelf consumeInputData:data];
    };
}

@end

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        (void)argc;
        (void)argv;
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        DDSystemMenuControllerInstance = [[DDSystemMenuController alloc] init];
        [DDSystemMenuControllerInstance start];
        [app run];
        DDSystemMenuControllerInstance = nil;
    }
    return 0;
}

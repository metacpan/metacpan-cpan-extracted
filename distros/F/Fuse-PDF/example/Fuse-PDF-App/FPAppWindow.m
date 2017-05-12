//
//  FPAppWindow.m
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 11/29/07.
//  Copyright 2007, All rights reserved.
//

#import "AppDelegate.h"
#import "BundledTask.h"
#import "FPAppWindow.h"

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
   NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
   NSRange range = NSMakeRange(0, [attrString length]);
   
   [attrString beginEditing];
   [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
   
   // make the text appear in blue
   [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
   
   // next make the text appear with an underline
   [attrString addAttribute:
            NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
   
   [attrString endEditing];
   
   return [attrString autorelease];
}
@end

@implementation FPAppWindow

static FPAppWindow *sharedController = nil;

+ (id)sharedController {
   if (!sharedController)
      sharedController = [[FPAppWindow allocWithZone:nil] init];
   [sharedController showWindow:nil];
   return sharedController;
}

- (id)init {
   self = [self initWithWindowNibName:@"FPAppWindow"];
   return self;
}

- (void)windowDidLoad {
   printf("window loaded\n");
   [[self window] setExcludedFromWindowsMenu:YES];
   [[NSApplication sharedApplication] removeWindowsItem:[self window]];
   [super windowDidLoad];
   [self setup];
   
}

-(void) parseVersion: (NSString*)result {
   //printf("result: %s\n", result ? [result UTF8String] : [@"nil" UTF8String]);
   if (result) {
      NSRange versionLoc = [result rangeOfString:@"version "];
      if (NSNotFound != versionLoc.location) {
         NSRange near = {versionLoc.location - 10, versionLoc.length + 50};
         printf("found version near '%s'\n", [[result substringWithRange: near] UTF8String]);
         NSRange spaceSearch = {versionLoc.location + versionLoc.length, 100};
         printf("looking for space at %d+%d\n", spaceSearch.location, spaceSearch.length);
         if (spaceSearch.location >= [result length]) {
            printf("end of string\n");
            return;
         }
         NSRange nextSpace = [result rangeOfString:@"\n" options:0 range:spaceSearch];
         if (NSNotFound != nextSpace.location) {
            NSRange numberLoc = {spaceSearch.location, nextSpace.location - spaceSearch.location};
            [fuseVersion release];
            fuseVersion = [result substringWithRange:numberLoc];
            [fuseVersion retain];
            printf("number version = %s\n", [fuseVersion UTF8String]);
            [fuseStatus setObjectValue:[@"present, v" stringByAppendingString:fuseVersion]];
            return;
         } else {printf("missing space\n");}
      } else {printf("missing versionloc\n");}
   } else {printf("nil result\n");}
}

-(void)getFuseVersion {
   Callback *callback = [Callback create:self method:@selector(parseVersion:)];
   NSArray *cmd = [NSArray arrayWithObjects:@"/System/Library/Filesystems/fusefs.fs/Support/mount_fusefs", @"-v", nil];
   [BundledTask run:cmd callback:callback];
}

-(void)parseArch:(NSString*)arch {
   NSRange r = [arch rangeOfString:@"\n"];
   if (NSNotFound != r.location) {
      NSRange begin = {0, r.location};
      arch = [arch substringWithRange:begin];
   }
   printf("arch: %s\n", [arch UTF8String]);
   archext = [[@"." stringByAppendingString:arch] retain];
}
-(void)getPerlArch {
   Callback *callback = [Callback create:self method:@selector(parseArch:)];
   //NSArray *cmd = [NSArray arrayWithObjects:@"/usr/bin/perl", @"-e", @"use Config; print @Config{myarchname}", nil];
   NSArray *cmd = [NSArray arrayWithObject:@"/usr/bin/arch"];
   [BundledTask run:cmd callback:callback];
}

-(void)setup {
   [self getPerlArch];

   [unmountButton setEnabled:NO];

   //NSString *urlStr = [fuseLink stringValue];
   NSString *urlStr = @"http://code.google.com/p/macfuse";
   // both are needed, otherwise hyperlink won't accept mousedown
   [fuseLink setAllowsEditingTextAttributes: YES];
   [fuseLink setSelectable: YES];
   NSURL* url = [NSURL URLWithString:urlStr];
   NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
   [string appendAttributedString: [NSAttributedString hyperlinkFromString:urlStr withURL:url]];
   // set the attributed string to the NSTextField
   [fuseLink setAttributedStringValue: string];
   
   [dropWell registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
   [dropWell setCallback:[Callback create:self method:@selector(doMount:)]];
   
   pdfListSource = [[PDFList alloc] init];
   [pdfList setDataSource:pdfListSource];

   [self getFuseVersion];
}

-(NSString *)createMountPathForFile:(NSString *)path {
   NSString *filename = [path lastPathComponent];
   NSString *root = [@"/Volumes/" stringByAppendingString:filename];
   NSFileManager *mgr = [NSFileManager defaultManager];
   NSString *mountPath = root;
   root = [root stringByAppendingString:@"-"];
   int i = 0;
   while ([mgr fileExistsAtPath:mountPath]) {
      mountPath = [root stringByAppendingString:[NSString stringWithFormat:@"%d", ++i]];
   }
   [mgr createDirectoryAtPath:mountPath attributes:nil];
   return mountPath;
}

-(void)mountCallback:(NSString *)output fromTask:(BundledTask *)task {
   if (output)
      printf("%s\n", [output UTF8String]);
   printf("unmount\n");
   [task release];
}

-(void)doMount:(NSString*)path {
   printf("mount %s\n", [path UTF8String]);
   NSMutableArray *array = [pdfListSource array];
   NSString *mountPath = [self createMountPathForFile:path];
   @try {
      NSArray *cmd = [NSArray arrayWithObjects:[@"mount_pdf" stringByAppendingString:archext], path, mountPath, nil];
      BundledTask *t = [[BundledTask alloc] initWithCmd:cmd];
	  [t setVerbose:YES];
      Callback *callback = [Callback create:self method:@selector(mountCallback:fromTask:) data:t];
      [t start:callback];
      [array addObject:mountPath];
      [array addObject:path];
      [unmountButton setEnabled:YES];
      [pdfList reloadData];
   }
   @catch (NSException *e) {
      [[NSAlert alertWithMessageText:@"PDF mount failed" defaultButton:nil alternateButton:nil otherButton:nil
          informativeTextWithFormat:@"Failed to mount PDF file %@ at %@: %@", path, mountPath, e] runModal];
      [[NSFileManager defaultManager] removeFileAtPath:mountPath handler:nil];
   }
}

-(IBAction)mountPDF:(id)sender {
   printf("mountPDF\n");
   NSOpenPanel *open = [NSOpenPanel openPanel];
   [open setCanChooseFiles:YES];
   [open setCanChooseDirectories:NO];
   [open setAllowsMultipleSelection:NO];
   [open setResolvesAliases:YES];
   if (NSOKButton == [open runModalForTypes:[NSArray arrayWithObject:@"pdf"]]) {
      NSString *path = [open filename];
      [self doMount:path];
   }
}
-(IBAction)unmountPDF:(id)sender {
   printf("unmountPDF\n");
   NSIndexSet *indexSet = [pdfList selectedRowIndexes];
   NSMutableArray *array = [pdfListSource array];
   int i;
   for (i=[array count] - 2; i>=0; i -= 2) {
      if ([indexSet containsIndex:i/2]) {
         NSString *mountPath = [array objectAtIndex:i];
         NSString *path = [array objectAtIndex:i+1];
         @try {
            NSArray *cmd = [NSArray arrayWithObjects: @"/sbin/umount", mountPath, nil];
			BundledTask *t = [[BundledTask alloc] initWithCmd:cmd];
			[t setVerbose:YES];
			[[t autorelease] startAndWait];
         }
         @catch (NSException *e) {
            [[NSAlert alertWithMessageText:@"PDF unmount failed" defaultButton:nil alternateButton:nil otherButton:nil
                 informativeTextWithFormat:@"Failed to unmount PDF file %@ at %@: %@", path, mountPath, e] runModal];
         }
         [[NSFileManager defaultManager] removeFileAtPath:mountPath handler:nil];
         [array removeObjectAtIndex:i+1];
         [array removeObjectAtIndex:i];
      }
   }
   [pdfList reloadData];
   if (0 == [array count])
      [unmountButton setEnabled:NO];
}
-(IBAction)clickLink:(id)sender {
   printf("clickLink\n");
}

@end

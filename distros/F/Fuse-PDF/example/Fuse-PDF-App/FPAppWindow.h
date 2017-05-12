//
//  FPAppWindow.h
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 11/29/07.
//  Copyright 2007, All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DragWell.h";
#import "PDFList.h"

@interface FPAppWindow : NSWindowController {
   @protected
   IBOutlet NSTextField *fuseStatus;
   IBOutlet NSTextField *fuseLink;
   IBOutlet NSTableView *pdfList;
   IBOutlet NSButton *mountButton;
   IBOutlet NSButton *unmountButton;
   IBOutlet DragWell *dropWell;
   NSString *fuseVersion;
   PDFList *pdfListSource;
   NSString *archext;
}

+(id)sharedController;
-(void) setup;

-(IBAction)mountPDF:(id)sender;
-(IBAction)unmountPDF:(id)sender;
-(IBAction)clickLink:(id)sender;


@end

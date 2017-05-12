//
//  AppDelegate.h
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 11/29/07.
//  Copyright 2007, All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FPAppWindow.h"


@interface AppDelegate : NSObject {
}
-(IBAction) showController:(id)sender;
-(FPAppWindow *) controller;
-(IBAction)mountPDF:(id)sender;
-(IBAction)unmountPDF:(id)sender;
@end

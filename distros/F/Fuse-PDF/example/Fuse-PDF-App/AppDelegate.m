//
//  AppDelegate.m
//  Fuse-PDF-App
//
//  Created by Chris Dolan on 11/29/07.
//  Copyright 2007, All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
   printf("launched\n");
   [self showController:self];   
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
   // Prevent auto-creation of untitled doc at launch
   return NO;
}

-(IBAction)showController:(id)sender {
   [[self controller] showWindow:sender];
}

-(FPAppWindow *) controller {
   return [FPAppWindow sharedController];
}

-(IBAction)mountPDF:(id)sender {
   [[self controller] mountPDF: sender];
}
-(IBAction)unmountPDF:(id)sender {
   [[self controller] unmountPDF: sender];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
   BOOL handleKey = NO;
   if ([key isEqualToString:@"controller"])
      handleKey = YES;
   return handleKey;
}

@end

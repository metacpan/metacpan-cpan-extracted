//
//  BundledTask.h
//  MediaLandscape
//
//  Created by Chris Dolan on 4/27/06.
//  Copyright 2006 Clotho Advanced Media Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskWrapper.h"
#import "Callback.h"

@interface BundledTask : NSObject <TaskWrapperController>
{
  @protected
   Callback *callback;
   NSString *result;
   BOOL isRunning;
   BOOL isVerbose;
   TaskWrapper *task;
   NSArray *absoluteCmd;
}

+ (id) run:(NSArray *)cmd;
+ (id) run:(NSArray *)cmd callback:(Callback *)cb;
- (id) initWithCmd:(NSArray *)cmd;
- (id) initWithCmd:(NSArray *)cmd fromBundle:(NSBundle *)bundle;
- (void)setVerbose:(BOOL)verbose;
- (BOOL)isRunning;
- (void)start;
- (void)start:(Callback *)cb;
- (NSString *)startAndWait;
- (void)halt;
@end
